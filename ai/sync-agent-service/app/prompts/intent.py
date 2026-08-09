"""Prompt phân loại intent — LLM JSON schema (gpt-4o-mini)."""
from __future__ import annotations

INTENT_PROMPT_VERSION = "intent-v1.8.0"

AGENT_CATALOG: dict[str, str] = {
    "coach": "Trò chuyện chung, động viên, FAQ fitness chung — không gắn bài tập/lộ trình cụ thể.",
    "nutrition": (
        "Dinh dưỡng cá nhân: calo/macro mục tiêu, log bữa ăn, nước, cân nặng — "
        "KHÔNG phải tìm quán/menu/mua món (→commerce), "
        "KHÔNG phải thống kê nhiều tuần/tháng hay biểu đồ (→insight)."
    ),
    "workout": (
        "Tập luyện & lộ trình AI: tạo/xoá/sửa PersonalizedRoadmap, lịch tập ngày/tuần, "
        "bài tập cụ thể, kỹ thuật/form, chấn thương, set/rep, replan, phục hồi. "
        "Mọi câu 'tạo lộ trình', 'theo dõi bởi Cyn', 'AI Roadmap' → workout."
    ),
    "commerce": (
        "1. Mua sắm & ví: đặt món, giỏ hàng/thêm vào giỏ, ví, đơn hàng, thanh toán. "
        "2. Tư vấn quán/món đối tác: tìm quán gần, menu, chi tiết món (giá/calo từ tool), "
        "review quán/món, rating. "
        "3. Tìm MÓN ĂN THẬT trên nền tảng ('tìm món phù hợp mục tiêu', 'có bán X không')."
    ),
    "insight": (
        "Phân tích tiến độ & thống kê ĐA KỲ: thống kê dinh dưỡng/tập luyện n ngày·tuần·tháng, "
        "biểu đồ, xu hướng, dự đoán, đánh giá 'mức này có ổn không', báo cáo tuần, burnout, plateau."
    ),
}

_AGENT_LIST_TEXT = "\n".join(f"- {k}: {v}" for k, v in AGENT_CATALOG.items())

_SYSTEM = f"""Bạn là intent router của trợ lý sức khoẻ SYNC (VN).
Đọc tin nhắn, hiểu ý định, chọn ĐÚNG MỘT agent.

Agents:
{_AGENT_LIST_TEXT}

Quy tắc:
- Hiểu tiếng Việt có/không dấu, lóng, code-switch EN.
- Phân loại theo Ý ĐỊNH, không chỉ từ khoá.
- Tạo / bắt đầu / muốn có LỘ TRÌNH (roadmap, AI Roadmap, theo dõi bởi Cyn) → workout, KHÔNG coach.
  Nhắc tên Cyn trong câu tạo lộ trình vẫn là workout (Cyn = coach tập, không phải trò chuyện xã giao).
- Hỏi về BÀI TẬP CỤ THỂ (tên bài, kỹ thuật, form, có phù hợp với mình không) → workout, KHÔNG coach.
- FAQ chung không gắn bài tập cụ thể (protein là gì, creatine, stress) → coach.
- Quán ăn / nhà hàng / menu đối tác / review quán·món / tìm quán gần / giá món trên app → commerce.
  (Khác nutrition: nutrition = log/mục tiêu calo cá nhân, không phải tìm quán.)
- TÌM/MUA MÓN THẬT: "tìm món ăn phù hợp", "có bán X không", "thêm vào giỏ/cart", đặt món → commerce,
  KHÔNG nutrition (nutrition không được bịa món generic).
- THỐNG KÊ/BIỂU ĐỒ/XU HƯỚNG/DỰ ĐOÁN theo nhiều ngày·tuần·tháng (kể cả về dinh dưỡng
  hay tập luyện) → insight, KHÔNG nutrition/workout. "thống kê dinh dưỡng 2 tuần" = insight.
- Mơ hồ/xã giao → coach.
- complexity: simple | standard | complex.
- language: vi | en.
- confidence: 0.0-1.0.
- reason ≤12 từ.
- Trả về DUY NHẤT một object JSON với các khóa: agent, language, complexity, confidence, reason."""

_FEWSHOT: list[tuple[str, str]] = [
    ("Tôi muốn tạo lộ trình theo dõi bởi Cyn!",
     '{"agent":"workout","language":"vi","complexity":"standard","confidence":0.97,"reason":"tạo lộ trình AI"}'),
    ("tao lo trinh tap giup minh voi",
     '{"agent":"workout","language":"vi","complexity":"standard","confidence":0.95,"reason":"tạo lộ trình tập"}'),
    ("hom nay tap bai gi vay",
     '{"agent":"workout","language":"vi","complexity":"standard","confidence":0.93,"reason":"lịch tập hôm nay"}'),
    ("Bài bench press có phù hợp với mình không?",
     '{"agent":"workout","language":"vi","complexity":"standard","confidence":0.94,"reason":"bài tập cụ thể"}'),
    ("Kỹ thuật push up như thế nào?",
     '{"agent":"workout","language":"vi","complexity":"standard","confidence":0.95,"reason":"kỹ thuật bài tập"}'),
    ("hôm nay mình nên ăn bao nhiêu protein?",
     '{"agent":"nutrition","language":"vi","complexity":"standard","confidence":0.95,"reason":"hỏi lượng đạm"}'),
    ("đặt giùm tui suất cơm gà ức nha",
     '{"agent":"commerce","language":"vi","complexity":"standard","confidence":0.96,"reason":"đặt món ăn"}'),
    ("quán ăn gần đây có gì ngon?",
     '{"agent":"commerce","language":"vi","complexity":"standard","confidence":0.95,"reason":"tìm quán gần"}'),
    ("quán nào bán bún bò gần tôi rating trên 4 sao",
     '{"agent":"commerce","language":"vi","complexity":"standard","confidence":0.96,"reason":"tìm quán theo món"}'),
    ("cho mình xem review quán X với",
     '{"agent":"commerce","language":"vi","complexity":"standard","confidence":0.94,"reason":"review quán"}'),
    ("món này bao nhiêu calo và giá?",
     '{"agent":"commerce","language":"vi","complexity":"standard","confidence":0.9,"reason":"chi tiết món đối tác"}'),
    ("thống kê dinh dưỡng 2 tuần gần đây của tôi nhé",
     '{"agent":"insight","language":"vi","complexity":"standard","confidence":0.95,"reason":"thống kê đa kỳ"}'),
    ("tiến độ tập luyện tháng này của mình thế nào?",
     '{"agent":"insight","language":"vi","complexity":"standard","confidence":0.94,"reason":"xu hướng tiến độ"}'),
    ("tìm món ăn phù hợp với dinh dưỡng và mục tiêu của tôi đi",
     '{"agent":"commerce","language":"vi","complexity":"standard","confidence":0.92,"reason":"tìm món thật trên Sync"}'),
    ("trên nền tảng này có bán cơm ức gà rau củ không",
     '{"agent":"commerce","language":"vi","complexity":"standard","confidence":0.94,"reason":"hỏi món có bán"}'),
    ("thêm món đó vào cart giúp mình",
     '{"agent":"commerce","language":"vi","complexity":"standard","confidence":0.95,"reason":"thêm giỏ hàng"}'),
    ("dinh dưỡng mấy ngày nay của tôi thế nào rồi",
     '{"agent":"insight","language":"vi","complexity":"standard","confidence":0.93,"reason":"đánh giá dinh dưỡng đa kỳ"}'),
    ("tuần này mình ăn uống ra sao",
     '{"agent":"insight","language":"vi","complexity":"standard","confidence":0.92,"reason":"đánh giá ăn uống theo tuần"}'),
    ("nhận xét chế độ ăn của tôi đi",
     '{"agent":"insight","language":"vi","complexity":"standard","confidence":0.9,"reason":"nhận xét dinh dưỡng"}'),
    ("sáng nay mình cân được 92kg",
     '{"agent":"nutrition","language":"vi","complexity":"standard","confidence":0.93,"reason":"báo cân nặng mới"}'),
    ("mình xuống còn 78.5kg rồi nè",
     '{"agent":"nutrition","language":"vi","complexity":"standard","confidence":0.92,"reason":"báo cân nặng mới"}'),
]


def build_intent_messages(user_text: str, recent_context: str | None = None) -> list[dict[str, str]]:
    messages: list[dict[str, str]] = [{"role": "system", "content": _SYSTEM}]
    for u, a in _FEWSHOT:
        messages.append({"role": "user", "content": u})
        messages.append({"role": "assistant", "content": a})
    ctx = f"(Bối cảnh gần đây: {recent_context})\n" if recent_context else ""
    messages.append({"role": "user", "content": f"{ctx}{user_text}"})
    return messages
