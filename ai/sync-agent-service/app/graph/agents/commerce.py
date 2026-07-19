"""Commerce Agent — tư vấn quán/món + đặt đơn/thanh toán (spending gate)."""
from __future__ import annotations

import json
import math
import re
import uuid
from typing import Any

from langchain_core.runnables import RunnableConfig

from app.graph.agents.runner import run_tool_agent
from app.state import SyncAgentState
from app.tools import dotnet
from app.tools.context import ToolRunContext

_FAR_WARN_KM = 5.0
_FAR_REFUSE_KM = 10.0

_GUID_RE = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)


def _is_guid(value: Any) -> bool:
    return bool(_GUID_RE.match(str(value or "").strip()))


def _norm_name(value: str) -> str:
    return re.sub(r"\s+", " ", (value or "").strip().lower())


def _names_compatible(a: str, b: str) -> bool:
    """Loose match so LLM short names still accept catalog titles."""
    na, nb = _norm_name(a), _norm_name(b)
    if not na or not nb:
        return False
    if na == nb or na in nb or nb in na:
        return True
    ta = {t for t in re.split(r"[^a-z0-9à-ỹ]+", na) if len(t) >= 3}
    tb = {t for t in re.split(r"[^a-z0-9à-ỹ]+", nb) if len(t) >= 3}
    if not ta or not tb:
        return False
    overlap = len(ta & tb)
    return overlap >= max(1, min(len(ta), len(tb)) // 2)


def _parse_pay_pref(raw: str) -> str:
    s = (raw or "").strip().lower()
    if "wallet" in s or "ví sync" in s or "sync wallet" in s:
        return "wallet"
    if "vietqr" in s or "qr" in s or "chuyển khoản" in s:
        return "vietqr"
    if "cod" in s or "nhận hàng" in s:
        return "cod"
    return ""


def _is_place_order_intent(text: str) -> bool:
    """User wants checkout/form — must NOT mutate cart qty."""
    raw = (text or "").strip()
    if not raw:
        return False
    low = raw.lower()
    # Form submit is handled by _parse_checkout_confirm, not this helper.
    if "thông tin giao hàng" in low or "thong tin giao hang" in low:
        return False
    if "delivery_confirmed=true" in low:
        return False
    needles = (
        "tiến hành đặt hàng",
        "tien hanh dat hang",
        "tiến hành đặt đơn",
        "tien hanh dat don",
        "xác nhận đặt hàng",
        "xac nhan dat hang",
        "checkout",
        "đặt hàng đi",
        "dat hang di",
        "đặt đơn đi",
        "dat don di",
    )
    if any(n in low for n in needles):
        return True
    compact = re.sub(r"\s+", " ", low).strip(" !.？?")
    return compact in {
        "đặt hàng",
        "dat hang",
        "đặt đơn",
        "dat don",
        "đặt luôn",
        "dat luon",
        "order",
        "order now",
    }


def _parse_checkout_confirm(text: str) -> dict[str, str] | None:
    """Parse Flutter checkout_form submit bubble (deterministic path)."""
    raw = (text or "").strip()
    if not raw:
        return None
    low = raw.lower()
    if "thông tin giao hàng" not in low and "thong tin giao hang" not in low:
        return None
    if "phương thức thanh toán" not in low and "phuong thuc thanh toan" not in low:
        return None

    def _cap(label: str) -> str:
        m = re.search(
            rf"{label}\s*:\s*([^;\n]+)",
            raw,
            flags=re.IGNORECASE,
        )
        return (m.group(1).strip().rstrip(".") if m else "")

    name = _cap("Tên") or _cap("Ho ten") or _cap("Họ tên")
    phone = _cap("SĐT") or _cap("SDT") or _cap("Số điện thoại") or _cap("So dien thoai")
    # Address may contain "TP. HCM" — stop before payment clause, not at first ".".
    addr_m = re.search(
        r"(?:Địa chỉ|Dia chi)\s*:\s*(.+?)(?:\s*\.\s*Phương thức|\s*\.\s*Phuong thuc|\s*;\s*|$)",
        raw,
        flags=re.IGNORECASE | re.DOTALL,
    )
    address = (addr_m.group(1).strip().rstrip(".") if addr_m else "")
    if not address:
        address = _cap("Địa chỉ") or _cap("Dia chi")
    pay_m = re.search(
        r"Phương thức thanh toán\s*:\s*([^\n.]+)|Phuong thuc thanh toan\s*:\s*([^\n.]+)",
        raw,
        flags=re.IGNORECASE,
    )
    pay_raw = ""
    if pay_m:
        pay_raw = (pay_m.group(1) or pay_m.group(2) or "").strip()
    pay = _parse_pay_pref(pay_raw) or "cod"
    phone_digits = re.sub(r"\D+", "", phone)
    if len(phone_digits) < 9 or not address:
        return None
    return {
        "name": name,
        "phone": phone_digits if phone_digits else phone,
        "address": address,
        "payment_method_pref": pay,
    }


_PROPOSE_SCHEMA = {
    "type": "function",
    "function": {
        "name": "propose_order",
        "description": (
            "Đề xuất đặt đơn từ cart phiên (hoặc items[]). KHÔNG đặt thật. "
            "Lần gọi đầu (delivery_confirmed=false): hiện form thông tin giao hàng "
            "(pre-fill từ profile) + chọn PTTT để user xác nhận. "
            "Sau khi user xác nhận → gọi lại với delivery_confirmed=true + payment_method_pref. "
            f"{_FAR_WARN_KM:.0f}–{_FAR_REFUSE_KM:.0f}km → cần accept_distance; >{_FAR_REFUSE_KM:.0f}km từ chối. "
            "Luôn chờ user xác nhận thông tin giao hàng VÀ PTTT trước khi đặt."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "partner_id": {
                    "type": "string",
                    "description": "GUID thật từ search_partners/get_partner_detail/cart — KHÔNG tự bịa",
                },
                "items": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "food_menu_item_id": {
                                "type": "string",
                                "description": "GUID foodId từ dish_list/get_menu/cart — KHÔNG tự bịa",
                            },
                            "quantity": {"type": "integer"},
                            "notes": {"type": "string"},
                        },
                        "required": ["food_menu_item_id", "quantity"],
                    },
                },
                "use_cart": {
                    "type": "boolean",
                    "description": "True (mặc định) để lấy items từ cart phiên",
                },
                "delivery_confirmed": {
                    "type": "boolean",
                    "description": (
                        "False (mặc định): hiện form giao hàng + payment để user xác nhận. "
                        "True: user đã xác nhận thông tin giao hàng + PTTT → tiến hành quote và đặt."
                    ),
                },
                "recipient_name": {"type": "string"},
                "recipient_phone": {"type": "string"},
                "delivery_address": {"type": "string"},
                "delivery_lat": {"type": "number"},
                "delivery_lng": {"type": "number"},
                "voucher_code": {"type": "string"},
                "payment_method_pref": {
                    "type": "string",
                    "description": "wallet | cod | vietqr | ask — ask để hiện lựa chọn",
                },
                "accept_distance": {
                    "type": "boolean",
                    "description": (
                        f"True khi user đã chấp nhận khoảng cách {_FAR_WARN_KM:.0f}–{_FAR_REFUSE_KM:.0f}km"
                    ),
                },
                "accept_distance_over_7km": {
                    "type": "boolean",
                    "description": "Deprecated alias của accept_distance",
                },
                "summary": {"type": "string"},
                "reason": {"type": "string", "description": "Lý do AI đề xuất (snapshot)"},
            },
            "required": ["partner_id"],
        },
    },
}

_CART_SCHEMAS = [
    {
        "type": "function",
        "function": {
            "name": "add_to_cart",
            "description": (
                "Thêm ĐÚNG món user yêu cầu vào cart (mặc định qty=1). "
                "BẮT BUỘC truyền food_id GUID của món đó (từ dish_list/search_partner_dishes "
                "cho ĐÚNG tên món) + name. CẤM tái sử dụng foodId món khác đang có trong cart. "
                "Không gọi tool này khi user chỉ bảo đặt hàng/checkout."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "food_id": {"type": "string"},
                    "qty": {"type": "integer"},
                    "name": {
                        "type": "string",
                        "description": "Tên món user muốn thêm — dùng để đối chiếu food_id",
                    },
                    "partner_id": {"type": "string"},
                    "unit_price": {"type": "number"},
                    "replace_cart": {
                        "type": "boolean",
                        "description": "True nếu user đồng ý xoá giỏ quán cũ để thêm món quán khác",
                    },
                },
                "required": ["food_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "update_cart_item",
            "description": "Cập nhật số lượng món trong cart (qty<=0 = xoá).",
            "parameters": {
                "type": "object",
                "properties": {
                    "food_id": {"type": "string"},
                    "qty": {"type": "integer"},
                },
                "required": ["food_id", "qty"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "remove_from_cart",
            "description": "Xoá món khỏi cart phiên.",
            "parameters": {
                "type": "object",
                "properties": {"food_id": {"type": "string"}},
                "required": ["food_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "view_cart",
            "description": "Xem cart phiên + tổng tạm tính; phát card cart.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "estimate_delivery",
            "description": (
                "Ước khoảng cách/ETA/phí ship tới partner theo lat/lng giao hàng. "
                f"Áp luật ≤{_FAR_WARN_KM:.0f} ok; {_FAR_WARN_KM:.0f}–{_FAR_REFUSE_KM:.0f} cảnh báo; "
                f">{_FAR_REFUSE_KM:.0f}km từ chối."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "partner_id": {"type": "string"},
                    "lat": {"type": "number"},
                    "lng": {"type": "number"},
                },
                "required": ["partner_id"],
            },
        },
    },
]


def _norm_items(items: list | None) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for raw in items or []:
        if not isinstance(raw, dict):
            continue
        fid = (
            raw.get("food_menu_item_id")
            or raw.get("foodMenuItemId")
            or raw.get("foodId")
            or raw.get("id")
        )
        if not fid:
            continue
        qty = int(raw.get("quantity") or raw.get("qty") or raw.get("Quantity") or 1)
        line: dict[str, Any] = {
            "foodMenuItemId": str(fid),
            "quantity": max(1, qty),
        }
        notes = raw.get("notes") or raw.get("Notes")
        if notes:
            line["notes"] = str(notes)
        out.append(line)
    return out


def _cart_to_items(cart: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return _norm_items([
        {
            "food_menu_item_id": c.get("foodId") or c.get("food_id"),
            "quantity": c.get("qty") or c.get("quantity") or 1,
        }
        for c in cart
        if isinstance(c, dict)
    ])


def _cart_total(cart: list[dict[str, Any]]) -> float:
    total = 0.0
    for c in cart:
        if not isinstance(c, dict):
            continue
        try:
            price = float(c.get("unitPrice") or c.get("unit_price") or 0)
            qty = int(c.get("qty") or c.get("quantity") or 1)
            total += price * max(1, qty)
        except (TypeError, ValueError):
            continue
    return total


def _emit_cart_card(ctx: ToolRunContext, cart: list[dict[str, Any]]) -> None:
    ctx.display_payload.append({
        "type": "cart",
        "items": cart,
        "total": _cart_total(cart),
        "count": len(cart),
    })


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def _estimate_eta_minutes(distance_km: float) -> int:
    return max(15, int(round(15 + distance_km * 3)))


def _estimate_ship_fee(distance_km: float) -> float:
    # Transparent heuristic until quote provides authoritative fee.
    if distance_km <= 3:
        return 15000.0
    if distance_km <= _FAR_WARN_KM:
        return 20000.0
    if distance_km <= _FAR_REFUSE_KM:
        return 35000.0
    return 50000.0


def _wallet_balance_vnd(wallet: dict[str, Any]) -> float:
    coins = float(wallet.get("coinBalance") or wallet.get("availableBalance") or 0)
    vnd_per = float(wallet.get("vndPerCoin") or 100)
    if wallet.get("balanceVnd") is not None or wallet.get("BalanceVnd") is not None:
        try:
            return float(wallet.get("balanceVnd") or wallet.get("BalanceVnd") or 0)
        except (TypeError, ValueError):
            pass
    return coins * vnd_per


def _partner_coords(partner_detail: dict[str, Any]) -> tuple[float | None, float | None]:
    p_lat = partner_detail.get("lat") or partner_detail.get("Lat") or partner_detail.get("latitude")
    p_lng = partner_detail.get("lng") or partner_detail.get("Lng") or partner_detail.get("longitude")
    loc = partner_detail.get("location") or partner_detail.get("Location") or {}
    if isinstance(loc, dict):
        p_lat = p_lat or loc.get("lat") or loc.get("Lat")
        p_lng = p_lng or loc.get("lng") or loc.get("Lng")
    try:
        return (
            float(p_lat) if p_lat is not None else None,
            float(p_lng) if p_lng is not None else None,
        )
    except (TypeError, ValueError):
        return None, None


async def _resolve_distance_km(
    user_id: str,
    partner_id: str,
    lat: float | None,
    lng: float | None,
) -> tuple[float | None, int | None, dict[str, Any]]:
    partner_detail: dict[str, Any] = {}
    try:
        partner_detail = await dotnet.get_partner_detail(
            user_id,
            partner_id,
            lat=float(lat) if lat is not None else None,
            lng=float(lng) if lng is not None else None,
        )
    except Exception:
        partner_detail = {}
    if not isinstance(partner_detail, dict):
        partner_detail = {}

    distance_km: float | None = None
    for key in ("distanceKm", "DistanceKm", "distance", "Distance"):
        if partner_detail.get(key) is not None:
            try:
                distance_km = float(partner_detail[key])
                break
            except (TypeError, ValueError):
                pass

    p_lat, p_lng = _partner_coords(partner_detail)
    if distance_km is None and lat is not None and lng is not None and p_lat is not None and p_lng is not None:
        try:
            distance_km = round(_haversine_km(float(lat), float(lng), float(p_lat), float(p_lng)), 2)
        except (TypeError, ValueError):
            distance_km = None

    eta = _estimate_eta_minutes(distance_km) if distance_km is not None else None
    return distance_km, eta, partner_detail


async def commerce_agent(state: SyncAgentState, config: RunnableConfig) -> dict[str, Any]:
    from app.graph.subscription_gating import commerce_allowed, normalize_tier

    user_id = state["user_id"]
    snapshot = state.get("user_snapshot", {}) or {}
    sub = normalize_tier(
        state.get("subscription_tier")
        or snapshot.get("subscriptionTier")
        or snapshot.get("SubscriptionTier")
    )

    if not commerce_allowed(sub):
        action_id = str(uuid.uuid4())
        summary = (
            "Gói Free chưa gồm tư vấn quán/món Sync, review và đặt món. "
            "Nâng Premium để mở khóa commerce và hạn mức AI cao hơn."
        )
        prose = (
            "Hiện bạn đang dùng gói Free nên mình chưa mở được các nghiệp vụ "
            "tìm quán, xem món/review hay đặt món trên Sync. "
            "Gói Premium mở khóa toàn bộ phần này và tăng hạn mức AI. "
            "Bạn có muốn nâng cấp lên Premium không? Bấm xác nhận để mình gửi mã VietQR thanh toán."
        )
        pending = {
            "action_id": action_id,
            "type": "upgrade_premium",
            "plan_hint": "Premium",
            "summary": summary,
            "status": "awaiting_confirmation",
        }
        return {
            "final_response": prose,
            "pending_actions": [*(state.get("pending_actions") or []), pending],
            "requires_confirmation": True,
            "tokens_used": state.get("tokens_used", 0),
        }

    per_order_limit = float(snapshot.get("maxAutoOrderLimitPerOrder") or 100000)
    daily_limit = snapshot.get("maxAutoOrderLimitDaily")
    allergies = [str(x).lower() for x in (snapshot.get("allergies") or [])]
    disliked = [str(x).lower() for x in (snapshot.get("dislikedFoods") or [])]
    has_loc = state.get("user_latitude") is not None and state.get("user_longitude") is not None
    ctx = ToolRunContext(user_id=user_id, state=dict(state))
    cart: list[dict[str, Any]] = [
        dict(x) for x in (state.get("cart") or []) if isinstance(x, dict)
    ]
    cart_dirty = False

    def _mark_cart(new_cart: list[dict[str, Any]]) -> list[dict[str, Any]]:
        nonlocal cart, cart_dirty
        cart = new_cart
        cart_dirty = True
        ctx.state["cart"] = cart
        return cart

    async def _resolve_food_for_cart(
        food_id: str,
        name: str,
    ) -> tuple[str | None, dict[str, Any], str, str]:
        """Return (food_id, detail, dish_name, partner_id) for the intended dish.

        Prefers name match when the GUID points at a different dish (common LLM bug).
        """
        fid = str(food_id or "").strip()
        want_name = (name or "").strip()
        detail: dict[str, Any] = {}
        if _is_guid(fid):
            try:
                detail = await dotnet.get_food_detail(user_id, fid)
            except Exception:
                detail = {}
            if isinstance(detail, dict) and not detail.get("error"):
                detail_name = str(
                    detail.get("nameVi")
                    or detail.get("NameVi")
                    or detail.get("name")
                    or detail.get("Name")
                    or ""
                )
                pid = str(detail.get("partnerId") or detail.get("PartnerId") or "")
                if not want_name or _names_compatible(want_name, detail_name):
                    return fid, detail, detail_name or want_name, pid

        query = want_name or ""
        if not query:
            return (fid if _is_guid(fid) else None), detail, want_name, ""

        try:
            searched = await dotnet.search_partner_dishes(
                user_id, query=query, limit=8,
            )
        except Exception:
            searched = {}
        items = []
        if isinstance(searched, dict):
            items = (
                searched.get("items")
                or searched.get("Items")
                or searched.get("data")
                or searched.get("Data")
                or []
            )
            if isinstance(items, dict):
                items = items.get("items") or items.get("Items") or []
        best: dict[str, Any] | None = None
        for raw in items if isinstance(items, list) else []:
            if not isinstance(raw, dict):
                continue
            n = str(
                raw.get("nameVi")
                or raw.get("NameVi")
                or raw.get("name")
                or raw.get("Name")
                or ""
            )
            if _names_compatible(query, n):
                best = raw
                break
        if best is None and isinstance(items, list) and items and isinstance(items[0], dict):
            best = items[0]
        if not best:
            return None, {}, want_name, ""

        resolved_id = str(
            best.get("id")
            or best.get("Id")
            or best.get("foodId")
            or best.get("foodMenuItemId")
            or ""
        ).strip()
        resolved_name = str(
            best.get("nameVi")
            or best.get("NameVi")
            or best.get("name")
            or want_name
        )
        resolved_pid = str(
            best.get("partnerId") or best.get("PartnerId") or ""
        )
        if not _is_guid(resolved_id):
            return None, best, resolved_name, resolved_pid
        return resolved_id, best, resolved_name, resolved_pid

    async def _add_to_cart(
        food_id: str = "",
        qty: int = 1,
        name: str = "",
        partner_id: str = "",
        unit_price: float = 0,
        replace_cart: bool = False,
        **_: Any,
    ) -> dict[str, Any]:
        ctx.tools_called.append("add_to_cart")
        quantity = max(1, min(int(qty or 1), 20))
        want_name = (name or "").strip()

        fid, detail, dish_name, pid = await _resolve_food_for_cart(food_id, want_name)
        pid = str(partner_id or pid or "").strip()
        price = float(unit_price or 0)

        if not fid or not _is_guid(fid):
            return {
                "status": "error",
                "message": (
                    f"Không tìm được foodId hợp lệ cho «{want_name or food_id}». "
                    "Gọi search_partner_dishes với ĐÚNG tên món rồi dùng foodId từ kết quả."
                ),
            }

        if isinstance(detail, dict) and detail and not detail.get("error"):
            if price <= 0:
                try:
                    price = float(detail.get("price") or detail.get("Price") or 0)
                except (TypeError, ValueError):
                    price = 0
            if not pid:
                pid = str(detail.get("partnerId") or detail.get("PartnerId") or "")
            if not dish_name:
                dish_name = str(
                    detail.get("nameVi") or detail.get("NameVi") or detail.get("name") or ""
                )

        # If LLM reused cart foodId for a different dish name — already corrected
        # by _resolve_food_for_cart; also block increasing wrong line.
        name_l = (dish_name or want_name).lower()
        for a in allergies:
            if a and a in name_l:
                return {
                    "status": "blocked_allergy",
                    "message": f"Món «{dish_name}» trùng dị ứng đã khai ({a}). Không thêm vào cart.",
                }
        for d in disliked:
            if d and d in name_l:
                return {
                    "status": "blocked_dislike",
                    "message": f"Món «{dish_name}» nằm trong danh sách không thích. Đổi món khác nhé.",
                }

        cart_partners = {
            str(c.get("partnerId") or c.get("partner_id") or "").strip()
            for c in cart
            if isinstance(c, dict) and (c.get("partnerId") or c.get("partner_id"))
        }
        cart_partners.discard("")
        if pid and cart_partners and pid not in cart_partners and not replace_cart:
            old_names = ", ".join(
                str(c.get("name") or "?") for c in cart if isinstance(c, dict)
            ) or "món cũ"
            return {
                "status": "partner_conflict",
                "cart_partner_ids": sorted(cart_partners),
                "new_partner_id": pid,
                "food_id": fid,
                "name": dish_name,
                "message": (
                    f"Giỏ đang có món quán khác ({old_names}). "
                    f"«{dish_name}» thuộc quán khác nên không trộn chung một đơn. "
                    "User cần nói xoá giỏ rồi thêm món mới, hoặc đặt đơn quán hiện tại trước. "
                    "Khi user đồng ý xoá giỏ → gọi lại add_to_cart(..., replace_cart=true)."
                ),
            }

        updated = [] if replace_cart else [dict(x) for x in cart]
        found = False
        for row in updated:
            if str(row.get("foodId")) == fid:
                # Only bump qty when adding THE SAME dish — never via wrong GUID.
                row["qty"] = int(row.get("qty") or 1) + quantity
                if dish_name:
                    row["name"] = dish_name
                if pid:
                    row["partnerId"] = pid
                if price > 0:
                    row["unitPrice"] = price
                found = True
                break
        if not found:
            updated.append({
                "foodId": fid,
                "name": dish_name or want_name or fid,
                "partnerId": pid,
                "unitPrice": price,
                "qty": quantity,
            })
        _mark_cart(updated)
        _emit_cart_card(ctx, updated)
        return {
            "status": "ok",
            "cart": updated,
            "food_id": fid,
            "name": dish_name or want_name,
            "partner_id": pid,
            "total": _cart_total(updated),
            "message": f"Đã thêm {quantity} × {dish_name or want_name or fid} vào cart.",
        }

    async def _update_cart_item(food_id: str = "", qty: int = 1, **_: Any) -> dict[str, Any]:
        ctx.tools_called.append("update_cart_item")
        fid = str(food_id or "").strip()
        if not fid:
            return {"status": "error", "message": "Thiếu food_id."}
        quantity = int(qty)
        updated = []
        for row in cart:
            if str(row.get("foodId")) != fid:
                updated.append(dict(row))
                continue
            if quantity <= 0:
                continue
            new_row = dict(row)
            new_row["qty"] = quantity
            updated.append(new_row)
        _mark_cart(updated)
        _emit_cart_card(ctx, updated)
        return {"status": "ok", "cart": updated, "total": _cart_total(updated)}

    async def _remove_from_cart(food_id: str = "", **_: Any) -> dict[str, Any]:
        ctx.tools_called.append("remove_from_cart")
        fid = str(food_id or "").strip()
        updated = [dict(x) for x in cart if str(x.get("foodId")) != fid]
        _mark_cart(updated)
        _emit_cart_card(ctx, updated)
        return {"status": "ok", "cart": updated, "total": _cart_total(updated)}

    async def _view_cart(**_: Any) -> dict[str, Any]:
        ctx.tools_called.append("view_cart")
        _emit_cart_card(ctx, cart)
        return {
            "status": "ok",
            "cart": cart,
            "total": _cart_total(cart),
            "count": len(cart),
            "message": "Cart trống." if not cart else f"Cart có {len(cart)} dòng.",
        }

    async def _estimate_delivery_tool(
        partner_id: str = "",
        lat: float | None = None,
        lng: float | None = None,
        **_: Any,
    ) -> dict[str, Any]:
        ctx.tools_called.append("estimate_delivery")
        if not partner_id:
            return {"status": "error", "message": "Thiếu partner_id."}
        contact = await dotnet.get_default_contact(user_id)
        use_lat = lat if lat is not None else contact.get("lat")
        use_lng = lng if lng is not None else contact.get("lng")
        if use_lat is None:
            use_lat = state.get("user_latitude")
        if use_lng is None:
            use_lng = state.get("user_longitude")
        if use_lat is None or use_lng is None:
            return {
                "status": "needs_input",
                "message": "Thiếu toạ độ giao hàng để ước khoảng cách.",
                "missing": ["lat", "lng"],
            }
        distance_km, eta_minutes, _ = await _resolve_distance_km(
            user_id, partner_id, float(use_lat), float(use_lng),
        )
        if distance_km is None:
            return {"status": "error", "message": "Không tính được khoảng cách tới quán."}
        ship = _estimate_ship_fee(distance_km)
        if distance_km > _FAR_REFUSE_KM:
            return {
                "status": "refused_distance",
                "distance_km": distance_km,
                "eta_minutes": eta_minutes,
                "estimated_ship_fee": ship,
                "message": (
                    f"Quán cách ~{distance_km:.1f}km (> {_FAR_REFUSE_KM:.0f}km) — "
                    "mình không hỗ trợ đặt qua chat. Bạn đặt thủ công trên Marketplace nhé."
                ),
            }
        warn = distance_km > _FAR_WARN_KM
        return {
            "status": "ok" if not warn else "needs_distance_accept",
            "distance_km": distance_km,
            "eta_minutes": eta_minutes,
            "estimated_ship_fee": ship,
            "accept_required": warn,
            "message": (
                f"Cách ~{distance_km:.1f}km, ETA ~{eta_minutes} phút, phí ship ước ~{ship:,.0f}đ."
                + (
                    f" Trên {_FAR_WARN_KM:.0f}km — giao có thể lâu hơn/phí cao hơn, cần bạn xác nhận."
                    if warn
                    else ""
                )
            ),
        }

    async def _propose_order(
        partner_id: str = "",
        items: list | None = None,
        use_cart: bool = True,
        delivery_confirmed: bool = False,
        recipient_name: str = "",
        recipient_phone: str = "",
        delivery_address: str = "",
        delivery_lat: float | None = None,
        delivery_lng: float | None = None,
        voucher_code: str = "",
        payment_method_pref: str = "ask",
        accept_distance: bool = False,
        accept_distance_over_7km: bool = False,
        summary: str = "",
        reason: str = "",
        amount: float = 0,  # ignored — quote is source of truth
        **_: Any,
    ) -> dict[str, Any]:
        ctx.tools_called.append("propose_order")
        accepted_far = bool(accept_distance or accept_distance_over_7km)

        # Prefer session cart when items omitted / use_cart.
        # One order = one partner — never silently mix multi-restaurant lines.
        norm_items = _norm_items(items)
        if (use_cart or not norm_items) and cart:
            if not partner_id:
                partner_id = str(
                    cart[0].get("partnerId") or cart[0].get("partner_id") or ""
                )
            partner_cart = [
                c for c in cart
                if isinstance(c, dict)
                and (
                    not partner_id
                    or str(c.get("partnerId") or c.get("partner_id") or "") == partner_id
                )
            ]
            skipped = [
                str(c.get("name") or c.get("foodId") or "?")
                for c in cart
                if isinstance(c, dict) and c not in partner_cart
            ]
            cart_items = _cart_to_items(partner_cart)
            if cart_items:
                norm_items = cart_items
            if skipped:
                # Keep note for the LLM/user — don't order foreign-partner lines.
                ctx.state["_propose_skipped_items"] = skipped

        if not partner_id:
            return {"status": "error", "message": "Thiếu partner_id."}
        if not norm_items:
            return {
                "status": "error",
                "message": "Giỏ hàng trống — thêm món (add_to_cart) trước khi đề xuất đơn.",
            }

        # .NET nhận Guid — id bịa (vd ObjectId 24-hex) sẽ 400. Chặn sớm với message
        # hành động được để model tự sửa (search lại), thay vì RetryError mù.
        if not _is_guid(partner_id):
            return {
                "status": "error",
                "message": (
                    f"partner_id '{partner_id}' không phải GUID hợp lệ. "
                    "KHÔNG tự bịa id — dùng đúng partnerId từ kết quả search_partners/"
                    "get_partner_detail hoặc từ cart."
                ),
            }
        bad_ids = [i["foodMenuItemId"] for i in norm_items if not _is_guid(i["foodMenuItemId"])]
        if bad_ids:
            return {
                "status": "error",
                "message": (
                    f"foodMenuItemId không hợp lệ (không phải GUID): {', '.join(bad_ids[:3])}. "
                    "Dùng đúng foodId từ dish_list/get_menu/cart, không tự tạo id."
                ),
            }

        contact = await dotnet.get_default_contact(user_id)
        name = (recipient_name or contact.get("fullName") or contact.get("name") or "").strip()
        phone = (recipient_phone or contact.get("phone") or "").strip()
        address = (delivery_address or contact.get("address") or "").strip()
        lat = delivery_lat if delivery_lat is not None else contact.get("lat")
        lng = delivery_lng if delivery_lng is not None else contact.get("lng")
        if lat is None and state.get("user_latitude") is not None:
            lat = state.get("user_latitude")
        if lng is None and state.get("user_longitude") is not None:
            lng = state.get("user_longitude")

        # --- STEP 1: Always show delivery_info_form + payment selection ---
        # Unless delivery_confirmed=true (user already confirmed via form).
        if not delivery_confirmed:
            # Build form fields: show ALL fields, mark missing ones as required.
            missing: list[str] = []
            if not name:
                missing.append("name")
            if not phone:
                missing.append("phone")
            if not address:
                missing.append("address")

            # Always include all 3 core fields so user can review/edit pre-filled data.
            fields = [
                {
                    "key": "name",
                    "label": "Họ tên",
                    "required": True,
                    "prefilled": bool(name),
                },
                {
                    "key": "phone",
                    "label": "Số điện thoại",
                    "required": True,
                    "prefilled": bool(phone),
                },
                {
                    "key": "address",
                    "label": "Địa chỉ giao",
                    "required": True,
                    "type": "location",
                    "prefilled": bool(address),
                },
            ]
            # Include location picker when coords missing even if address text exists.
            if address and (lat is None or lng is None):
                fields[-1]["needs_coordinates"] = True

            prefill = {
                "name": name,
                "phone": phone,
                "address": address,
                "lat": lat,
                "lng": lng,
            }

            # Fetch wallet for payment options.
            wallet = await dotnet.check_wallet(user_id)
            balance = _wallet_balance_vnd(wallet if isinstance(wallet, dict) else {})
            # Estimate total from cart for display (actual quote comes after confirmation).
            est_total = _cart_total(cart) if cart else 0.0

            # Add payment_method as a select field INSIDE the form so user submits
            # delivery info + payment method together in ONE form submission.
            fields.append({
                "key": "payment_method",
                "label": "Phương thức thanh toán",
                "required": True,
                "type": "select",
                "options": [
                    {
                        "value": "wallet",
                        "label": f"Sync Wallet ({balance:,.0f}đ)",
                        "disabled": balance < est_total,
                        "hint": f"Thiếu {est_total - balance:,.0f}đ" if balance < est_total else None,
                    },
                    {"value": "cod", "label": "COD (thanh toán khi nhận hàng)"},
                    {"value": "vietqr", "label": "VietQR (chuyển khoản)"},
                ],
            })

            # Emit a SINGLE unified checkout_form — delivery info + payment method
            # in one card, one submit. Prevents the loop where submitting delivery
            # info loses payment selection and vice versa.
            ctx.display_payload.append({
                "type": "checkout_form",
                "fields": fields,
                "prefill": prefill,
                "partner_id": partner_id,
                "missing": missing,
                "walletBalance": balance,
                "walletSufficient": balance >= est_total,
                "amount": est_total,
            })

            # Build cart summary for the confirmation message.
            cart_summary_parts: list[str] = []
            for c in cart:
                if isinstance(c, dict):
                    cname = c.get("name") or c.get("foodId") or "?"
                    cqty = c.get("qty") or c.get("quantity") or 1
                    cprice = float(c.get("unitPrice") or c.get("unit_price") or 0)
                    cart_summary_parts.append(f"{cname} ×{cqty} ({cprice:,.0f}đ)")
            cart_summary = "; ".join(cart_summary_parts) if cart_summary_parts else "(từ items)"

            return {
                "status": "needs_delivery_confirmation",
                "missing": missing,
                "prefill": prefill,
                "cart_summary": cart_summary,
                "estimated_total": est_total,
                "message": (
                    "Vui lòng xác nhận thông tin giao hàng và chọn phương thức thanh toán. "
                    + (
                        f"Thiếu: {', '.join(missing)}. "
                        if missing
                        else "Thông tin đã được điền sẵn từ hồ sơ, bạn có thể chỉnh sửa. "
                    )
                    + "Sau khi xác nhận, mình sẽ tiến hành đặt đơn."
                ),
            }

        # --- STEP 2: delivery_confirmed=true — proceed with quote + order ---
        missing_hard: list[str] = []
        phone_digits = re.sub(r"\D+", "", phone or "")
        if not name:
            missing_hard.append("name")
        if len(phone_digits) < 9:
            missing_hard.append("phone")
        else:
            phone = phone_digits
        if not address:
            missing_hard.append("address")
        if missing_hard:
            # Re-show unified form instead of asking in a loop for one field.
            return await _propose_order(
                partner_id=partner_id,
                items=items,
                use_cart=use_cart,
                delivery_confirmed=False,
                recipient_name=name,
                recipient_phone=phone,
                delivery_address=address,
                delivery_lat=delivery_lat,
                delivery_lng=delivery_lng,
                voucher_code=voucher_code,
                payment_method_pref="ask",
                summary=summary,
                reason=reason,
            )

        quote = await dotnet.quote_order(
            user_id,
            partner_id=partner_id,
            items=norm_items,
            voucher_code=voucher_code or "",
        )
        if not quote.get("isValid", quote.get("IsValid", True)):
            return {
                "status": "error",
                "message": quote.get("errorMessage") or quote.get("ErrorMessage") or "Quote thất bại.",
                "quote": quote,
            }

        total = float(quote.get("total") or quote.get("Total") or 0)
        delivery_fee = float(quote.get("deliveryFee") or quote.get("DeliveryFee") or 0)
        lines = quote.get("lines") or quote.get("Lines") or []
        allergy_hits: list[str] = []
        for line in lines:
            if not isinstance(line, dict):
                continue
            name_vi = str(line.get("nameVi") or line.get("NameVi") or "").lower()
            for a in allergies:
                if a and a in name_vi:
                    allergy_hits.append(name_vi)
            for d in disliked:
                if d and d in name_vi:
                    allergy_hits.append(name_vi)
        if allergy_hits:
            return {
                "status": "blocked_allergy",
                "message": (
                    "Trong giỏ có món trùng dị ứng/không thích đã khai: "
                    + ", ".join(sorted(set(allergy_hits)))
                    + ". Đổi món khác giúp mình."
                ),
                "quote": quote,
            }

        distance_km, eta_minutes, _partner = await _resolve_distance_km(
            user_id, partner_id,
            float(lat) if lat is not None else None,
            float(lng) if lng is not None else None,
        )

        if distance_km is not None and distance_km > _FAR_REFUSE_KM:
            return {
                "status": "refused_distance",
                "distance_km": distance_km,
                "eta_minutes": eta_minutes,
                "amount": total,
                "delivery_fee": delivery_fee,
                "message": (
                    f"Quán cách ~{distance_km:.1f}km (trên {_FAR_REFUSE_KM:.0f}km) — "
                    "mình không hỗ trợ đặt qua chat. Bạn đặt thủ công trên Marketplace giúp mình."
                ),
                "partner_id": partner_id,
            }

        if distance_km is not None and distance_km > _FAR_WARN_KM and not accepted_far:
            return {
                "status": "needs_far_accept",
                "distance_km": distance_km,
                "eta_minutes": eta_minutes,
                "amount": total,
                "delivery_fee": delivery_fee,
                "message": (
                    f"Quán cách ~{distance_km:.1f}km (trên {_FAR_WARN_KM:.0f}km), "
                    f"ETA ~{eta_minutes} phút, phí ship {delivery_fee:,.0f}đ, tổng ~{total:,.0f}đ. "
                    "Giao có thể lâu hơn và phí ship tăng. Bạn có đồng ý tiếp tục không?"
                ),
                "partner_id": partner_id,
                "accept_distance_required": True,
            }

        pref = (payment_method_pref or "ask").strip().lower()
        if pref in ("", "ask", "select", "none"):
            wallet = await dotnet.check_wallet(user_id)
            balance = _wallet_balance_vnd(wallet if isinstance(wallet, dict) else {})
            ctx.display_payload.append({
                "type": "payment_method_select",
                "walletBalance": balance,
                "walletBalanceLabel": f"Số dư ví: {balance:,.0f}đ",
                "walletSufficient": balance >= total,
                "amount": total,
                "distanceKm": distance_km,
                "etaMinutes": eta_minutes,
                "options": ["wallet", "cod", "vietqr"],
            })
            dist_bit = (
                f"Cách ~{distance_km:.1f}km, ETA ~{eta_minutes} phút. "
                if distance_km is not None and eta_minutes is not None
                else ""
            )
            return {
                "status": "needs_payment_method",
                "amount": total,
                "distance_km": distance_km,
                "eta_minutes": eta_minutes,
                "breakdown": {
                    "subtotal": quote.get("subtotal") or quote.get("Subtotal"),
                    "deliveryFee": delivery_fee,
                    "discount": quote.get("discount") or quote.get("Discount"),
                    "total": total,
                },
                "message": (
                    f"{dist_bit}Tổng ~{total:,.0f}đ (ship {delivery_fee:,.0f}đ). "
                    "Chọn 1 phương thức: Sync Wallet / COD / VietQR."
                ),
            }

        if pref not in ("wallet", "cod", "vietqr"):
            pref = "wallet"

        over = total > per_order_limit
        if daily_limit is not None:
            try:
                over = over or total > float(daily_limit)
            except (TypeError, ValueError):
                pass

        action_id = str(uuid.uuid4())
        reasoning = {
            "reason": reason or summary or "AI propose_order",
            "quote": {
                "subtotal": quote.get("subtotal") or quote.get("Subtotal"),
                "deliveryFee": delivery_fee,
                "discount": quote.get("discount") or quote.get("Discount"),
                "total": total,
            },
            "distance_km": distance_km,
            "eta_minutes": eta_minutes,
            "payment_method_pref": pref,
            "accept_distance": bool(accepted_far),
            "cart": cart,
        }

        dist_summary = (
            f" · {distance_km:.1f}km · ETA {eta_minutes}p"
            if distance_km is not None and eta_minutes is not None
            else ""
        )
        ctx.pending_actions.append({
            "action_id": action_id,
            "type": "create_order",
            "idempotency_key": action_id,
            "partner_id": partner_id,
            "items": norm_items,
            "recipient_name": name,
            "recipient_phone": phone,
            "delivery_address": address,
            "delivery_lat": lat,
            "delivery_lng": lng,
            "voucher_code": voucher_code or None,
            "payment_method_pref": pref,
            "amount": total,
            "distance_km": distance_km,
            "eta_minutes": eta_minutes,
            "breakdown": {
                "subtotal": quote.get("subtotal") or quote.get("Subtotal"),
                "deliveryFee": delivery_fee,
                "discount": quote.get("discount") or quote.get("Discount"),
                "total": total,
            },
            "summary": summary or f"Đặt đơn {total:,.0f}đ ({pref}){dist_summary} — chờ xác nhận",
            "ai_reasoning_snapshot_json": json.dumps(reasoning, ensure_ascii=False),
            "over_limit": over,
            "status": "awaiting_confirmation",
        })

        return {
            "status": "pending_confirmation",
            "action_id": action_id,
            "amount": total,
            "distance_km": distance_km,
            "eta_minutes": eta_minutes,
            "breakdown": ctx.pending_actions[-1]["breakdown"],
            "over_limit": over,
            "limit": per_order_limit,
            "payment_method_pref": pref,
            "contact": {"name": name, "phone": phone, "address": address},
            "note": (
                f"Cần xác nhận trên app. Thanh toán bằng {pref}. "
                + (
                    f"Khoảng cách ~{distance_km:.1f}km, ETA ~{eta_minutes} phút."
                    if distance_km is not None
                    else ""
                )
            ),
        }

    allergy_line = (
        f"Dị ứng đã khai: {', '.join(str(x) for x in (snapshot.get('allergies') or []))}. "
        if snapshot.get("allergies") else ""
    )
    dislike_line = (
        f"Không thích: {', '.join(str(x) for x in (snapshot.get('dislikedFoods') or []))}. "
        if snapshot.get("dislikedFoods") else ""
    )
    loc_line = (
        "Client ĐÃ gửi lat/lng — CHỈ dùng khi user hỏi GẦN (gần tôi/gần đây/quanh đây)."
        if has_loc
        else (
            "Chưa có lat/lng. CHỈ gọi request_user_location khi user hỏi quán GẦN "
            "(gần tôi/gần đây/quanh đây). Gọi tối đa 1 lần/lượt."
        )
    )
    # Build detailed cart line showing each item so the AI always knows what's in the cart.
    if cart:
        cart_detail_parts: list[str] = []
        for idx, c in enumerate(cart, 1):
            if not isinstance(c, dict):
                continue
            c_name = c.get("name") or c.get("foodId") or "?"
            c_qty = int(c.get("qty") or c.get("quantity") or 1)
            c_price = float(c.get("unitPrice") or c.get("unit_price") or 0)
            c_pid = c.get("partnerId") or c.get("partner_id") or ""
            c_fid = c.get("foodId") or c.get("food_id") or ""
            cart_detail_parts.append(
                f"{idx}) {c_name} ×{c_qty} @{c_price:,.0f}đ "
                f"[foodId={c_fid}, partnerId={c_pid}]"
            )
        cart_line = (
            f"Cart phiên ({len(cart)} dòng, tạm tính {_cart_total(cart):,.0f}đ): "
            + "; ".join(cart_detail_parts)
            + ". "
        )
    else:
        cart_line = "Cart phiên đang trống. "

    # Deterministic checkout paths — bypass LLM so it cannot bump cart qty /
    # re-add wrong items / claim missing fields after a valid form submit.
    from app.graph.agents.base import last_user_text

    user_text = last_user_text(state)
    checkout = _parse_checkout_confirm(user_text)
    if checkout and cart:
        pid0 = str(cart[0].get("partnerId") or cart[0].get("partner_id") or "")
        confirmed = await _propose_order(
            partner_id=pid0,
            use_cart=True,
            delivery_confirmed=True,
            recipient_name=checkout["name"],
            recipient_phone=checkout["phone"],
            delivery_address=checkout["address"],
            payment_method_pref=checkout["payment_method_pref"],
            delivery_lat=state.get("user_latitude"),
            delivery_lng=state.get("user_longitude"),
        )
        status = str(confirmed.get("status") or "")
        msg = str(confirmed.get("message") or confirmed.get("note") or "")
        if status == "pending_confirmation":
            prose = (
                "Đã nhận đủ thông tin giao hàng và phương thức thanh toán. "
                f"{msg} Bấm xác nhận trên card để hoàn tất đơn."
            )
        elif status in ("needs_delivery_confirmation", "needs_payment_method", "needs_input"):
            prose = msg or "Vui lòng kiểm tra lại form đặt hàng."
        else:
            prose = msg or "Đang xử lý đặt hàng."

        out: dict[str, Any] = {
            "final_response": prose,
            "tokens_used": state.get("tokens_used", 0),
        }
        if ctx.pending_actions:
            out["pending_actions"] = [
                *(state.get("pending_actions") or []),
                *ctx.pending_actions,
            ]
            out["requires_confirmation"] = True
        if ctx.display_payload:
            out["display_payload"] = [
                *(state.get("display_payload") or []),
                *ctx.display_payload,
            ]
        # Never rewrite cart on form confirm.
        return out

    if _is_place_order_intent(user_text):
        if not cart:
            return {
                "final_response": (
                    "Giỏ hàng đang trống nên chưa đặt được. "
                    "Hãy chọn món và thêm vào giỏ trước nhé."
                ),
                "tokens_used": state.get("tokens_used", 0),
            }
        pid0 = str(cart[0].get("partnerId") or cart[0].get("partner_id") or "")
        form_res = await _propose_order(
            partner_id=pid0,
            use_cart=True,
            delivery_confirmed=False,
        )
        prose = str(form_res.get("message") or "")
        if not prose:
            prose = (
                "Mình mở form xác nhận đặt hàng. "
                "Kiểm tra thông tin giao hàng, chọn PTTT rồi bấm xác nhận — "
                "số lượng trong giỏ giữ nguyên."
            )
        out = {
            "final_response": prose,
            "tokens_used": state.get("tokens_used", 0),
        }
        if ctx.display_payload:
            out["display_payload"] = [
                *(state.get("display_payload") or []),
                *ctx.display_payload,
            ]
        # Cart intentionally unchanged — no cart_dirty write.
        return out

    extra = (
        f"Hạn mức tự động/đơn: {per_order_limit:,.0f}đ. "
        "Tư vấn READ (dùng TOOL, không bịa, KHÔNG markdown/ảnh trong text): "
        "search_partners / search_nearby_partners / search_partner_dishes / "
        "get_partner_detail / get_food_detail / get_menu / get_partner_reviews / get_food_reviews / "
        "evaluate_food_fit / recommend_partner_meals. "
        "Chỉ nguồn Sync/Marketplace — empty → nói rõ chưa có trên Sync, KHÔNG bịa món ngoài. "
        "Tìm MÓN theo tên/calo/rating (vd 'ức gà', 'salad') → CHỈ search_partner_dishes "
        "(KHÔNG truyền lat/lng, KHÔNG xin vị trí, KHÔNG mở radius). "
        "Tìm quán GẦN → search_nearby_partners; chưa có lat/lng → request_user_location một lần. "
        "Sau khi list món: follow-up chi tiết/review/đánh giá dinh dưỡng DÙNG foodId/id từ item "
        "(get_food_detail / get_food_reviews / evaluate_food_fit) — KHÔNG search lại bằng tên. "
        "Narration ngắn; danh sách/ảnh để display_payload (dish_list/partner_list/cart/…). "
        "CART — QUAN TRỌNG: "
        "Thêm món MỚI (tên khác món trong cart): BẮT BUỘC search_partner_dishes(query=tên) "
        "rồi add_to_cart(food_id=GUID_mới, name=tên_món, qty=1). "
        "CẤM tái dùng foodId món đang có trong cart. "
        "Một đơn chỉ 1 partner — món khác quán → partner_conflict (không cộng qty món cũ). "
        "User nói 'tiến hành đặt hàng'/'đặt hàng'/'checkout' → CHỈ propose_order(use_cart=true), "
        "TUYỆT ĐỐI KHÔNG add_to_cart/update_cart_item. "
        "add_to_cart = cộng dồn đúng foodId; update_cart_item = đặt số lượng tuyệt đối. "
        "Xem cart → view_cart; xoá → remove_from_cart. "
        f"{cart_line}"
        "GIAO DỊCH: MỌI thao tác tiền (đặt đơn, ví, VietQR, COD, nạp, reorder) PHẢI xác nhận trên app — "
        "kể cả khi user nói 'đặt luôn không hỏi'. "
        "ĐẶT ĐƠN (2 BƯỚC): "
        "Bước 1: propose_order(use_cart=true, delivery_confirmed=false) → hiện checkout_form "
        "(giao hàng + radio PTTT, một nút gửi). Chờ user xác nhận. "
        "Bước 2: Khi user gửi tin có Tên/SĐT/Địa chỉ + 'Phương thức thanh toán' "
        "(COD / VietQR / Sync Wallet) → GỌI NGAY "
        "propose_order(delivery_confirmed=true, payment_method_pref=wallet|cod|vietqr, "
        "recipient_name=..., recipient_phone=..., delivery_address=...) với đúng giá trị form. "
        "KHÔNG hiện lại form nếu đã đủ name+phone+address+payment. "
        "KHÔNG hỏi lặp từng field / PTTT riêng. "
        f"≤{_FAR_WARN_KM:.0f}km bình thường; {_FAR_WARN_KM:.0f}–{_FAR_REFUSE_KM:.0f}km cảnh báo + "
        f"accept_distance=true khi user đồng ý; >{_FAR_REFUSE_KM:.0f}km từ chối đặt qua chat. "
        "Có thể gọi estimate_delivery(partner_id, lat, lng) trước. "
        "KHÔNG nói 'không chấp nhận đặt món qua đây' — đặt món qua chat là hợp lệ với HITL. "
        "VietQR: đưa QR/link, chờ webhook PayOS; poll get_payment_status — KHÔNG tự đánh dấu đã trả. "
        "Ví: check_wallet; thiếu tiền → topup_wallet hoặc chuyển VietQR. "
        f"{allergy_line}{dislike_line}{loc_line} "
        "Không lộ khoá/API nội bộ. Không bịa giá/phí/số dư/km/ETA."
    )

    out = await run_tool_agent(
        state,
        "commerce",
        extra_context=extra,
        extra_impls={
            "propose_order": _propose_order,
            "add_to_cart": _add_to_cart,
            "update_cart_item": _update_cart_item,
            "remove_from_cart": _remove_from_cart,
            "view_cart": _view_cart,
            "estimate_delivery": _estimate_delivery_tool,
        },
        extra_schemas=[_PROPOSE_SCHEMA, *_CART_SCHEMAS],
        fallback_text="[commerce] Mình có thể gợi ý quán/món và hỗ trợ đặt đơn (có xác nhận).",
        config=config,
        use_bound_cache=False,
    )
    if ctx.pending_actions:
        out["pending_actions"] = [
            *(state.get("pending_actions") or []),
            *(out.get("pending_actions") or []),
            *ctx.pending_actions,
        ]
        out["requires_confirmation"] = True
    if ctx.display_payload:
        out["display_payload"] = [
            *(state.get("display_payload") or []),
            *(out.get("display_payload") or []),
            *ctx.display_payload,
        ]
    if cart_dirty:
        out["cart"] = cart
    if ctx.tools_called:
        prev = list((out.get("tool_results") or {}).get("_tools_called") or [])
        out["tool_results"] = {
            **(out.get("tool_results") or {}),
            "_tools_called": prev + ctx.tools_called,
        }
    return out
