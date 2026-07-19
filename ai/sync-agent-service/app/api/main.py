"""FastAPI entrypoint — MVP Chat.

Endpoints:
  GET  /healthz                 health
  GET  /metrics                 Prometheus
  POST /ai/chat                 chat SSE streaming (P0 - MVP)
  GET  /ai/conversations/{sid}  lấy lịch sử hội thoại
  POST /ai/voice                async voice (P2 - 501)
  WS   /ai/realtime             realtime voice (P2 - 501)

Auth: JWT do IAM phát hành. Rate-limit theo SubscriptionTier. Langfuse tắt mặc định — xem flow_log console.
"""
from __future__ import annotations

import json
import uuid
from contextlib import asynccontextmanager
from typing import Any

from fastapi import Depends, FastAPI, HTTPException, Request, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel, Field

from app.api.ratelimit import RateLimiter
from app.api.security import AuthContext, require_auth
from app.config import get_settings
from app.graph.build import build_graph
from app.graph.toolrunner import STREAM_FINAL_TAG
from app.logging_setup import get_logger, setup_logging
from app.memory.checkpointer import build_checkpointer
from app.observability import audit as audit_mod
from app.observability import metrics
from app.observability.flow_log import flow, flow_banner, flow_data, flow_timing, set_trace_id
from app.observability.tracing import trace_config
from app.state import initial_state

from app.tools import dotnet

_log = get_logger("ai.api")
_ctx: dict[str, Any] = {}


def _normalize_stream_piece(piece: Any) -> str:
    """Chuẩn hoá chunk LLM (str hoặc list multimodal) thành text SSE."""
    if piece is None:
        return ""
    if isinstance(piece, str):
        return piece
    if isinstance(piece, list):
        parts: list[str] = []
        for item in piece:
            if isinstance(item, str):
                parts.append(item)
            elif isinstance(item, dict):
                if item.get("type") == "text":
                    parts.append(str(item.get("text") or ""))
                else:
                    parts.append(str(item.get("text") or item.get("content") or ""))
            else:
                parts.append(str(item))
        return "".join(parts)
    return str(piece)


import re as _re

# Patterns to strip from LLM output before sending to chat UI.
# The Flutter client renders plain text — markdown symbols appear as literal
# characters and look bad (especially ** bold ** and # headers).
_MD_BOLD_ITALIC = _re.compile(r"\*{1,3}([^*\n]+?)\*{1,3}")
_MD_HEADER = _re.compile(r"^#{1,6}\s+", flags=_re.MULTILINE)
_MD_INLINE_CODE = _re.compile(r"`([^`\n]+?)`")
_MD_BULLET_DASH = _re.compile(r"^[ \t]*[-•]\s+", flags=_re.MULTILINE)
_MD_IMAGE = _re.compile(r"!\[[^\]]*\]\([^)]+\)")
_MD_LINK = _re.compile(r"\[([^\]]+)\]\([^)]+\)")


def _strip_markdown_for_chat(text: str) -> str:
    """Remove common markdown so plain-text chat UI looks clean.

    Deliberately light-touch: keeps numbers, punctuation, newlines, and
    Vietnamese diacritics intact. Converts bullet dashes to '•' so lists
    still read naturally without raw markdown symbols.
    """
    text = _MD_IMAGE.sub("", text)
    text = _MD_LINK.sub(r"\1", text)
    text = _MD_HEADER.sub("", text)
    text = _MD_BOLD_ITALIC.sub(r"\1", text)
    text = _MD_INLINE_CODE.sub(r"\1", text)
    text = _MD_BULLET_DASH.sub("• ", text)
    # Collapse leftover blank lines from stripped images
    text = _re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() if text else text


@asynccontextmanager
async def lifespan(app: FastAPI):
    import httpx
    import redis.asyncio as aioredis

    from app.deps import (
        set_fitness_kb,
        set_http_client,
        set_pg_pool,
        set_redis,
        track_background_task,
    )
    from app.tools.rag import FitnessKnowledgeBase

    settings = get_settings()
    setup_logging(settings.log_level)

    redis_client = aioredis.from_url(settings.redis_url)
    set_redis(redis_client)
    _ctx["redis"] = redis_client
    _ctx["ratelimiter"] = RateLimiter(redis_client)

    http_client = httpx.AsyncClient(**dotnet._client_kwargs())
    set_http_client(http_client)
    _ctx["http_client"] = http_client

    pg_pool = None
    try:
        import asyncpg

        pg_pool = await asyncpg.create_pool(
            settings.postgres_dsn, min_size=2, max_size=10,
        )
        set_pg_pool(pg_pool)
        _ctx["pg_pool"] = pg_pool
        set_fitness_kb(FitnessKnowledgeBase(pool=pg_pool))
    except Exception:
        _log.warning("pg_pool_unavailable", extra={"node": "lifespan"})

    _ctx["checkpointer"] = await build_checkpointer()
    _ctx["graph"] = build_graph(checkpointer=_ctx["checkpointer"])
    _ctx["background_tasks"] = set()
    _ctx["track_background_task"] = track_background_task

    try:
        from app.config import ModelTier
        from app.models.router import _build_chat_client

        _build_chat_client(ModelTier.SMALL)
        _build_chat_client(ModelTier.MID)
        _log.info("llm_clients_warmed", extra={"node": "lifespan"})
    except Exception:
        _log.warning("llm_warmup_skipped", extra={"node": "lifespan"})

    flow_banner()
    _log.info("ai_service_started", extra={"node": "lifespan"})
    yield
    try:
        await http_client.aclose()
    except Exception:
        pass
    try:
        await redis_client.aclose()
    except Exception:
        pass
    if pg_pool is not None:
        try:
            await pg_pool.close()
        except Exception:
            pass
    for task in list(_ctx.get("background_tasks", set())):
        task.cancel()
    _ctx.clear()


app = FastAPI(title="SYNC AI Agent Service", version="0.1.0", lifespan=lifespan)

from app.api.admin_dashboard import router as admin_dashboard_router  # noqa: E402

app.include_router(admin_dashboard_router, prefix="/ai")

_settings = get_settings()
app.add_middleware(
    CORSMiddleware,
    allow_origins=_settings.cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
    session_id: str
    locale: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    timezone: str | None = None


class ConfirmRequest(BaseModel):
    session_id: str
    action_id: str
    confirmed: bool = True


_SUPPORTED_ACTION_TYPES = frozenset({
    "create_order",
    "pay_with_wallet",
    "create_payment_link",
    "reorder",
    "topup_wallet",
    "create_roadmap",
    "delete_roadmap",
    "reschedule_session",
    "generate_week_plan",
    "plan_or_edit_workout",
    "enable_ai_reschedule",
    "upgrade_premium",
    "log_meal",
})


async def _execute_confirmed_action(user_id: str, action: dict) -> dict:
    """Dispatch confirmed action to the appropriate .NET call."""
    from app.tools.local import execute_workout_plan_write

    action_type = action.get("type")

    if action_type == "create_order":
        idem = action.get("idempotency_key") or action.get("action_id")
        items = action.get("items") or []
        pref = str(action.get("payment_method_pref") or "wallet").strip().lower()
        if pref not in ("wallet", "cod", "vietqr"):
            pref = "wallet"

        # COD → place with COD; Wallet/VietQR → Deferred then charge / QR.
        payment_method = "COD" if pref == "cod" else "Deferred"
        payload: dict[str, Any] = {
            "partnerId": action.get("partner_id"),
            "items": items,
            "paymentMethod": payment_method,
            "deliveryAddress": action.get("delivery_address") or "",
            "recipientName": action.get("recipient_name") or "",
            "recipientPhone": action.get("recipient_phone") or "",
            "voucherCode": action.get("voucher_code"),
            "aIReasoningSnapshotJson": action.get("ai_reasoning_snapshot_json"),
            "isAiInitiated": True,
        }
        if action.get("delivery_lat") is not None:
            payload["deliveryLat"] = action["delivery_lat"]
        if action.get("delivery_lng") is not None:
            payload["deliveryLng"] = action["delivery_lng"]
        result = await dotnet.create_order(user_id, payload, idem)
        order = result.get("order") if isinstance(result, dict) else None
        order_id = None
        if isinstance(order, dict):
            order_id = order.get("id") or order.get("Id")
        elif isinstance(result, dict):
            order_id = result.get("id") or result.get("Id")
            if not order_id and isinstance(result.get("data"), dict):
                data = result["data"]
                order = data.get("order") or data.get("Order") or data
                if isinstance(order, dict):
                    order_id = order.get("id") or order.get("Id")

        amount = float(
            action.get("amount")
            or (order.get("totalAmount") if isinstance(order, dict) else None)
            or (order.get("TotalAmount") if isinstance(order, dict) else None)
            or 0
        )

        base = {
            "order": result,
            "order_id": order_id,
            "payment_method_pref": pref,
            "distance_km": action.get("distance_km"),
            "eta_minutes": action.get("eta_minutes"),
            "amount": amount,
        }

        if pref == "cod":
            return {
                **base,
                "message": (
                    f"Đã tạo đơn COD{f' {order_id}' if order_id else ''}. "
                    "Thanh toán khi nhận hàng."
                ),
                "next_step": "Đơn COD đã tạo (IsAiInitiated).",
                "display_payload": [{
                    "type": "order_success",
                    "orderId": order_id,
                    "amount": amount,
                    "paymentMethod": "COD",
                }] if order_id else [],
            }

        if pref == "wallet" and order_id:
            charge = await dotnet.charge_order_wallet(
                user_id, order_id=order_id, amount=amount,
            )
            if not charge.get("success", charge.get("Success")):
                return {
                    **base,
                    "paid": False,
                    "charge": charge,
                    "insufficient": bool(
                        charge.get("insufficientBalance") or charge.get("InsufficientBalance")
                    ),
                    "message": (
                        charge.get("failureReason")
                        or charge.get("FailureReason")
                        or "Thanh toán ví thất bại. Hãy nạp ví hoặc chọn VietQR."
                    ),
                }
            tx_id = str(charge.get("transactionId") or charge.get("TransactionId") or "")
            confirmed = await dotnet.confirm_order_payment(user_id, order_id, tx_id)
            return {
                **base,
                "paid": True,
                "charge": charge,
                "order_confirmed": confirmed,
                "message": f"Đã tạo đơn và trừ ví {amount:,.0f}đ.",
                "display_payload": [{
                    "type": "order_success",
                    "orderId": order_id,
                    "amount": amount,
                    "paymentMethod": "wallet",
                }],
            }

        if pref == "vietqr" and order_id:
            order_code = (
                action.get("order_code")
                or (order.get("orderCode") if isinstance(order, dict) else None)
                or (order.get("OrderCode") if isinstance(order, dict) else None)
                or ""
            )
            link = await dotnet.create_vietqr_payment(
                user_id,
                order_id=order_id,
                order_code=str(order_code),
                amount=amount,
            )
            return {
                **base,
                "payment_link": link,
                "display_payload": [{
                    "type": "payment_qr",
                    "orderId": order_id,
                    "checkoutUrl": link.get("checkoutUrl") or link.get("CheckoutUrl"),
                    "qrCode": link.get("qrCode") or link.get("QrCode"),
                    "payOsOrderCode": link.get("payOsOrderCode") or link.get("PayOsOrderCode"),
                    "amount": amount,
                }],
                "message": "Đã tạo đơn + VietQR. Quét mã để thanh toán; trạng thái cập nhật qua webhook.",
            }

        return {
            **base,
            "next_step": (
                "Đơn đã tạo (chưa thanh toán). "
                "Gọi pay_with_wallet hoặc create_payment_link rồi xác nhận tiếp."
            ),
            "message": "Đã tạo đơn (Deferred).",
        }

    if action_type == "pay_with_wallet":
        order_id = action.get("order_id") or ""
        if not order_id:
            raise ValueError("order_id is required for pay_with_wallet")
        order = await dotnet.get_order(user_id, order_id)
        amount = float(
            action.get("amount")
            or order.get("totalAmount")
            or order.get("TotalAmount")
            or 0
        )
        charge = await dotnet.charge_order_wallet(user_id, order_id=order_id, amount=amount)
        if not charge.get("success", charge.get("Success")):
            return {
                "paid": False,
                "charge": charge,
                "insufficient": bool(
                    charge.get("insufficientBalance") or charge.get("InsufficientBalance")
                ),
                "message": charge.get("failureReason") or charge.get("FailureReason") or "Thanh toán ví thất bại.",
            }
        tx_id = str(charge.get("transactionId") or charge.get("TransactionId") or "")
        confirmed = await dotnet.confirm_order_payment(user_id, order_id, tx_id)
        return {"paid": True, "charge": charge, "order": confirmed}

    if action_type == "create_payment_link":
        order_id = action.get("order_id") or ""
        if not order_id:
            raise ValueError("order_id is required for create_payment_link")
        order = await dotnet.get_order(user_id, order_id)
        amount = float(
            action.get("amount")
            or order.get("totalAmount")
            or order.get("TotalAmount")
            or 0
        )
        order_code = (
            action.get("order_code")
            or order.get("orderCode")
            or order.get("OrderCode")
            or ""
        )
        link = await dotnet.create_vietqr_payment(
            user_id,
            order_id=order_id,
            order_code=str(order_code),
            amount=amount,
        )
        return {
            "payment_link": link,
            "display_payload": [{
                "type": "payment_qr",
                "orderId": order_id,
                "checkoutUrl": link.get("checkoutUrl") or link.get("CheckoutUrl"),
                "qrCode": link.get("qrCode") or link.get("QrCode"),
                "payOsOrderCode": link.get("payOsOrderCode") or link.get("PayOsOrderCode"),
                "amount": amount,
            }],
            "message": "Đã tạo VietQR. Quét mã để thanh toán; trạng thái cập nhật qua PayOS webhook.",
        }

    if action_type == "reorder":
        prev = action.get("previous_order_id") or ""
        if not prev:
            raise ValueError("previous_order_id is required for reorder")
        idem = action.get("idempotency_key") or action.get("action_id") or str(uuid.uuid4())
        result = await dotnet.reorder(
            user_id,
            prev,
            idem,
            ai_reasoning_snapshot_json=action.get("ai_reasoning_snapshot_json"),
        )
        return {
            "order": result,
            "next_step": "Đơn reorder (Deferred). Tiếp tục pay_with_wallet hoặc create_payment_link.",
        }

    if action_type == "topup_wallet":
        amount = float(action.get("amount") or 0)
        method = action.get("method") or "VietQR"
        result = await dotnet.topup_wallet(user_id, amount, method)
        return {"topup": result}

    if action_type == "create_roadmap":
        result = await dotnet.create_roadmap(user_id, action.get("payload", {}))
        return {"roadmap": result}

    if action_type == "delete_roadmap":
        roadmap_id = action.get("roadmap_id", "")
        if not roadmap_id:
            raise ValueError("roadmap_id is required for delete_roadmap")
        result = await dotnet.delete_roadmap(user_id, roadmap_id)
        return {"deleted": result}

    if action_type == "reschedule_session":
        from app.tools.local import validate_time_change

        session_id = str(action.get("session_id") or "")
        new_date = str(action.get("new_date") or "")
        new_time = str(action.get("new_time") or "07:00")
        # Re-validate lúc thực thi (pending có thể cũ/bị sửa): cùng ngày + trước 22:00.
        current_date = ""
        try:
            session = await dotnet.get_roadmap_session(user_id, session_id)
            current_date = str(
                session.get("scheduledDate") or session.get("ScheduledDate") or ""
            )[:10]
        except Exception:
            pass
        if not new_date and current_date:
            new_date = current_date
        err = validate_time_change(
            current_date=current_date, new_date=new_date, new_time=new_time,
        )
        if err:
            return {"status": "error", "message": err}
        result = await dotnet.reschedule_session(user_id, session_id, new_date, new_time)
        return {"session": result}

    if action_type == "enable_ai_reschedule":
        roadmap_id = str(action.get("roadmap_id") or "")
        if not roadmap_id:
            raise ValueError("roadmap_id is required for enable_ai_reschedule")
        patched = await dotnet.update_roadmap(
            user_id,
            roadmap_id,
            {"allowAiReschedule": True},
        )
        staged = action.get("staged_plan") or {}
        if not isinstance(staged, dict) or not staged:
            return {
                "enabled": True,
                "roadmap": patched,
                "scheduled": None,
                "message": "Đã bật quyền AI chỉnh lịch.",
            }
        write = await execute_workout_plan_write(user_id, {
            **staged,
            "roadmap_id": staged.get("roadmap_id") or roadmap_id,
        })
        msg = "Đã cho phép AI chỉnh lịch và lưu lịch tập."
        if not write.get("verified"):
            msg = (
                "Đã bật quyền và gọi lưu lịch, nhưng chưa xác nhận được session trên Roadmap. "
                "Kiểm tra tab Workout."
            )
        return {
            "enabled": True,
            "roadmap": patched,
            "message": msg,
            **write,
        }

    if action_type == "upgrade_premium":
        link = await dotnet.create_premium_payment_link(
            user_id,
            plan_code=str(action.get("plan_hint") or "Premium"),
        )
        # Unwrap ApiResponse envelope if present
        payload = link.get("data") if isinstance(link, dict) and isinstance(link.get("data"), dict) else link
        if not isinstance(payload, dict):
            payload = link if isinstance(link, dict) else {}
        checkout = (
            payload.get("checkoutUrl")
            or payload.get("CheckoutUrl")
            or ""
        )
        qr = payload.get("qrCode") or payload.get("QrCode") or ""
        amount = payload.get("amount") or payload.get("Amount")
        display = {
            "type": "payment_qr",
            "purpose": "premium_upgrade",
            "checkoutUrl": checkout,
            "qrCode": qr,
            "amount": amount,
            "planName": "Premium",
            "orderCode": payload.get("orderCode") or payload.get("OrderCode"),
            "transactionId": payload.get("transactionId") or payload.get("TransactionId"),
        }
        return {
            "upgraded_checkout": payload,
            "display_payload": [display],
            "message": "Đã tạo VietQR nâng Premium. Quét mã hoặc mở link để thanh toán.",
        }

    if action_type in ("generate_week_plan", "plan_or_edit_workout"):
        staged = action.get("staged_plan") if isinstance(action.get("staged_plan"), dict) else {}
        mode = (
            (staged.get("mode") if staged else None)
            or action.get("mode")
            or "create"
        )
        if action_type == "generate_week_plan":
            mode = "create"
        payload = {
            "mode": mode,
            "roadmap_id": (staged.get("roadmap_id") if staged else None) or action.get("roadmap_id"),
            "sessions": (staged.get("sessions") if staged else None) or action.get("sessions"),
            "ops": (staged.get("ops") if staged else None) or action.get("ops"),
        }
        write = await execute_workout_plan_write(user_id, payload)
        if write.get("status") == "error":
            return {
                "status": "error",
                "message": write.get("message") or write.get("error") or "Không lưu được lịch tập.",
                **write,
            }
        ids = write.get("saved_session_ids") or []
        if write.get("verified"):
            msg = f"Đã lưu lịch tập ({len(ids)} session)." if ids else "Đã lưu lịch tập vào lộ trình."
        else:
            msg = (
                "Gọi lưu lịch xong nhưng chưa đọc lại được session trên Roadmap. "
                "Kiểm tra tab Workout."
            )
        return {"message": msg, **write}

    if action_type == "log_meal":
        result = await dotnet.log_meal(user_id, action.get("payload", {}))
        return {"meal_log": result}

    raise ValueError(f"Unsupported action type: {action_type}")


@app.post("/ai/chat/confirm")
async def confirm_action(req: ConfirmRequest, auth: AuthContext = Depends(require_auth)):
    """Xác nhận pending_action (write actions) sau confirmation gate."""
    graph = _ctx["graph"]
    config = trace_config(auth.user_id, req.session_id, {})
    snap = await graph.aget_state(config)
    if not snap or not snap.values:
        raise HTTPException(status_code=404, detail="Không tìm thấy hội thoại")

    pending = list(snap.values.get("pending_actions") or [])
    action = next((a for a in pending if a.get("action_id") == req.action_id), None)
    if not action:
        _log.warning(
            "confirm: action_id=%s not in pending_actions (count=%s types=%s) session=%s",
            req.action_id,
            len(pending),
            [a.get("type") for a in pending if isinstance(a, dict)],
            req.session_id,
        )
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy hành động chờ xác nhận (hết hạn hoặc đã xác nhận).",
        )

    if not req.confirmed:
        remaining = [a for a in pending if a.get("action_id") != req.action_id]
        await graph.aupdate_state(config, {"pending_actions": remaining, "requires_confirmation": bool(remaining)})
        return {"status": "cancelled", "action_id": req.action_id}

    if action.get("type") not in _SUPPORTED_ACTION_TYPES:
        raise HTTPException(status_code=400, detail=f"Loại hành động '{action.get('type')}' chưa hỗ trợ xác nhận")

    try:
        result = await _execute_confirmed_action(auth.user_id, action)
    except Exception as exc:
        from app.tools.dotnet import readable_error

        _log.exception(
            "confirm_execute_failed action_id=%s type=%s",
            req.action_id,
            action.get("type"),
        )
        # Soft error — keep pending so client can retry; never bare 502/RetryError.
        friendly = readable_error(exc)
        return {
            "status": "error",
            "action_id": req.action_id,
            "message": friendly or "Không thể thực hiện hành động. Thử lại sau.",
            "error": friendly,
        }

    if isinstance(result, dict) and result.get("status") == "error":
        return {
            "status": "error",
            "action_id": req.action_id,
            "message": result.get("message") or result.get("error") or "Thực hiện thất bại.",
            **{k: v for k, v in result.items() if k not in ("status",)},
        }

    remaining = [a for a in pending if a.get("action_id") != req.action_id]
    patch: dict[str, Any] = {
        "pending_actions": remaining,
        "requires_confirmation": bool(remaining),
    }
    if action.get("type") == "create_order":
        patch["cart"] = []
    await graph.aupdate_state(config, patch)
    return {"status": "completed", "action_id": req.action_id, **result}


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok", "service": "sync-ai", "version": app.version}


@app.get("/metrics")
async def prometheus_metrics() -> PlainTextResponse:
    try:
        from prometheus_client import CONTENT_TYPE_LATEST, generate_latest

        return PlainTextResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)
    except Exception:
        return PlainTextResponse("# prometheus_client not installed\n")


@app.post("/ai/chat")
async def chat(req: ChatRequest, request: Request, auth: AuthContext = Depends(require_auth)):
    """Chat SSE streaming. Trả token dần + sự kiện confirm/done."""
    from langchain_core.messages import HumanMessage
    from sse_starlette.sse import EventSourceResponse
    import asyncio
    from asyncio import CancelledError
    from time import perf_counter

    from app.graph.subscription_gating import normalize_tier, token_budget_for_subscription

    trace_id = str(uuid.uuid4())
    set_trace_id(trace_id)

    flow("▶ POST /ai/chat — nhận yêu cầu chat từ client")
    flow(f"Auth — JWT hợp lệ | user={auth.user_id} | tier={auth.tier} | role={auth.role}", indent=1)
    flow_data("Người dùng", auth.user_id, indent=1)
    flow_data("Phiên", req.session_id, indent=1)
    flow_data("Gói", auth.tier, indent=1)
    flow_data("Persona", auth.persona, indent=1)
    flow_data("Tin nhắn", req.message, indent=1, max_len=200)

    await _ctx["ratelimiter"].check(auth.user_id, auth.tier)
    if get_settings().rate_limit_enabled:
        flow("✓ Rate-limit: cho phép (chưa vượt hạn mức/phút)", indent=1)
    else:
        flow("○ Rate-limit: tắt (RATE_LIMIT_ENABLED=false)", indent=1)

    from app.tools import dotnet as dotnet_tools

    try:
        quota = await dotnet_tools.consume_ai_quota(auth.user_id)
        if quota.get("allowed") is False:
            flow(
                f"✗ Monthly AI quota exceeded ({quota.get('used')}/{quota.get('limit')})",
                indent=1,
            )
            raise HTTPException(
                status_code=429,
                detail="Đã đạt giới hạn AI tháng này (Free: 30 lượt). Nâng cấp Premium để không giới hạn.",
            )
        flow(
            f"✓ Monthly AI quota OK ({quota.get('used', '?')}/{quota.get('limit') or '∞'})",
            indent=1,
        )
    except HTTPException:
        raise
    except Exception:
        flow("○ Monthly AI quota check skipped (IAM unavailable)", indent=1)

    graph = _ctx["graph"]
    locale = req.locale or auth.locale
    subscription_tier = normalize_tier(auth.tier)
    token_budget = token_budget_for_subscription(subscription_tier)

    state = initial_state(
        user_id=auth.user_id, session_id=req.session_id, channel="chat",
        locale=locale, token_budget=token_budget,  # type: ignore[arg-type]
    )
    state["persona"] = auth.persona
    state["motivation_style"] = auth.motivation_style
    state["subscription_tier"] = subscription_tier
    state["messages"] = [HumanMessage(content=req.message)]
    state["handoff_count"] = 0
    # Cart là giỏ hàng phiên — giữ qua các turn (pop để checkpointer bảo toàn).
    # NGƯỢC LẠI pending_actions/requires_confirmation phải reset MỖI turn:
    # nếu giữ, action cũ chưa confirm sẽ re-fire guardrail spending-gate ở mọi
    # turn sau (chip "Cần xác nhận" hiện trên mọi message) và emit lại pending
    # card cũ. Action chưa confirm coi như hết hạn khi user nhắn tiếp — confirm
    # endpoint đã trả 404 "hết hạn" thân thiện cho card cũ trên client.
    # (pending_actions/requires_confirmation là channel last-write-wins nên
    # truyền [] / False trong input là reset sạch.)
    state.pop("cart", None)
    if req.latitude is not None and req.longitude is not None:
        state["user_latitude"] = float(req.latitude)
        state["user_longitude"] = float(req.longitude)
        flow_data("Vị trí client", f"{req.latitude},{req.longitude}", indent=1)
    if req.timezone and str(req.timezone).strip():
        state["user_timezone"] = str(req.timezone).strip()
    config = trace_config(auth.user_id, req.session_id, {"trace_id": trace_id})

    flow("→ Bắt đầu LangGraph pipeline (guardrail → supervisor [context∥intent] → agent → SSE)", indent=1)

    async def event_gen():
        final_intent, final_tier = "coach", "small"
        tools_called: list[str] = []
        turn_tool_outputs: list[dict[str, Any]] = []
        token_chunks = 0
        final_text = ""
        streamed_buffer: list[str] = []
        turn_start = perf_counter()
        cancelled = False
        with metrics.time_turn("chat"):
            try:
                async for ev in graph.astream_events(state, config, version="v2"):
                    if await request.is_disconnected():
                        flow("⚠ Client ngắt kết nối SSE — dừng stream", indent=1)
                        break
                    kind = ev.get("event")
                    node = ev.get("name", "")

                    if kind == "on_chain_start" and node in (
                        "guardrail_in", "supervisor",
                        "coach", "nutrition", "workout", "commerce", "insight",
                        "prepare_handoff", "guardrail_out",
                    ):
                        flow(f"⟳ Node [{node}] — bắt đầu", indent=2)

                    if kind == "on_chain_end" and node == "guardrail_in":
                        out = ev["data"].get("output") or {}
                        flags = out.get("guardrail_flags") or []
                        if flags:
                            flow_data("Guardrail IN — cờ", flags, indent=2)

                    if kind == "on_chain_end" and node == "supervisor":
                        out = ev["data"].get("output") or {}
                        final_intent = out.get("intent", final_intent)
                        final_tier = out.get("model_tier", final_tier)
                        snap = out.get("user_snapshot")
                        if snap:
                            flow_data("Context — snapshot (đã de-identify)", snap, indent=2, max_len=250)
                        elif "context_unavailable" in (out.get("guardrail_flags") or []):
                            flow("⚠ Context — không tải được IAM snapshot (chạy degrade)", indent=2)
                        flow(
                            f"Supervisor — intent={final_intent} | tier={final_tier} | "
                            f"confidence={out.get('intent_confidence')} | nguồn={out.get('intent_source')}",
                            indent=2,
                        )

                    if kind == "on_chat_model_stream":
                        # Only forward final narration tokens — nested planners / tool-phase
                        # streams must not appear in the user bubble.
                        ev_tags = ev.get("tags") or []
                        meta = ev.get("metadata") or {}
                        meta_tags = meta.get("tags") or []
                        if STREAM_FINAL_TAG not in ev_tags and STREAM_FINAL_TAG not in meta_tags:
                            continue
                        # Stream raw tokens — never strip/normalize per-piece (would delete
                        # inter-token spaces and break markdown image regex mid-stream).
                        piece = _normalize_stream_piece(
                            getattr(ev["data"].get("chunk"), "content", "")
                        )
                        if piece:
                            token_chunks += 1
                            streamed_buffer.append(piece)
                            if token_chunks == 1:
                                flow_timing(
                                    "First token SSE",
                                    int((perf_counter() - turn_start) * 1000),
                                    indent=2,
                                )
                                flow("◀ LLM bắt đầu stream token về client", indent=2)
                            yield {"event": "token", "data": piece}

                    elif kind == "on_chain_end" and node == "prepare_handoff":
                        out = ev["data"].get("output") or {}
                        payload = {
                            "to": out.get("target_agent"),
                            "reason": out.get("handoff_reason", ""),
                        }
                        # Nếu hop trước có lỡ stream text, ngăn dính chữ với hop sau.
                        if streamed_buffer and not streamed_buffer[-1].endswith(("\n", " ")):
                            streamed_buffer.append("\n\n")
                        flow_data("Handoff — chuyển agent", payload, indent=2)
                        yield {
                            "event": "handoff",
                            "data": json.dumps(payload, ensure_ascii=False),
                        }

                    elif kind == "on_chain_end" and node in (
                        "coach", "nutrition", "workout", "commerce", "insight",
                    ):
                        out = ev["data"].get("output") or {}
                        tr = (out.get("tool_results") or {}).get("_tools_called") or []
                        tools_called.extend(tr)
                        outputs = (out.get("tool_results") or {}).get("_outputs") or []
                        turn_tool_outputs.extend(outputs)
                        if tr:
                            flow_data(f"Agent [{node}] — tools đã gọi", tr, indent=2)
                        final_text = out.get("final_response") or final_text
                        final_resp = (out.get("final_response") or "")[:120]
                        if final_resp:
                            flow_data(f"Agent [{node}] — phản hồi (rút gọn)", final_resp, indent=2)
                        for pa in out.get("pending_actions") or []:
                            flow_data("SSE → pending_action", pa, indent=2)
                            yield {
                                "event": "pending_action",
                                "data": json.dumps(pa, ensure_ascii=False),
                            }
                        for dp in out.get("display_payload") or []:
                            flow_data("SSE → display_payload", dp, indent=2)
                            yield {
                                "event": "display_payload",
                                "data": json.dumps(dp, ensure_ascii=False),
                            }

                    elif kind == "on_chain_end" and node == "guardrail_out":
                        out = ev["data"].get("output") or {}
                        if out.get("requires_confirmation"):
                            flow("Guardrail OUT — cần xác nhận chi tiêu (spending gate)", indent=2)
                            yield {"event": "confirm", "data": "spending_requires_confirmation"}
                        flags = out.get("guardrail_flags") or []
                        if flags:
                            flow_data("Guardrail OUT — cờ", flags, indent=2)
                        for flag in flags:
                            metrics.inc_block(flag)

            except CancelledError:
                cancelled = True
                flow("⚠ Client disconnect — generator cancelled", indent=1)
                return
            except Exception as exc:  # pragma: no cover
                _log.exception("chat_error", extra={"trace_id": trace_id})
                flow(f"✗ Lỗi pipeline: {exc}", indent=1)
                yield {"event": "error", "data": str(exc)}

        if token_chunks == 0 and final_text.strip():
            piece = final_text  # strip markdown only in final_payload below
            streamed_buffer.append(piece)
            yield {"event": "token", "data": piece}
            token_chunks = 1

        metrics.inc_turn(final_intent, final_tier)
        snap = await graph.aget_state(config)
        st = snap.values if snap else {}
        flow(
            f"■ Kết thúc turn | intent={final_intent} | tier={final_tier} | "
            f"tokens≈{st.get('tokens_used', 0)} | SSE tokens={token_chunks} | tools={tools_called}",
            indent=1,
        )
        # Prefer full streamed turn (all hops) over last-hop final_response alone.
        # Strip markdown ONLY on the complete message (not per token).
        joined = _strip_markdown_for_chat("".join(streamed_buffer))
        hop_text = _strip_markdown_for_chat(final_text)
        if joined and (not hop_text or len(joined) >= len(hop_text)):
            reply_text = joined
        else:
            reply_text = hop_text or joined
        final_payload = {
            "type": "final",
            "text": reply_text,
            "intent": final_intent,
            "tier": final_tier,
            "subscription_tier": subscription_tier,
            "model_tier": final_tier,
            "tools": list(dict.fromkeys(tools_called)),
            "tool_results": turn_tool_outputs,
            "requires_confirmation": st.get("requires_confirmation", False),
        }
        final_json = json.dumps(final_payload, ensure_ascii=False)
        yield {"event": "final", "data": final_json}
        yield {"event": "done", "data": "[DONE]"}

        async def _write_audit_bg() -> None:
            try:
                bg_snap = await graph.aget_state(config)
                bg_st = bg_snap.values if bg_snap else st
                a = audit_mod.TurnAudit(
                    trace_id=trace_id, user_id=auth.user_id, session_id=req.session_id,
                    intent=final_intent, tier=final_tier, locale=locale,
                    tokens_used=bg_st.get("tokens_used", 0), estimated_cost_usd=0.0,
                    guardrail_flags=bg_st.get("guardrail_flags", []),
                    requires_confirmation=bg_st.get("requires_confirmation", False),
                    tools_called=list(dict.fromkeys(tools_called)),
                )
                audit_mod.write_audit(a)
                await audit_mod.persist_turn_audit(a)
            except Exception:
                _log.exception("audit_background_failed", extra={"trace_id": trace_id})

        track = _ctx.get("track_background_task")
        task = asyncio.create_task(_write_audit_bg())
        if callable(track):
            track(task)
        else:
            _ctx.setdefault("background_tasks", set()).add(task)
            task.add_done_callback(_ctx["background_tasks"].discard)

    return EventSourceResponse(
        event_gen(),
        headers={
            "X-Accel-Buffering": "no",
            "Cache-Control": "no-cache, no-transform",
        },
        ping=15,
    )


@app.get("/ai/conversations/{session_id}")
async def get_conversation(session_id: str, auth: AuthContext = Depends(require_auth)):
    """Lấy state hội thoại từ checkpointer (lịch sử)."""
    graph = _ctx["graph"]
    config = {"configurable": {"thread_id": session_id}}
    snap = await graph.aget_state(config)
    if not snap or not snap.values:
        raise HTTPException(status_code=404, detail="Không tìm thấy hội thoại")
    msgs = snap.values.get("messages", [])
    return {
        "session_id": session_id,
        "messages": [
            {"role": getattr(m, "type", "?"), "content": getattr(m, "content", "")}
            for m in msgs
        ],
    }


# --- P2 placeholders ---------------------------------------------------------
@app.post("/ai/voice", status_code=501)
async def voice() -> dict[str, str]:
    return {"detail": "Async voice thuộc P2 — chưa bật ở MVP Chat."}


@app.websocket("/ai/realtime")
async def realtime(ws: WebSocket):
    await ws.accept()
    await ws.send_json({"error": "Realtime voice thuộc P2 — chưa bật ở MVP Chat."})
    await ws.close()
