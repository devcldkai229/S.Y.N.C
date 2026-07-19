"""Central tool registry — schema (LLM) + async impl bindings per agent."""
from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import Any, Awaitable, Callable

from app.tools import dotnet, local
from app.tools import insight_stats as _insight
from app.tools.context import ToolRunContext, safe_tool_call
from app.tools import websearch as _ws

ToolFn = Callable[..., Awaitable[dict[str, Any]]]


@dataclass(frozen=True)
class ToolDef:
    name: str
    description: str
    parameters: dict[str, Any]
    agents: frozenset[str]
    tool_type: str = "read"  # read | write | financial | safety | control


def _obj(props: dict[str, Any], required: list[str] | None = None) -> dict[str, Any]:
    schema: dict[str, Any] = {"type": "object", "properties": props}
    if required:
        schema["required"] = required
    return schema


def _registry() -> dict[str, ToolDef]:
    empty = _obj({})
    return {
        "get_today_workout": ToolDef(
            "get_today_workout", "Lấy buổi tập hôm nay.",
            _obj({"date_label": {"type": "string", "description": "today|tomorrow|yesterday"}}),
            frozenset({"workout", "insight"}),
        ),
        "get_active_roadmap": ToolDef(
            "get_active_roadmap", "Lấy PersonalizedRoadmap AI đang active (phase, goal, flags, AI settings).",
            empty, frozenset({"workout"}),
        ),
        "get_roadmap_sessions": ToolDef(
            "get_roadmap_sessions", "Danh sách tất cả buổi tập theo roadmap.",
            _obj({"roadmap_id": {"type": "string"}}, ["roadmap_id"]),
            frozenset({"workout"}),
        ),
        "get_workout_schedule": ToolDef(
            "get_workout_schedule",
            "Lấy lịch tập trong khoảng ngày (hôm nay/ngày mai/hôm qua/cả tuần). "
            "Dùng when user hỏi 'hôm nay tập gì', 'lịch tập tuần này'.",
            _obj({
                "from_date": {"type": "string", "description": "ISO-8601 date YYYY-MM-DD, mặc định hôm nay"},
                "to_date": {"type": "string", "description": "ISO-8601 date YYYY-MM-DD, mặc định = from_date"},
            }),
            frozenset({"workout"}),
        ),
        "get_workout_history": ToolDef(
            "get_workout_history",
            "Lịch sử buổi tập đã hoàn thành (WorkoutExecutionLog). "
            "Dùng khi user hỏi 'tuần trước tập mấy buổi', 'đã tập hôm nay chưa'.",
            _obj({
                "from_date": {"type": "string", "description": "ISO-8601 YYYY-MM-DD"},
                "to_date": {"type": "string", "description": "ISO-8601 YYYY-MM-DD"},
            }),
            frozenset({"workout", "insight"}),
        ),
        "create_roadmap": ToolDef(
            "create_roadmap",
            "Tạo PersonalizedRoadmap mới cho user. PHẢI xác nhận trước khi thực hiện. "
            "Chỉ tạo được 1 roadmap/user — nếu đã có phải xoá trước.",
            _obj({
                "roadmap_name": {"type": "string"},
                "fitness_goal": {"type": "string", "description": "LoseFat|BuildMuscle|Maintain|ImproveEndurance"},
                "current_phase": {"type": "string"},
                "start_date": {"type": "string", "description": "ISO-8601"},
                "current_weight_kg": {"type": "number"},
                "target_weight_kg": {"type": "number"},
                "initial_fat_percentage": {"type": "number"},
                "target_fat_percentage": {"type": "number"},
            }, ["roadmap_name", "fitness_goal", "current_phase", "start_date"]),
            frozenset({"workout"}), "write",
        ),
        "delete_roadmap": ToolDef(
            "delete_roadmap",
            "Xoá PersonalizedRoadmap hiện tại kèm tất cả sessions. PHẢI xác nhận trước. "
            "Yêu cầu khi user muốn tạo lộ trình mới.",
            _obj({"roadmap_id": {"type": "string"}}, ["roadmap_id"]),
            frozenset({"workout"}), "write",
        ),
        "reschedule_session": ToolDef(
            "reschedule_session",
            "Đổi GIỜ 1 buổi tập (chỉ buổi chưa tập — Scheduled). PHẢI xác nhận. "
            "LUẬT: chỉ đổi trong CÙNG NGÀY của buổi (bỏ trống new_date để giữ ngày) "
            "và new_time phải TRƯỚC 22:00 — sau 22:00 bị từ chối. "
            "Chỉ cho phép nếu buổi đó chưa hoàn thành và tuần đó chưa có buổi nào Completed/InProgress.",
            _obj({
                "session_id": {"type": "string"},
                "new_date": {"type": "string", "description": "Bỏ trống = giữ ngày hiện tại của buổi (khuyến nghị)"},
                "new_time": {"type": "string", "description": "HH:MM, phải TRƯỚC 22:00"},
            }, ["session_id", "new_date"]),
            frozenset({"workout"}), "write",
        ),
        "generate_week_plan": ToolDef(
            "generate_week_plan",
            "Alias của plan_or_edit_workout (horizon=week). Sinh lịch 1 tuần — PHẢI xác nhận.",
            _obj({
                "roadmap_id": {"type": "string"},
                "week_start_date": {"type": "string", "description": "ISO-8601 YYYY-MM-DD ngày đầu tuần (Monday)"},
                "reason": {"type": "string"},
            }, ["roadmap_id", "week_start_date"]),
            frozenset({"workout"}), "write",
        ),
        "plan_or_edit_workout": ToolDef(
            "plan_or_edit_workout",
            "Tạo HOẶC chỉnh lịch tập theo horizon linh hoạt (today/week/rest_of_week/next_n_days/range) "
            "hoặc slot cụ thể (vd tối nay + tối mai). 'Từ hôm nay đến hết tuần' → rest_of_week. "
            "User nói 'k buổi/ngày' → sessions_per_day=k. Luôn gửi full context (mục tiêu, sinh trắc, "
            "recovery, execution+set logs 7 ngày). PHẢI xác nhận trước khi lưu.",
            _obj({
                "horizon": {
                    "type": "string",
                    "description": (
                        "today|week|rest_of_week|next_n_days|range|slots. "
                        "rest_of_week = hôm nay → Chủ Nhật tuần NÀY (dùng cho 'đến hết tuần')"
                    ),
                },
                "days": {"type": "integer", "description": "Cho next_n_days (mặc định 7)"},
                "sessions_per_day": {
                    "type": "integer",
                    "description": "Số buổi MỖI ngày (mặc định 1; 'tập 2 buổi/ngày' → 2, tối đa 3)",
                },
                "from_date": {"type": "string", "description": "ISO-8601 YYYY-MM-DD"},
                "to_date": {"type": "string", "description": "ISO-8601 YYYY-MM-DD"},
                "week_start_date": {"type": "string", "description": "ISO-8601 Monday (horizon=week)"},
                "target_slots": {
                    "type": "array",
                    "description": "Slot cụ thể [{date,time_of_day|time}]",
                    "items": {
                        "type": "object",
                        "properties": {
                            "date": {"type": "string"},
                            "time_of_day": {"type": "string", "description": "sang|trua|chieu|toi"},
                            "time": {"type": "string", "description": "HH:MM"},
                        },
                    },
                },
                "edit_intent": {"type": "string", "description": "Mô tả chỉnh sửa (mode=edit)"},
                "session_id": {"type": "string", "description": "Sửa đúng 1 buổi"},
                "roadmap_id": {"type": "string"},
                "reason": {"type": "string"},
                "mode": {"type": "string", "description": "create|edit"},
            }),
            frozenset({"workout"}), "write",
        ),
        "update_roadmap": ToolDef(
            "update_roadmap", "Cập nhật phase/flags/mục tiêu roadmap AI.",
            _obj({
                "roadmap_id": {"type": "string"},
                "current_phase": {"type": "string"},
                "allow_ai_reschedule": {"type": "boolean"},
                "allow_ai_intensity_adjustment": {"type": "boolean"},
                "allow_ai_recovery_deload": {"type": "boolean"},
                "target_weight_kg": {"type": "number"},
                "current_weight_kg": {"type": "number"},
            }, ["roadmap_id"]),
            frozenset({"workout"}), "write",
        ),
        "schedule_roadmap_session": ToolDef(
            "schedule_roadmap_session", "Lên lịch buổi tập mới trong roadmap AI.",
            _obj({
                "roadmap_id": {"type": "string"},
                "scheduled_date": {"type": "string", "description": "ISO-8601"},
                "scheduled_time": {"type": "string"},
                "session_title": {"type": "string"},
                "session_type": {"type": "string"},
                "estimated_duration_minutes": {"type": "integer"},
                "execution_blocks": {
                    "type": "array",
                    "items": {"type": "object"},
                },
            }, ["roadmap_id", "scheduled_date", "session_title", "execution_blocks"]),
            frozenset({"workout"}), "write",
        ),
        "request_replan": ToolDef(
            "request_replan", "Yêu cầu lên lại lịch tập.",
            _obj({"reason": {"type": "string"}}, ["reason"]),
            frozenset({"workout"}), "write",
        ),
        "adjust_intensity": ToolDef(
            "adjust_intensity", "Điều chỉnh cường độ buổi tập.",
            _obj({
                "session_id": {"type": "string"},
                "factor": {"type": "number", "description": "0.5-1.5"},
            }, ["session_id", "factor"]),
            frozenset({"workout"}), "write",
        ),
        "search_exercises": ToolDef(
            "search_exercises", "Tìm bài tập theo cơ/nhóm/dụng cụ.",
            _obj({
                "query": {"type": "string"}, "muscle": {"type": "string"},
                "equipment": {"type": "string"}, "difficulty": {"type": "string"},
                "limit": {"type": "integer"},
            }),
            frozenset({"workout"}),
        ),
        "get_exercise_detail": ToolDef(
            "get_exercise_detail",
            "Chi tiết ExerciseCatalog (cues, lỗi thường gặp, contraindications, cơ bám). "
            "Truyền exercise_id nếu đã biết, hoặc query/slug tên bài (vd 'push up', 'bench press', 'push-up').",
            _obj({
                "exercise_id": {"type": "string", "description": "GUID bài tập (ưu tiên nếu có)"},
                "query": {"type": "string", "description": "Tên bài tập EN/VI để tra catalog"},
                "slug": {"type": "string", "description": "Slug catalog, vd push-up"},
            }),
            frozenset({"workout"}),
        ),
        "get_exercise_media": ToolDef(
            "get_exercise_media", "Link video/Unity demo bài tập.",
            _obj({
                "exercise_id": {"type": "string"},
                "asset_type": {"type": "string"},
            }, ["exercise_id"]),
            frozenset({"workout"}),
        ),
        "substitute_exercise": ToolDef(
            "substitute_exercise", "Đổi bài tập trong buổi.",
            _obj({
                "session_id": {"type": "string"},
                "exercise_id": {"type": "string"},
                "reason": {"type": "string"},
            }, ["session_id", "exercise_id"]),
            frozenset({"workout"}), "write",
        ),
        "log_workout_execution": ToolDef(
            "log_workout_execution", "Ghi hoàn thành buổi tập.",
            _obj({
                "session_id": {"type": "string"},
                "duration_min": {"type": "integer"},
                "perceived_difficulty": {"type": "string"},
                "energy_before": {"type": "integer"},
                "energy_after": {"type": "integer"},
            }, ["session_id"]),
            frozenset({"workout"}), "write",
        ),
        "log_set": ToolDef(
            "log_set", "Ghi 1 set tập.",
            _obj({
                "execution_id": {"type": "string"},
                "exercise_id": {"type": "string"},
                "set_number": {"type": "integer"},
                "actual_reps": {"type": "integer"},
                "weight_kg": {"type": "number"},
                "rir": {"type": "integer"},
            }, ["execution_id", "exercise_id", "set_number"]),
            frozenset({"workout"}), "write",
        ),
        "get_recovery_status": ToolDef(
            "get_recovery_status", "Trạng thái phục hồi / mệt mỏi.",
            empty, frozenset({"workout", "insight"}),
        ),
        "get_daily_summary": ToolDef(
            "get_daily_summary", "Tổng hợp dinh dưỡng hôm nay (calo, macro).",
            _obj({"date": {"type": "string", "description": "YYYY-MM-DD"}}),
            frozenset({"nutrition", "insight"}),
        ),
        "get_nutrition_targets": ToolDef(
            "get_nutrition_targets", "Mục tiêu calo/macro từ hồ sơ.",
            empty, frozenset({"nutrition"}),
        ),
        "search_food": ToolDef(
            "search_food", "Tìm món/thực phẩm trong catalog.",
            _obj({"query": {"type": "string"}, "limit": {"type": "integer"}}),
            frozenset({"nutrition"}),
        ),
        "get_food_by_barcode": ToolDef(
            "get_food_by_barcode", "Tra cứu thực phẩm theo mã vạch.",
            _obj({"barcode": {"type": "string"}}, ["barcode"]),
            frozenset({"nutrition"}),
        ),
        "log_meal": ToolDef(
            "log_meal", "Ghi nhật ký bữa ăn.",
            _obj({
                "meal_type": {"type": "string"},
                "items": {"type": "array", "items": {"type": "object"}},
                "notes": {"type": "string"},
                "photo_url": {"type": "string"},
            }, ["meal_type", "items"]),
            frozenset({"nutrition"}), "write",
        ),
        "log_water": ToolDef(
            "log_water", "Ghi lượng nước uống (ml).",
            _obj({"amount_ml": {"type": "integer"}}, ["amount_ml"]),
            frozenset({"nutrition"}), "write",
        ),
        "suggest_meal_plan": ToolDef(
            "suggest_meal_plan", "Gợi ý thực đơn theo mục tiêu calo.",
            _obj({
                "target_calories": {"type": "integer"},
                "meals_per_day": {"type": "integer"},
            }),
            frozenset({"nutrition"}),
        ),
        "estimate_meal_from_photo": ToolDef(
            "estimate_meal_from_photo", "Ước lượng bữa ăn từ ảnh (cần VISION_ENABLED).",
            _obj({"image_url": {"type": "string"}}, ["image_url"]),
            frozenset({"nutrition"}),
        ),
        "check_wallet": ToolDef(
            "check_wallet", "Số dư ví và hạn mức.",
            empty, frozenset({"commerce"}),
        ),
        "recommend_partner_meals": ToolDef(
            "recommend_partner_meals",
            "Gợi ý món đối tác Sync theo mục tiêu & ngân sách (chỉ Marketplace, không bịa).",
            _obj({"goal": {"type": "string"}, "max_price": {"type": "number"}}),
            frozenset({"commerce"}),
        ),
        "search_partners": ToolDef(
            "search_partners",
            "Tìm quán/đối tác theo từ khoá (có thể kèm lat/lng để gần).",
            _obj({
                "lat": {"type": "number"}, "lng": {"type": "number"},
                "partner_type": {"type": "string"}, "query": {"type": "string"},
                "dish": {"type": "string"}, "min_rating": {"type": "number"},
                "radius_km": {"type": "number"}, "limit": {"type": "integer"},
            }),
            frozenset({"commerce"}),
        ),
        "search_nearby_partners": ToolDef(
            "search_nearby_partners",
            "Tìm quán GẦN theo vị trí + món/từ khoá + rating. "
            "Nếu chưa có lat/lng, tool tự xin quyền vị trí.",
            _obj({
                "lat": {"type": "number"}, "lng": {"type": "number"},
                "query": {"type": "string"}, "dish": {"type": "string"},
                "min_rating": {"type": "number"}, "radius_km": {"type": "number"},
                "limit": {"type": "integer"},
            }),
            frozenset({"commerce"}),
        ),
        "search_partner_dishes": ToolDef(
            "search_partner_dishes",
            "Tìm món theo tên/query/rating trên toàn app. "
            "KHÔNG truyền lat/lng trừ khi user hỏi gần. "
            "use_location=true chỉ khi có ý địa lý.",
            _obj({
                "query": {"type": "string"},
                "partner_id": {"type": "string"},
                "lat": {"type": "number"}, "lng": {"type": "number"},
                "radius_km": {"type": "number"},
                "min_rating": {"type": "number"},
                "limit": {"type": "integer"},
                "use_location": {"type": "boolean"},
            }),
            frozenset({"commerce"}),
        ),
        "get_partner_detail": ToolDef(
            "get_partner_detail",
            "Chi tiết quán: địa chỉ, giờ mở, cover, rating, menu.",
            _obj({
                "partner_id": {"type": "string"},
                "lat": {"type": "number"}, "lng": {"type": "number"},
            }, ["partner_id"]),
            frozenset({"commerce"}),
        ),
        "get_food_detail": ToolDef(
            "get_food_detail",
            "Chi tiết món: mô tả, giá, macro/calo, dietaryTags, spice, rating. "
            "Truyền food_menu_item_id = foodId từ dish_list.",
            _obj({"food_menu_item_id": {"type": "string"}}, ["food_menu_item_id"]),
            frozenset({"commerce", "nutrition"}),
        ),
        "get_partner_reviews": ToolDef(
            "get_partner_reviews",
            "Review của quán (rating, comment, ảnh, partnerReply).",
            _obj({
                "partner_id": {"type": "string"},
                "limit": {"type": "integer"},
            }, ["partner_id"]),
            frozenset({"commerce"}),
        ),
        "get_food_reviews": ToolDef(
            "get_food_reviews",
            "Review của món ăn.",
            _obj({
                "food_menu_item_id": {"type": "string"},
                "limit": {"type": "integer"},
            }, ["food_menu_item_id"]),
            frozenset({"commerce"}),
        ),
        "evaluate_food_fit": ToolDef(
            "evaluate_food_fit",
            "Đánh giá món có hợp dinh dưỡng không: macro món + meal logs ~7 ngày + target/sinh trắc. "
            "Truyền food_menu_item_id (foodId từ dish_list), KHÔNG search bằng tên.",
            _obj({
                "food_menu_item_id": {"type": "string"},
                "days": {"type": "integer", "description": "Số ngày meal log (mặc định 7)"},
            }, ["food_menu_item_id"]),
            frozenset({"commerce", "nutrition"}),
        ),
        "request_user_location": ToolDef(
            "request_user_location",
            "Xin quyền vị trí khi user hỏi quán gần mà chưa có lat/lng. Gửi box request_location_permission.",
            _obj({"reason": {"type": "string"}}),
            frozenset({"commerce"}),
        ),
        "get_menu": ToolDef(
            "get_menu", "Menu của đối tác.",
            _obj({"partner_id": {"type": "string"}}, ["partner_id"]),
            frozenset({"commerce"}),
        ),
        "recommend_affiliate_products": ToolDef(
            "recommend_affiliate_products", "Sản phẩm affiliate theo danh mục.",
            _obj({"category": {"type": "string"}}),
            frozenset({"commerce"}),
        ),
        "list_vouchers": ToolDef(
            "list_vouchers", "Voucher khả dụng của user.",
            empty, frozenset({"commerce"}),
        ),
        "get_default_contact": ToolDef(
            "get_default_contact",
            "Lấy contact mặc định để đặt đơn: họ tên, SĐT (IAM) + địa chỉ giao (Order).",
            empty, frozenset({"commerce"}),
        ),
        "get_payment_status": ToolDef(
            "get_payment_status",
            "Đọc trạng thái thanh toán theo order_id hoặc payos_order_code (không tự đánh dấu đã trả).",
            _obj({
                "order_id": {"type": "string"},
                "payos_order_code": {"type": "integer"},
            }),
            frozenset({"commerce"}),
        ),
        "pay_with_wallet": ToolDef(
            "pay_with_wallet",
            "Thanh toán đơn bằng ví — LUÔN cần xác nhận. Kiểm tra số dư trước.",
            _obj({"order_id": {"type": "string"}}, ["order_id"]),
            frozenset({"commerce"}), "financial",
        ),
        "create_payment_link": ToolDef(
            "create_payment_link",
            "Tạo link/QR VietQR (PayOS) cho đơn chưa thanh toán — LUÔN cần xác nhận.",
            _obj({
                "order_id": {"type": "string"},
                "method": {"type": "string"},
            }, ["order_id"]),
            frozenset({"commerce"}), "financial",
        ),
        "track_order": ToolDef(
            "track_order", "Theo dõi đơn hàng.",
            _obj({"order_id": {"type": "string"}}, ["order_id"]),
            frozenset({"commerce"}),
        ),
        "apply_voucher": ToolDef(
            "apply_voucher",
            "Không tự áp voucher độc lập — truyền voucher_code vào propose_order để quote.",
            _obj({
                "order_draft_id": {"type": "string"},
                "voucher_code": {"type": "string"},
            }, ["voucher_code"]),
            frozenset({"commerce"}), "financial",
        ),
        "reorder": ToolDef(
            "reorder", "Đặt lại đơn trước (LUÔN cần xác nhận).",
            _obj({"previous_order_id": {"type": "string"}}, ["previous_order_id"]),
            frozenset({"commerce"}), "financial",
        ),
        "topup_wallet": ToolDef(
            "topup_wallet", "Nạp ví (LUÔN cần xác nhận).",
            _obj({"amount": {"type": "number"}, "method": {"type": "string"}}, ["amount"]),
            frozenset({"commerce"}), "financial",
        ),
        "get_gamification_status": ToolDef(
            "get_gamification_status", "Streak, XP, level, SyncCoins.",
            empty, frozenset({"coach", "insight"}),
        ),
        "suggest_next_achievement": ToolDef(
            "suggest_next_achievement", "Thành tựu gần đạt nhất.",
            empty, frozenset({"coach"}),
        ),
        "log_mood_checkin": ToolDef(
            "log_mood_checkin", "Ghi tâm trạng hiện tại.",
            _obj({"mood": {"type": "string"}, "note": {"type": "string"}}, ["mood"]),
            frozenset({"coach"}), "write",
        ),
        "get_community_highlights": ToolDef(
            "get_community_highlights", "Challenge/feed nổi bật cộng đồng.",
            empty, frozenset({"coach"}),
        ),
        "remember_user_fact": ToolDef(
            "remember_user_fact", "Ghi sở thích/fact dài hạn về user.",
            _obj({"fact": {"type": "string"}}, ["fact"]),
            frozenset({"coach", "nutrition", "workout", "commerce"}), "write",
        ),
        "recall_user_memory": ToolDef(
            "recall_user_memory", "Truy hồi facts liên quan.",
            _obj({"query": {"type": "string"}, "k": {"type": "integer"}}, ["query"]),
            frozenset({"coach", "nutrition", "workout", "commerce"}),
        ),
        "send_notification": ToolDef(
            "send_notification", "Gửi thông báo chủ động tới app.",
            _obj({
                "title": {"type": "string"}, "body": {"type": "string"},
                "deep_link": {"type": "string"},
            }, ["title", "body"]),
            frozenset({"coach", "insight"}), "write",
        ),
        "handoff": ToolDef(
            "handoff",
            "Chỉ bàn giao khi user RÕ ràng hỏi miền khác (vd đang nutrition mà hỏi lịch tập). "
            "Chọn đích: workout=lịch tập/lộ trình/bài tập; nutrition=log bữa/calo-macro cá nhân; "
            "commerce=TÌM/MUA/ĐẶT món thật, quán, giỏ hàng, ví/thanh toán; "
            "insight=THỐNG KÊ đa kỳ (n ngày/tuần/tháng), biểu đồ, xu hướng, dự đoán, báo cáo; "
            "coach=trò chuyện/động viên/FAQ chung. "
            "Cấm handoff cùng agent; cấm nhảy workout chỉ vì nhắc 'tập'. "
            "Câu dinh dưỡng/calo/macro/log bữa → ở lại nutrition; "
            "nhưng 'thống kê dinh dưỡng 2 tuần' → insight, 'tìm/mua món' → commerce.",
            _obj({
                "target_agent": {
                    "type": "string",
                    "enum": ["coach", "nutrition", "workout", "commerce", "insight"],
                },
                "reason": {"type": "string"},
            }, ["target_agent"]),
            frozenset({"coach", "nutrition", "workout", "commerce", "insight"}), "control",
        ),
        "escalate_to_human": ToolDef(
            "escalate_to_human", "Escalate khủng hoảng sức khỏe tâm thần.",
            _obj({
                "reason": {"type": "string"},
                "severity": {"type": "string"},
            }, ["reason"]),
            frozenset({"coach"}), "safety",
        ),
        "web_search": ToolDef(
            "web_search",
            "Tìm kiếm web để xác minh thông tin chính xác cao (nghiên cứu, số liệu, tư vấn y tế cần kiểm chứng). "
            "CHỈ dùng cho Coach khi câu hỏi cần độ chính xác cao và KB nội bộ không đủ.",
            _obj({
                "query": {"type": "string"},
                "max_results": {"type": "integer"},
            }, ["query"]),
            frozenset({"coach"}),
        ),
        "get_progress_trends": ToolDef(
            "get_progress_trends", "Xu hướng metric N ngày.",
            _obj({"metric": {"type": "string"}, "days": {"type": "integer"}}),
            frozenset({"insight"}),
        ),
        "detect_burnout": ToolDef(
            "detect_burnout", "Đánh giá nguy cơ burnout.",
            empty, frozenset({"insight"}),
        ),
        "detect_plateau": ToolDef(
            "detect_plateau", "Phát hiện chững tiến độ.",
            _obj({"metric": {"type": "string"}}),
            frozenset({"insight"}),
        ),
        "generate_weekly_report": ToolDef(
            "generate_weekly_report", "Báo cáo tuần đa nguồn.",
            empty, frozenset({"insight"}),
        ),
        "compute_and_update_ai_scores": ToolDef(
            "compute_and_update_ai_scores", "Tính & ghi điểm AI về IAM.",
            empty, frozenset({"insight"}), "write",
        ),
        "get_nutrition_stats": ToolDef(
            "get_nutrition_stats",
            "Thống kê dinh dưỡng đa kỳ + biểu đồ (Premium). period vd 14d/8w/3m.",
            _obj({
                "period": {"type": "string"},
                "granularity": {"type": "string"},
            }),
            frozenset({"insight"}),
        ),
        "evaluate_nutrition_adequacy": ToolDef(
            "evaluate_nutrition_adequacy",
            "Nhận định mức dinh dưỡng có ổn không + confidence (Premium).",
            _obj({"period": {"type": "string"}}),
            frozenset({"insight"}),
        ),
        "get_workout_stats": ToolDef(
            "get_workout_stats",
            "Thống kê tập luyện đa kỳ + biểu đồ completion/volume (Premium).",
            _obj({
                "period": {"type": "string"},
                "granularity": {"type": "string"},
                "exercise_id": {"type": "string"},
            }),
            frozenset({"insight"}),
        ),
        "get_body_progress": ToolDef(
            "get_body_progress",
            "Tiến độ cân/mỡ ước lượng từ cân bằng năng lượng (Premium).",
            _obj({"period": {"type": "string"}}),
            frozenset({"insight"}),
        ),
        "predict_outcome": ToolDef(
            "predict_outcome",
            "Dự đoán ETA mục tiêu cân + verdict dinh dưỡng đa nguồn (Premium).",
            _obj({"period": {"type": "string"}}),
            frozenset({"insight"}),
        ),
        "build_insight_dashboard": ToolDef(
            "build_insight_dashboard",
            "Gộp nhiều biểu đồ nutrition/workout/body thành insight_dashboard (Premium).",
            _obj({
                "period": {"type": "string"},
                "focus": {"type": "string"},
            }),
            frozenset({"insight"}),
        ),
    }


TOOL_REGISTRY = _registry()

AGENT_TOOLS: dict[str, list[str]] = {
    "coach": [
        "get_gamification_status", "suggest_next_achievement", "log_mood_checkin",
        "get_community_highlights", "remember_user_fact", "recall_user_memory",
        "send_notification", "handoff", "escalate_to_human", "web_search",
    ],
    "nutrition": [
        "get_daily_summary", "get_nutrition_targets", "search_food", "get_food_by_barcode",
        "log_meal", "log_water", "suggest_meal_plan", "estimate_meal_from_photo",
        "evaluate_food_fit", "get_food_detail",
        "remember_user_fact", "recall_user_memory", "handoff",
    ],
    "workout": [
        "get_active_roadmap", "get_roadmap_sessions", "get_workout_schedule", "get_workout_history",
        "create_roadmap", "delete_roadmap", "update_roadmap", "schedule_roadmap_session",
        "reschedule_session", "generate_week_plan", "plan_or_edit_workout",
        "get_today_workout", "request_replan", "adjust_intensity", "search_exercises",
        "get_exercise_detail", "get_exercise_media", "substitute_exercise",
        "log_workout_execution", "log_set", "get_recovery_status",
        "remember_user_fact", "recall_user_memory", "handoff",
    ],
    "commerce": [
        "check_wallet", "recommend_partner_meals", "search_partners",
        "search_nearby_partners", "search_partner_dishes", "get_partner_detail", "get_food_detail",
        "get_partner_reviews", "get_food_reviews", "evaluate_food_fit", "request_user_location",
        "get_menu", "get_default_contact", "get_payment_status",
        "pay_with_wallet", "create_payment_link",
        "recommend_affiliate_products", "list_vouchers", "track_order",
        "apply_voucher", "reorder", "topup_wallet",
        "remember_user_fact", "recall_user_memory", "handoff",
    ],
    "insight": [
        "get_daily_summary", "get_today_workout", "get_progress_trends", "detect_burnout",
        "detect_plateau", "generate_weekly_report", "compute_and_update_ai_scores",
        "get_nutrition_stats", "evaluate_nutrition_adequacy", "get_workout_stats",
        "get_body_progress", "predict_outcome", "build_insight_dashboard",
        "get_gamification_status", "get_recovery_status", "send_notification", "handoff",
    ],
}


def tools_for_agent(agent: str) -> list[str]:
    from app.config import get_settings

    names = list(AGENT_TOOLS.get(agent, []))
    if not get_settings().vision_enabled and "estimate_meal_from_photo" in names:
        names.remove("estimate_meal_from_photo")
    return names


def tool_schemas(names: list[str]) -> list[dict[str, Any]]:
    specs = []
    for n in names:
        d = TOOL_REGISTRY.get(n)
        if not d:
            continue
        specs.append({
            "type": "function",
            "function": {
                "name": d.name,
                "description": d.description,
                "parameters": d.parameters,
            },
        })
    return specs


def _wrap(ctx: ToolRunContext, name: str, fn: ToolFn) -> ToolFn:
    async def _inner(**kwargs: Any) -> dict[str, Any]:
        ctx.tools_called.append(name)
        result = await safe_tool_call(fn, **kwargs)
        ctx.tool_calls_log.append({"tool": name, "args": kwargs, "result": result})
        return result

    return _inner


def build_impls(ctx: ToolRunContext, names: list[str]) -> dict[str, ToolFn]:
    uid = ctx.user_id

    async def _send_notification(title: str = "", body: str = "", deep_link: str = "", **_: Any):
        return await dotnet.send_notification(uid, {
            "type": "AiIntervention", "channel": "InApp", "priority": "Normal",
            "title": title, "body": body, "deepLink": deep_link or None,
            "allowAiGenerated": True,
        })

    async def _log_meal(meal_type: str, items: list | None = None, notes: str = "",
                        photo_url: str = "", **_: Any):
        payload = {
            "mealType": meal_type,
            "items": items or [],
            "notes": notes or None,
            "photoUrl": photo_url or None,
            "source": "AiSuggested",
        }
        # log_meal is a write action — require confirmation
        action_id = str(uuid.uuid4())
        meal_summary = ", ".join(
            f"{item.get('name', '?')} {item.get('grams', '')}g"
            for item in (items or [])
        )
        ctx.pending_actions.append({
            "action_id": action_id,
            "type": "log_meal",
            "payload": payload,
            "status": "awaiting_confirmation",
            "summary": f"Log bữa {meal_type}: {meal_summary or 'xem chi tiết'}",
        })
        return {
            "status": "pending_confirmation",
            "action_id": action_id,
            "message": f"Mình sẽ log bữa {meal_type}. Bạn xác nhận không?",
            "summary": ctx.pending_actions[-1]["summary"],
        }

    async def _log_workout_execution(session_id: str, duration_min: int = 0,
                                     perceived_difficulty: str = "", energy_before: int = 0,
                                     energy_after: int = 0, **_: Any):
        return await dotnet.log_workout_execution(uid, {
            "sessionId": session_id,
            "durationMinutes": duration_min,
            "perceivedDifficulty": perceived_difficulty,
            "energyLevelBefore": energy_before,
            "energyLevelAfter": energy_after,
        })

    async def _log_set(execution_id: str, exercise_id: str, set_number: int,
                       actual_reps: int = 0, weight_kg: float = 0, rir: int | None = None, **_: Any):
        body: dict[str, Any] = {
            "workoutExecutionId": execution_id,
            "exerciseId": exercise_id,
            "setNumber": set_number,
            "actualReps": actual_reps,
            "weightKg": weight_kg,
        }
        if rir is not None:
            body["rir"] = rir
        return await dotnet.log_set(uid, body)

    async def _get_workout_schedule(from_date: str = "", to_date: str = "", **_: Any):
        from datetime import datetime as _dt

        from app.tools.time_utils import local_today, resolve_tz_name

        tz = resolve_tz_name(ctx.state)
        today = local_today(ctx.state).isoformat()
        fd = from_date or today
        td = to_date or fd
        try:
            result = await dotnet.get_sessions_by_range(
                uid, from_iso=fd, to_iso=td, time_zone_id=tz,
            )
            if isinstance(result, dict) and result.get("error"):
                raise RuntimeError(result["error"])
            return result
        except Exception:
            try:
                roadmap = await dotnet.get_active_roadmap(uid)
                roadmap_id = roadmap.get("id", "")
                if not roadmap_id:
                    return {"items": [], "message": "Không tìm thấy roadmap active."}
                all_sessions = await dotnet.get_roadmap_sessions(uid, roadmap_id)
                items = all_sessions.get("items", all_sessions if isinstance(all_sessions, list) else [])
                fd_dt = _dt.fromisoformat(fd + "T00:00:00") if "T" not in fd else _dt.fromisoformat(fd)
                td_dt = _dt.fromisoformat(td + "T23:59:59") if "T" not in td else _dt.fromisoformat(td)
                filtered = [s for s in items if isinstance(s, dict) and s.get("scheduledDate") and
                            fd_dt.isoformat()[:10] <= str(s["scheduledDate"])[:10] <= td_dt.isoformat()[:10]]
                return {"items": filtered, "date_range": f"{fd} to {td}", "timezone": tz}
            except Exception as exc2:
                return {"error": str(exc2), "items": []}

    async def _get_workout_history(from_date: str = "", to_date: str = "", **_: Any):
        from datetime import timedelta

        from app.tools.time_utils import local_today, resolve_tz_name

        tz = resolve_tz_name(ctx.state)
        today = local_today(ctx.state)
        fd = from_date or (today - timedelta(days=7)).isoformat()
        td = to_date or today.isoformat()
        return await dotnet.get_workout_history(
            uid, from_iso=fd, to_iso=td, time_zone_id=tz,
        )

    async def _create_roadmap(
        roadmap_name: str = "",
        fitness_goal: str = "Maintain",
        current_phase: str = "Foundation",
        start_date: str = "",
        current_weight_kg: float | None = None,
        target_weight_kg: float | None = None,
        initial_fat_percentage: float | None = None,
        target_fat_percentage: float | None = None,
        **_: Any,
    ):
        from app.tools.time_utils import local_today

        payload: dict[str, Any] = {
            "roadmapName": roadmap_name,
            "fitnessGoal": fitness_goal,
            "currentPhase": current_phase,
            "startDate": start_date or local_today(ctx.state).isoformat(),
            "adaptiveAiEnabled": True,
            "allowAiReschedule": True,
            "allowAiIntensityAdjustment": True,
            "allowAiRecoveryDeload": True,
            "roadmapStatus": "Active",
        }
        snapshot = ctx.state.get("user_snapshot", {})
        if current_weight_kg is not None:
            payload["currentWeightKg"] = current_weight_kg
        elif snapshot.get("currentWeightKg"):
            payload["currentWeightKg"] = snapshot["currentWeightKg"]
        else:
            payload["currentWeightKg"] = 70.0
        if target_weight_kg is not None:
            payload["targetWeightKg"] = target_weight_kg
        elif snapshot.get("targetWeightKg"):
            payload["targetWeightKg"] = snapshot["targetWeightKg"]
        else:
            payload["targetWeightKg"] = payload["currentWeightKg"]
        payload["initialFatPercentage"] = initial_fat_percentage or 20.0
        payload["targetFatPercentage"] = target_fat_percentage or 15.0
        # Append to pending_actions — confirm before executing
        import uuid as _uuid
        action_id = str(_uuid.uuid4())
        ctx.pending_actions.append({
            "action_id": action_id,
            "type": "create_roadmap",
            "payload": payload,
            "status": "awaiting_confirmation",
            "summary": f"Tạo lộ trình '{roadmap_name}' ({fitness_goal}) bắt đầu từ {payload['startDate']}",
        })
        return {
            "status": "pending_confirmation",
            "action_id": action_id,
            "message": "Mình đã chuẩn bị lộ trình. Bạn xác nhận để tạo nhé?",
            "summary": ctx.pending_actions[-1]["summary"],
        }

    async def _delete_roadmap(roadmap_id: str = "", **_: Any):
        import uuid as _uuid
        action_id = str(_uuid.uuid4())
        ctx.pending_actions.append({
            "action_id": action_id,
            "type": "delete_roadmap",
            "roadmap_id": roadmap_id,
            "status": "awaiting_confirmation",
            "summary": f"Xoá roadmap {roadmap_id} và toàn bộ lịch tập liên quan",
        })
        return {
            "status": "pending_confirmation",
            "action_id": action_id,
            "message": "Bạn chắc chắn muốn xoá lộ trình này? Thao tác không thể hoàn tác.",
        }

    async def _reschedule_session(session_id: str = "", new_date: str = "", new_time: str = "07:00", **_: Any):
        import uuid as _uuid

        from app.tools.local import validate_time_change

        if not session_id:
            return {"error": "Thiếu session_id — đọc lịch (get_workout_schedule) để lấy id buổi cần đổi."}

        # Luật đổi lịch qua AI: chỉ đổi GIỜ trong cùng ngày, và giờ mới < 22:00.
        # Đọc session thật để biết ngày hiện tại — không tin ngày do LLM đoán.
        current_date = ""
        try:
            session = await dotnet.get_roadmap_session(uid, session_id)
            current_date = str(
                session.get("scheduledDate") or session.get("ScheduledDate") or ""
            )[:10]
        except Exception:
            pass  # không đọc được → vẫn validate giờ; ngày sẽ được chốt lại lúc confirm

        if not new_date and current_date:
            new_date = current_date
        err = validate_time_change(
            current_date=current_date, new_date=new_date, new_time=new_time,
        )
        if err:
            return {"error": err}

        action_id = str(_uuid.uuid4())
        ctx.pending_actions.append({
            "action_id": action_id,
            "type": "reschedule_session",
            "session_id": session_id,
            "new_date": new_date,
            "new_time": new_time,
            "status": "awaiting_confirmation",
            "summary": f"Đổi giờ buổi tập ngày {new_date} sang {new_time}",
        })
        return {
            "status": "pending_confirmation",
            "action_id": action_id,
            "message": f"Mình sẽ đổi buổi tập sang {new_date} lúc {new_time}. Bạn xác nhận không?",
        }

    async def _generate_week_plan(
        roadmap_id: str = "",
        week_start_date: str = "",
        reason: str = "",
        **_: Any,
    ):
        return await local.generate_week_plan(
            ctx, roadmap_id=roadmap_id, week_start_date=week_start_date, reason=reason,
        )

    async def _plan_or_edit_workout(
        horizon: str = "week",
        days: int = 7,
        from_date: str = "",
        to_date: str = "",
        week_start_date: str = "",
        target_slots: list | None = None,
        sessions_per_day: int = 1,
        edit_intent: str = "",
        session_id: str = "",
        roadmap_id: str = "",
        reason: str = "",
        mode: str = "",
        **_: Any,
    ):
        return await local.plan_or_edit_workout(
            ctx,
            horizon=horizon,
            days=int(days or 7),
            from_date=from_date,
            to_date=to_date,
            week_start_date=week_start_date,
            target_slots=target_slots or [],
            sessions_per_day=int(sessions_per_day or 1),
            edit_intent=edit_intent,
            session_id=session_id,
            roadmap_id=roadmap_id,
            reason=reason,
            mode=mode,
        )

    def _emit_exercise_media_card(detail_or_media: Any, *, exercise_name: str = "") -> None:
        """Prefer card display_payload over markdown images in chat text."""
        if not isinstance(detail_or_media, dict) or detail_or_media.get("error"):
            return
        name = (
            exercise_name
            or detail_or_media.get("nameEn")
            or detail_or_media.get("NameEn")
            or detail_or_media.get("nameVi")
            or detail_or_media.get("NameVi")
            or detail_or_media.get("name")
            or detail_or_media.get("exerciseName")
            or "Bài tập"
        )
        images: list[str] = []
        for key in ("imageUrls", "ImageUrls", "mediaUrls", "MediaUrls", "urls", "Urls"):
            raw = detail_or_media.get(key)
            if isinstance(raw, list):
                for u in raw:
                    if isinstance(u, str) and u.strip():
                        images.append(u.strip())
                    elif isinstance(u, dict):
                        url = u.get("url") or u.get("Url") or u.get("imageUrl") or u.get("ImageUrl")
                        if url:
                            images.append(str(url).strip())
        items = detail_or_media.get("items") or detail_or_media.get("Items") or []
        if isinstance(items, list):
            for it in items:
                if isinstance(it, dict):
                    url = it.get("url") or it.get("Url") or it.get("imageUrl") or it.get("ImageUrl")
                    if url:
                        images.append(str(url).strip())
                elif isinstance(it, str) and it.strip():
                    images.append(it.strip())
        # Dedupe preserve order
        seen: set[str] = set()
        uniq = []
        for u in images:
            if u not in seen:
                seen.add(u)
                uniq.append(u)
        if not uniq:
            return
        # Dedupe same exercise card in one turn
        for p in (*ctx.display_payload, *(ctx.state.get("display_payload") or [])):
            if isinstance(p, dict) and p.get("type") == "exercise_media" and p.get("exerciseName") == name:
                return
        ctx.display_payload.append({
            "type": "exercise_media",
            "exerciseName": str(name),
            "images": uniq[:8],
        })

    async def _get_exercise_detail(
        exercise_id: str = "",
        query: str = "",
        slug: str = "",
        **_: Any,
    ):
        if exercise_id:
            detail = await dotnet.get_exercise_detail(uid, exercise_id)
        elif query or slug:
            detail = await dotnet.lookup_exercise_detail(uid, query=query, slug=slug)
        else:
            return {"error": "Thiếu exercise_id hoặc query/slug tên bài tập"}
        _emit_exercise_media_card(detail)
        return detail

    async def _get_exercise_media(
        exercise_id: str = "",
        asset_type: str = "",
        **_: Any,
    ):
        if not exercise_id:
            return {"error": "Thiếu exercise_id"}
        media = await dotnet.get_exercise_media(uid, exercise_id, asset_type)
        name = ""
        try:
            detail = await dotnet.get_exercise_detail(uid, exercise_id)
            if isinstance(detail, dict):
                name = str(
                    detail.get("nameEn")
                    or detail.get("NameEn")
                    or detail.get("nameVi")
                    or detail.get("name")
                    or ""
                )
        except Exception:
            pass
        _emit_exercise_media_card(media, exercise_name=name)
        return media

    def _state_lat_lng() -> tuple[float | None, float | None]:
        snap = ctx.state or {}
        lat = snap.get("user_latitude")
        lng = snap.get("user_longitude")
        try:
            return (
                float(lat) if lat is not None else None,
                float(lng) if lng is not None else None,
            )
        except (TypeError, ValueError):
            return None, None

    def _unwrap_items(result: Any) -> list:
        if isinstance(result, list):
            return result
        if not isinstance(result, dict):
            return []
        for key in ("items", "data", "results"):
            val = result.get(key)
            if isinstance(val, list):
                return val
        return []

    async def _request_user_location(reason: str = "", **_: Any):
        msg = reason or "Cho phép truy cập vị trí để tìm quán gần bạn"
        existing = (*(ctx.state.get("display_payload") or []), *ctx.display_payload)
        if any(
            isinstance(p, dict) and p.get("type") == "request_location_permission"
            for p in existing
        ):
            return {
                "status": "location_required",
                "message": msg,
                "note": "Đã xin quyền vị trí trong lượt này — chờ client gửi lat/lng.",
                "deduped": True,
            }
        ctx.display_payload.append({
            "type": "request_location_permission",
            "reason": msg,
        })
        return {
            "status": "location_required",
            "message": msg,
            "note": "Chờ client gửi lại tin nhắn kèm latitude/longitude.",
        }

    def _first_image(raw: dict[str, Any]) -> str | None:
        urls = raw.get("imageUrls") or raw.get("ImageUrls") or []
        if isinstance(urls, list) and urls:
            return str(urls[0])
        for key in (
            "imageUrl", "ImageUrl", "coverImageUrl", "CoverImageUrl",
            "logoUrl", "LogoUrl", "thumbnailUrl", "ThumbnailUrl",
        ):
            val = raw.get(key)
            if val:
                return str(val)
        return None

    def _normalize_dish_card(raw: Any) -> dict[str, Any] | None:
        if not isinstance(raw, dict):
            return None
        fid = raw.get("id") or raw.get("Id") or raw.get("foodId") or raw.get("FoodId")
        out = dict(raw)
        if fid is not None:
            out["foodId"] = str(fid)
            out.setdefault("id", str(fid))
        partner_name = (
            raw.get("partnerName")
            or raw.get("PartnerName")
            or raw.get("partner_name")
            or raw.get("kitchenName")
            or raw.get("KitchenName")
        )
        if partner_name:
            out["partnerName"] = str(partner_name)
        partner_id = raw.get("partnerId") or raw.get("PartnerId")
        if partner_id is not None:
            out["partnerId"] = str(partner_id)
        # Prefer Vietnamese/English dish name — never use partnerName as the title.
        name_vi = raw.get("nameVi") or raw.get("NameVi")
        name_en = raw.get("nameEn") or raw.get("NameEn")
        name = raw.get("name") or raw.get("Name")
        if name_vi:
            out["nameVi"] = str(name_vi)
        if name_en:
            out["nameEn"] = str(name_en)
        if name and not name_vi:
            out["name"] = str(name)
        img = _first_image(raw)
        if img:
            out["imageUrl"] = img
        out["source"] = "sync"
        return out

    def _emit_dish_list(items: list[dict[str, Any]], *, empty_query: str = "") -> dict[str, Any]:
        if items:
            ctx.display_payload.append({"type": "dish_list", "items": items[:20], "source": "sync"})
            return {"items": items[:20], "source": "sync", "count": len(items)}
        msg = (
            "Hiện Sync/đối tác chưa có món khớp trên Marketplace. "
            "Mình không bịa món ngoài Sync — thử từ khoá khác hoặc đổi mục tiêu."
        )
        if empty_query:
            msg = (
                f"Hiện Sync/đối tác chưa có món khớp «{empty_query}». "
                "Mình không bịa món ngoài Sync — thử từ khoá khác nhé."
            )
        return {"items": [], "source": "sync", "count": 0, "message": msg, "empty": True}

    def _normalize_partner_card(raw: Any) -> dict[str, Any] | None:
        if not isinstance(raw, dict):
            return None
        pid = raw.get("id") or raw.get("Id") or raw.get("partnerId") or raw.get("PartnerId")
        out = dict(raw)
        if pid is not None:
            out["partnerId"] = str(pid)
            out.setdefault("id", str(pid))
        img = _first_image(raw)
        if img:
            out["imageUrl"] = img
        return out

    async def _search_partners(
        lat=None, lng=None, partner_type="", query="", dish="",
        min_rating=None, radius_km=None, limit=10, **_: Any,
    ):
        state_lat, state_lng = _state_lat_lng()
        use_lat = lat if lat is not None else state_lat
        use_lng = lng if lng is not None else state_lng
        result = await dotnet.search_partners(
            uid,
            lat=use_lat,
            lng=use_lng,
            partner_type=partner_type or "",
            query=query or "",
            dish=dish or "",
            min_rating=float(min_rating) if min_rating is not None else None,
            radius_km=float(radius_km) if radius_km is not None else None,
            limit=int(limit or 10),
        )
        items = [
            c for c in (_normalize_partner_card(i) for i in _unwrap_items(result)) if c
        ]
        if items:
            ctx.display_payload.append({"type": "partner_list", "items": items[:15]})
        return result

    async def _search_nearby_partners(
        lat=None, lng=None, query="", dish="",
        min_rating=None, radius_km=5, limit=10, **_: Any,
    ):
        state_lat, state_lng = _state_lat_lng()
        use_lat = lat if lat is not None else state_lat
        use_lng = lng if lng is not None else state_lng
        if use_lat is None or use_lng is None:
            return await _request_user_location(
                "Cho phép truy cập vị trí để tìm quán gần bạn",
            )
        result = await dotnet.search_nearby_partners(
            uid,
            lat=float(use_lat),
            lng=float(use_lng),
            query=query or "",
            dish=dish or "",
            min_rating=float(min_rating) if min_rating is not None else None,
            radius_km=float(radius_km or 5),
            limit=int(limit or 10),
        )
        items = [
            c for c in (_normalize_partner_card(i) for i in _unwrap_items(result)) if c
        ]
        if items:
            ctx.display_payload.append({"type": "partner_list", "items": items[:15]})
        return result

    async def _search_partner_dishes(
        query="", partner_id="", lat=None, lng=None,
        radius_km=None, min_rating=None, limit=20, use_location=False, **_: Any,
    ):
        # Default: app-wide dish search — do NOT inject state lat/lng unless
        # the model explicitly passes lat/lng or use_location=true (geo intent).
        use_lat = lat
        use_lng = lng
        if use_location and (use_lat is None or use_lng is None):
            state_lat, state_lng = _state_lat_lng()
            use_lat = use_lat if use_lat is not None else state_lat
            use_lng = use_lng if use_lng is not None else state_lng
        result = await dotnet.search_partner_dishes(
            uid,
            query=query or "",
            partner_id=partner_id or "",
            lat=float(use_lat) if use_lat is not None else None,
            lng=float(use_lng) if use_lng is not None else None,
            radius_km=float(radius_km) if radius_km is not None else None,
            min_rating=float(min_rating) if min_rating is not None else None,
            limit=int(limit or 20),
        )
        items = [
            c for c in (_normalize_dish_card(i) for i in _unwrap_items(result)) if c
        ]
        empty_payload = _emit_dish_list(items, empty_query=query or "")
        if isinstance(result, dict):
            return {**result, **empty_payload}
        return empty_payload

    async def _recommend_partner_meals(goal="GeneralHealth", max_price=150000, **_: Any):
        result = await dotnet.recommend_partner_meals(
            uid, goal=goal, max_price=float(max_price),
        )
        items = [
            c for c in (_normalize_dish_card(i) for i in _unwrap_items(result)) if c
        ]
        empty_payload = _emit_dish_list(items, empty_query=str(goal or ""))
        if isinstance(result, dict):
            return {**result, **empty_payload}
        if isinstance(result, list):
            return {**empty_payload}
        return empty_payload

    async def _get_partner_detail(partner_id="", lat=None, lng=None, **_: Any):
        state_lat, state_lng = _state_lat_lng()
        use_lat = lat if lat is not None else state_lat
        use_lng = lng if lng is not None else state_lng
        result = await dotnet.get_partner_detail(
            uid, partner_id, lat=use_lat, lng=use_lng,
        )
        if isinstance(result, dict) and not result.get("error") and (
            result.get("id") or result.get("Id") or result.get("name") or result.get("Name")
        ):
            card = _normalize_partner_card(result) or result
            ctx.display_payload.append({"type": "partner_detail", "data": card})
        return result

    async def _get_food_detail(food_menu_item_id="", **_: Any):
        result = await dotnet.get_food_detail(uid, food_menu_item_id)
        if isinstance(result, dict) and not result.get("error") and (
            result.get("id") or result.get("Id") or result.get("nameVi") or result.get("NameVi")
        ):
            card = _normalize_dish_card(result) or result
            ctx.display_payload.append({"type": "food_detail", "data": card})
        return result

    async def _get_partner_reviews(partner_id="", limit=20, **_: Any):
        result = await dotnet.get_partner_reviews(uid, partner_id, limit=int(limit or 20))
        items = _unwrap_items(result)
        if items:
            ctx.display_payload.append({
                "type": "review_list", "targetType": "Partner",
                "targetId": partner_id, "items": items[:20],
            })
        return result

    async def _get_food_reviews(food_menu_item_id="", limit=20, **_: Any):
        result = await dotnet.get_food_reviews(uid, food_menu_item_id, limit=int(limit or 20))
        items = _unwrap_items(result)
        if items:
            ctx.display_payload.append({
                "type": "review_list", "targetType": "FoodMenuItem",
                "targetId": food_menu_item_id, "items": items[:20],
            })
        return result

    async def _get_menu(partner_id="", **_: Any):
        result = await dotnet.get_menu(uid, partner_id)
        items = [
            c for c in (_normalize_dish_card(i) for i in _unwrap_items(result)) if c
        ]
        if items:
            ctx.display_payload.append({
                "type": "menu_list", "partnerId": partner_id, "items": items[:30], "source": "sync",
            })
        return result if isinstance(result, dict) else {"items": items, "source": "sync"}

    async def _pending_money(
        action_type: str,
        *,
        amount: float = 0,
        summary: str = "",
        **extra: Any,
    ) -> dict[str, Any]:
        action_id = str(uuid.uuid4())
        action = {
            "action_id": action_id,
            "type": action_type,
            "idempotency_key": action_id,
            "amount": float(amount),
            "summary": summary,
            "status": "awaiting_confirmation",
            **extra,
        }
        ctx.pending_actions.append(action)
        return {
            "status": "pending_confirmation",
            "action_id": action_id,
            "message": "Cần bạn xác nhận trên app trước khi thực hiện giao dịch.",
            "summary": summary,
            "amount": float(amount),
        }

    async def _pay_with_wallet(order_id: str = "", **_: Any):
        if not order_id:
            return {"error": "Thiếu order_id"}
        order = await dotnet.get_order(uid, order_id)
        amount = float(order.get("totalAmount") or order.get("TotalAmount") or 0)
        wallet = await dotnet.check_wallet(uid)
        coins = float(wallet.get("coinBalance") or wallet.get("availableBalance") or 0)
        vnd_per = float(wallet.get("vndPerCoin") or 100)
        balance_vnd = coins * vnd_per
        if amount > 0 and balance_vnd < amount:
            return {
                "status": "insufficient_balance",
                "order_id": order_id,
                "amount": amount,
                "balance_vnd": balance_vnd,
                "message": "Số dư ví không đủ. Hãy nạp ví hoặc chọn VietQR.",
            }
        return await _pending_money(
            "pay_with_wallet",
            amount=amount,
            summary=f"Thanh toán ví đơn {order_id}: {amount:,.0f}đ",
            order_id=order_id,
        )

    async def _create_payment_link(order_id: str = "", method: str = "vietqr", **_: Any):
        if not order_id:
            return {"error": "Thiếu order_id"}
        order = await dotnet.get_order(uid, order_id)
        amount = float(order.get("totalAmount") or order.get("TotalAmount") or 0)
        order_code = order.get("orderCode") or order.get("OrderCode") or ""
        return await _pending_money(
            "create_payment_link",
            amount=amount,
            summary=f"Tạo VietQR đơn {order_code or order_id}: {amount:,.0f}đ",
            order_id=order_id,
            order_code=order_code,
            method=method or "vietqr",
        )

    async def _reorder_pending(previous_order_id: str = "", **_: Any):
        if not previous_order_id:
            return {"error": "Thiếu previous_order_id"}
        return await _pending_money(
            "reorder",
            summary=f"Đặt lại đơn {previous_order_id}",
            previous_order_id=previous_order_id,
        )

    async def _topup_pending(amount: float = 0, method: str = "VietQR", **_: Any):
        if float(amount) <= 0:
            return {"error": "Số tiền nạp phải > 0"}
        return await _pending_money(
            "topup_wallet",
            amount=float(amount),
            summary=f"Nạp ví {float(amount):,.0f}đ qua {method or 'VietQR'}",
            method=method or "VietQR",
        )

    async def _apply_voucher_blocked(order_draft_id: str = "", voucher_code: str = "", **_: Any):
        return {
            "status": "use_propose_order",
            "message": (
                "Không áp voucher độc lập. Truyền voucher_code vào propose_order "
                "để quote tổng tiền thật rồi xác nhận đặt đơn."
            ),
            "voucher_code": voucher_code,
            "order_draft_id": order_draft_id,
        }

    from app.tools.time_utils import local_today, resolve_tz_name

    _user_tz = resolve_tz_name(ctx.state)

    registry: dict[str, ToolFn] = {
        "get_today_workout": lambda **_: dotnet.get_today_workout(uid, time_zone_id=_user_tz),
        "get_active_roadmap": lambda **_: dotnet.get_active_roadmap(uid),
        "get_roadmap_sessions": lambda roadmap_id="", **_: dotnet.get_roadmap_sessions(uid, roadmap_id),
        "get_workout_schedule": _get_workout_schedule,
        "get_workout_history": _get_workout_history,
        "create_roadmap": _create_roadmap,
        "delete_roadmap": _delete_roadmap,
        "reschedule_session": _reschedule_session,
        "generate_week_plan": _generate_week_plan,
        "plan_or_edit_workout": _plan_or_edit_workout,
        "update_roadmap": lambda roadmap_id="", current_phase="", allow_ai_reschedule=None,
                              allow_ai_intensity_adjustment=None, allow_ai_recovery_deload=None,
                              target_weight_kg=None, current_weight_kg=None, **_: dotnet.update_roadmap(
            uid,
            roadmap_id,
            {
                k: v for k, v in {
                    "currentPhase": current_phase or None,
                    "allowAiReschedule": allow_ai_reschedule,
                    "allowAiIntensityAdjustment": allow_ai_intensity_adjustment,
                    "allowAiRecoveryDeload": allow_ai_recovery_deload,
                    "targetWeightKg": target_weight_kg,
                    "currentWeightKg": current_weight_kg,
                }.items() if v is not None
            },
        ),
        "schedule_roadmap_session": lambda roadmap_id="", scheduled_date="", scheduled_time="07:00",
                                        session_title="", session_type="Strength",
                                        estimated_duration_minutes=45, execution_blocks=None, **kw:
            dotnet.schedule_roadmap_session(uid, {
                "roadmapId": roadmap_id,
                "scheduledDate": scheduled_date,
                "scheduledTime": scheduled_time,
                "timezone": kw.get("timezone") or _user_tz,
                "sessionTitle": session_title,
                "sessionType": session_type,
                "estimatedDurationMinutes": int(estimated_duration_minutes or 45),
                "notificationEnabled": True,
                "executionBlocks": execution_blocks or [],
            }),
        "request_replan": lambda reason="user_request", **_: dotnet.request_replan(uid, reason),
        "adjust_intensity": lambda session_id="", factor=1.0, **_: dotnet.adjust_intensity(
            uid, session_id, float(factor)),
        "search_exercises": lambda query="", muscle="", equipment="", difficulty="",
                              limit=5, **_: dotnet.search_exercises(
            uid, query=query, muscle=muscle, equipment=equipment, difficulty=difficulty, limit=limit),
        "get_exercise_detail": _get_exercise_detail,
        "get_exercise_media": _get_exercise_media,
        "substitute_exercise": lambda session_id="", exercise_id="", reason="", **_:
            dotnet.substitute_exercise(uid, session_id, exercise_id, reason),
        "log_workout_execution": _log_workout_execution,
        "log_set": _log_set,
        "get_recovery_status": lambda **_: dotnet.get_recovery_status(uid),
        "get_daily_summary": lambda date=None, **_: dotnet.get_daily_summary(
            uid, date=date or local_today(ctx.state).isoformat(), time_zone_id=_user_tz,
        ),
        "get_nutrition_targets": lambda **_: dotnet.get_nutrition_targets(uid),
        "search_food": lambda query="", limit=10, **_: dotnet.search_food(uid, query=query, limit=limit),
        "get_food_by_barcode": lambda barcode="", **_: dotnet.get_food_by_barcode(uid, barcode),
        "log_meal": _log_meal,
        "log_water": lambda amount_ml=0, **_: dotnet.log_water(uid, int(amount_ml)),
        "suggest_meal_plan": lambda target_calories=None, meals_per_day=3, **_:
            local.suggest_meal_plan(ctx, target_calories, meals_per_day),
        "estimate_meal_from_photo": lambda image_url="", **_:
            local.estimate_meal_from_photo(ctx, image_url),
        "check_wallet": lambda **_: dotnet.check_wallet(uid),
        "recommend_partner_meals": _recommend_partner_meals,
        "search_partners": _search_partners,
        "search_nearby_partners": _search_nearby_partners,
        "search_partner_dishes": _search_partner_dishes,
        "get_partner_detail": _get_partner_detail,
        "get_food_detail": _get_food_detail,
        "get_partner_reviews": _get_partner_reviews,
        "get_food_reviews": _get_food_reviews,
        "evaluate_food_fit": lambda food_menu_item_id="", days=7, **_:
            local.evaluate_food_fit(ctx, food_menu_item_id=food_menu_item_id, days=int(days or 7)),
        "request_user_location": _request_user_location,
        "get_menu": _get_menu,
        "get_default_contact": lambda **_: dotnet.get_default_contact(uid),
        "get_payment_status": lambda order_id="", payos_order_code=None, **_:
            dotnet.get_payment_status(
                uid,
                order_id=order_id or "",
                payos_order_code=int(payos_order_code) if payos_order_code is not None else None,
            ),
        "pay_with_wallet": _pay_with_wallet,
        "create_payment_link": _create_payment_link,
        "recommend_affiliate_products": lambda category="", **_:
            dotnet.recommend_affiliate_products(uid, category),
        "list_vouchers": lambda **_: dotnet.list_vouchers(uid),
        "track_order": lambda order_id="", **_: dotnet.track_order(uid, order_id),
        "apply_voucher": _apply_voucher_blocked,
        "reorder": _reorder_pending,
        "topup_wallet": _topup_pending,
        "get_gamification_status": lambda **_: dotnet.get_gamification_status(uid),
        "suggest_next_achievement": lambda **_: dotnet.suggest_next_achievement(uid),
        "log_mood_checkin": lambda mood="", note="", **_: local.log_mood_checkin(ctx, mood, note),
        "get_community_highlights": lambda **_: dotnet.get_community_highlights(uid),
        "remember_user_fact": lambda fact="", **_: local.remember_user_fact(ctx, fact),
        "recall_user_memory": lambda query="", k=5, **_: local.recall_user_memory(ctx, query, k=k),
        "send_notification": _send_notification,
        "handoff": lambda target_agent="", reason="", **_: local.handoff(ctx, target_agent, reason),
        "escalate_to_human": lambda reason="", severity="high", **_:
            local.escalate_to_human(ctx, reason, severity),
        "get_progress_trends": lambda metric="calories", days=7, **_:
            local.get_progress_trends(ctx, metric=metric, days=int(days)),
        "detect_burnout": lambda **_: local.detect_burnout(ctx),
        "detect_plateau": lambda metric="weight", **_: local.detect_plateau(ctx, metric=metric),
        "generate_weekly_report": lambda **_: local.generate_weekly_report(ctx),
        "compute_and_update_ai_scores": lambda **_: local.compute_and_update_ai_scores(ctx),
        "get_nutrition_stats": lambda period="14d", granularity="day", **_:
            _insight.get_nutrition_stats(ctx, period=period, granularity=granularity),
        "evaluate_nutrition_adequacy": lambda period="14d", **_:
            _insight.evaluate_nutrition_adequacy(ctx, period=period),
        "get_workout_stats": lambda period="14d", granularity="week", exercise_id="", **_:
            _insight.get_workout_stats(
                ctx, period=period, granularity=granularity, exercise_id=exercise_id,
            ),
        "get_body_progress": lambda period="8w", **_:
            _insight.get_body_progress(ctx, period=period),
        "predict_outcome": lambda period="8w", **_:
            _insight.predict_outcome(ctx, period=period),
        "build_insight_dashboard": lambda period="8w", focus="all", **_:
            _insight.build_insight_dashboard(ctx, period=period, focus=focus),
        "web_search": lambda query="", max_results=5, **_: _ws.web_search(query, max_results=int(max_results)),
    }

    return {n: _wrap(ctx, n, registry[n]) for n in names if n in registry}


# Back-compat for older agent imports
def tool_impls(user_id: str, names: list[str], state: dict[str, Any] | None = None) -> dict[str, ToolFn]:
    ctx = ToolRunContext(user_id=user_id, state=state or {})
    return build_impls(ctx, names)
