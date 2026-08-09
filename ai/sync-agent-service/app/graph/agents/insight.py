"""Insight Agent — thống kê + biểu đồ + dự đoán (Premium cho đa kỳ)."""
from __future__ import annotations

import uuid
from typing import Any

from langchain_core.runnables import RunnableConfig

from app.graph.agents.runner import run_tool_agent
from app.graph.subscription_gating import insight_premium_allowed, normalize_tier
from app.state import SyncAgentState
from app.tools.insight_charts import premium_upsell_payload


async def insight_agent(state: SyncAgentState, config: RunnableConfig) -> dict[str, Any]:
    snapshot = state.get("user_snapshot") or {}
    sub = normalize_tier(
        state.get("subscription_tier")
        or snapshot.get("subscriptionTier")
        or snapshot.get("SubscriptionTier")
    )
    premium = insight_premium_allowed(sub)

    if premium:
        extra = (
            "Bạn là Insight Premium. Khi user hỏi tổng quan dinh dưỡng N tuần/tháng, "
            "tiến độ tập, mức ăn có ổn không, khi nào đạt mục tiêu → GỌI TOOL: "
            "get_nutrition_stats / evaluate_nutrition_adequacy / get_workout_stats / "
            "get_body_progress / predict_outcome / build_insight_dashboard. "
            "Câu ĐÁNH GIÁ dinh dưỡng ('dinh dưỡng mấy ngày nay/tuần này thế nào', "
            "'ăn uống ra sao', 'nhận xét chế độ ăn') → gọi get_nutrition_stats + "
            "evaluate_nutrition_adequacy (period phù hợp: 'mấy ngày nay'≈7d, 'tuần này'≈7d, "
            "'tháng này'≈30d), trả nhận định + biểu đồ. Nhắc mục tiêu khuyến nghị: giảm mỡ nên "
            "thâm hụt 200-400 kcal và ưu tiên món ít dầu mỡ (tool đã tính vùng này). "
            "build_insight_dashboard khi cần gộp nhiều biểu đồ. "
            "Narration ngắn; số liệu CHỈ từ tool; biểu đồ ở display_payload (không markdown). "
            "Nêu rõ yếu tố dựa vào + độ tin cậy; thiếu dữ liệu → báo thiếu, không bịa. "
            "Dự đoán là ước lượng, không phải tư vấn y khoa. "
            "Dùng get_progress_trends / detect_burnout / detect_plateau / generate_weekly_report "
            "khi phù hợp; burnout cao → handoff workout/coach."
        )
    else:
        extra = (
            "User đang Free. Được tóm tắt 1 ngày qua get_daily_summary / get_today_workout. "
            "Nếu user yêu cầu thống kê đa kỳ, biểu đồ, dự đoán ETA, tổng quan tuần/tháng, "
            "nhận định dinh dưỡng dài hạn — gọi get_nutrition_stats (hoặc tool chart khác): "
            "tool sẽ trả premium_required + upsell VietQR. "
            "KHÔNG bịa số liệu chart. Giải thích lợi ích Premium ngắn gọn."
        )

    out = await run_tool_agent(
        state,
        "insight",
        extra_context=extra,
        fallback_text="[insight] Phân tích tiến độ sẽ hiển thị ở đây.",
        config=config,
    )

    # Ensure Free path that somehow skipped tools still gets a soft tip — only if no pending.
    if not premium and not (out.get("pending_actions") or state.get("pending_actions")):
        # Do not auto-upsell every turn; tools handle advanced requests.
        pass

    return out


def free_premium_upsell_state(state: SyncAgentState) -> dict[str, Any]:
    """Optional hard short-circuit (commerce-style) — available for callers."""
    action_id = str(uuid.uuid4())
    pending = {
        "action_id": action_id,
        "type": "upgrade_premium",
        "plan_hint": "Premium",
        "summary": "Nâng Premium để mở AI Insights & biểu đồ.",
        "status": "awaiting_confirmation",
    }
    return {
        "final_response": (
            "Thống kê đa kỳ, biểu đồ dinh dưỡng/tập luyện và dự đoán mục tiêu "
            "là tính năng Premium. Bạn có muốn nâng cấp không? Bấm xác nhận để nhận mã VietQR."
        ),
        "pending_actions": [*(state.get("pending_actions") or []), pending],
        "requires_confirmation": True,
        "display_payload": [
            *(state.get("display_payload") or []),
            premium_upsell_payload(),
        ],
        "tokens_used": state.get("tokens_used", 0),
    }
