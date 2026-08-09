"""Coach Agent — hội thoại, động viên, Q&A + memory/gamification/web-search."""
from __future__ import annotations

import re
from typing import Any

from langchain_core.runnables import RunnableConfig

from app.graph.agents.base import last_user_text
from app.graph.agents.runner import run_tool_agent
from app.state import SyncAgentState
from app.text_norm import strip_accents
from app.tools.rag import rag_fitness_kb

_COACH_EXTRA_BASE = """
## Vai trò
Trợ lý hội thoại, FAQ fitness, động viên. KHÔNG trực tiếp xử lý lịch tập hay dinh dưỡng cụ thể — handoff sang workout/nutrition khi cần.

## Báo cân nặng (Premium — Adaptive Engine)
- User báo cân nặng mới ("mình 92kg") → gọi log_weight(weight_kg=X) — engine tự
  tính lại mục tiêu; bạn CHỈ diễn giải kết quả tool (cũ→mới + lý do + confidence),
  không tự tính. Free → tool tự trả upsell.

## Chọn đích handoff đúng
- Thống kê/tổng quan/biểu đồ/xu hướng/dự đoán theo NHIỀU ngày·tuần·tháng (kể cả về
  dinh dưỡng hay tập luyện) → handoff insight, KHÔNG phải nutrition/workout.
- Tìm/mua/đặt món thật, quán ăn, giỏ hàng, ví/thanh toán → handoff commerce.
- Khi handoff: KHÔNG dài dòng "mình sẽ chuyển bạn..." — gọi tool là đủ, agent kế tiếp trả lời.

## Trả lời câu hỏi chung
- Câu hỏi chung về fitness, sức khỏe, tâm lý → dùng kiến thức nội tại + RAG từ KB nội bộ (đã được inject bên dưới).
- Câu hỏi cần độ chính xác cao (nghiên cứu mới, số liệu y tế, tư vấn khoa học) → dùng web_search trước, trích dẫn nguồn.

## Giải thích các thông số hệ thống
- RecoveryProfile: CurrentRecoveryScore (0-100 tổng trạng thái phục hồi), FatigueLevel (1-10 mệt mỏi tổng quát),
  MuscleSorenessScore (1-10 đau nhức cơ), CnsFatigueScore (1-10 mệt hệ thần kinh trung ương),
  RecommendedTrainingIntensity (Low/Moderate/High), RecommendedWorkoutDuration (phút).
- PersonalizedRoadmap: FitnessGoal, CurrentPhase, StartDate/ExpectedEndDate, CurrentWeightKg/TargetWeightKg,
  InitialFatPercentage/TargetFatPercentage, AdaptiveAiEnabled/AllowAiReschedule/AllowAiIntensityAdjustment/AllowAiRecoveryDeload.
- TDEE/macro: BaseTDEE = tổng năng lượng tiêu thụ mỗi ngày; Protein/Carb/Fat target tính từ BiometricProfile.

## Cảm xúc & động viên
- User chia sẻ stress, mệt mỏi → lắng nghe, động viên, gọi recall_user_memory để cá nhân hóa.
- Phát hiện khủng hoảng sức khỏe tâm thần → gọi escalate_to_human ngay.

## Sử dụng web_search
- Chỉ dùng khi câu hỏi cần xác minh cao: nghiên cứu khoa học, thuốc, bệnh lý cụ thể.
- Luôn trích dẫn URL nguồn khi dùng kết quả web_search.
- KHÔNG dùng web_search cho câu hỏi fitness cơ bản — RAG nội bộ đủ.
"""


def _skip_rag(state: SyncAgentState, query: str) -> bool:
    if state.get("model_tier") == "small":
        return True
    tokens = re.findall(r"[\w']+", strip_accents(query or ""))
    if len(tokens) <= 3:
        return True
    if state.get("intent_source") == "heuristic" and state.get("intent") == "coach":
        return True
    return False


async def coach_agent(state: SyncAgentState, config: RunnableConfig) -> dict[str, Any]:
    query = last_user_text(state)
    kb = ""
    if query and not _skip_rag(state, query):
        kb = await rag_fitness_kb(query)

    extra = _COACH_EXTRA_BASE
    if kb:
        extra = f"Kiến thức tham khảo (chỉ dùng nếu liên quan):\n{kb}\n\n" + extra

    return await run_tool_agent(
        state, "coach",
        extra_context=extra,
        fallback_text="[coach] Mình ở đây để hỗ trợ bạn nhé!",
        config=config,
    )
