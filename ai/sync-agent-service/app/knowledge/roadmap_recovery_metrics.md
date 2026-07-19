# Roadmap & Recovery Metrics — SYNC AI Knowledge Base

## RecoveryProfile

RecoveryProfile lưu trạng thái phục hồi sinh lý hiện tại của người dùng, cập nhật theo từng buổi tập.

| Trường | Kiểu | Mô tả |
|---|---|---|
| **CurrentRecoveryScore** | 0–100 | Điểm phục hồi tổng thể. ≥75 = sẵn sàng tập nặng, 50–75 = tập vừa, <50 = cần nghỉ hoặc tập nhẹ. |
| **FatigueLevel** | 1–10 | Mệt mỏi chủ quan tổng quát (1=rất tươi, 10=kiệt sức). >7 nên giảm cường độ. |
| **MuscleSorenessScore** | 1–10 | Đau nhức cơ (DOMS). >6 = tránh tập nhóm cơ đó ngay hôm sau. |
| **CnsFatigueScore** | 1–10 | Mệt hệ thần kinh trung ương (CNS). >6 = giảm volume, tránh lift nặng. |
| **RecommendedTrainingIntensity** | Low/Moderate/High | Cường độ AI khuyến nghị dựa trên tổng hợp các điểm trên. |
| **RecommendedWorkoutDuration** | phút | Thời lượng tập tối ưu hôm nay theo tình trạng phục hồi. |

### Đọc chỉ số phục hồi
- **Tốt (≥75, Fatigue ≤4, Soreness ≤4)**: Có thể tập nặng, volume cao, compound movement.
- **Trung bình (50–74, Fatigue 5–6, Soreness 5–6)**: Tập vừa phải, tránh PR cá nhân, giảm volume ~20%.
- **Kém (<50, Fatigue ≥7, Soreness ≥7)**: Tập nhẹ (yoga/stretching/đi bộ) hoặc nghỉ hoàn toàn.
- **CNS ≥7**: Đặc biệt tránh Deadlift, Squat tối đa — dù cơ bắp không đau.

---

## PersonalizedRoadmap

PersonalizedRoadmap là lộ trình tập luyện dài hạn do AI thiết kế, gắn với mục tiêu cụ thể.

| Trường | Mô tả |
|---|---|
| **RoadmapName** | Tên lộ trình (vd: "Giảm mỡ 3 tháng"). |
| **FitnessGoal** | Mục tiêu: LoseFat / BuildMuscle / Maintain / ImproveEndurance. |
| **CurrentPhase** | Giai đoạn hiện tại: Foundation / Hypertrophy / Strength / Deload / Peak. |
| **StartDate / ExpectedEndDate** | Ngày bắt đầu và ngày dự kiến kết thúc. |
| **CurrentWeightKg / TargetWeightKg** | Cân nặng hiện tại và mục tiêu. |
| **InitialFatPercentage / TargetFatPercentage** | % mỡ cơ thể ban đầu và mục tiêu. |
| **RoadmapStatus** | Active / Paused / Completed / Cancelled. |
| **AdaptiveAiEnabled** | AI được phép tự điều chỉnh lộ trình (cường độ, volume). |
| **AllowAiReschedule** | AI được phép đổi lịch buổi tập. |
| **AllowAiIntensityAdjustment** | AI được phép điều chỉnh cường độ (weight/reps). |
| **AllowAiRecoveryDeload** | AI được phép thêm tuần deload khi phục hồi kém. |

### Các giai đoạn tập (Phase)
- **Foundation**: Xây nền tảng, học kỹ thuật, cường độ thấp-vừa (4–8 tuần đầu).
- **Hypertrophy**: Tăng cơ, volume cao, rep 8–15 (thường 8–12 tuần).
- **Strength**: Tăng sức mạnh, rep thấp (3–6), weight nặng (4–8 tuần).
- **Deload**: Tuần giảm tải (<50% volume thường lệ) để phục hồi CNS.
- **Peak**: Chuẩn bị thi đấu/kiểm tra, volume giảm, intensity cao.

---

## TDEE & Macro Targets

| Trường (từ BiometricProfile/AIContextDto) | Mô tả |
|---|---|
| **BaseTDEE** | Total Daily Energy Expenditure — tổng calo tiêu thụ trong ngày theo mức độ hoạt động (kcal). |
| **DailyProteinTargetGram** | Mục tiêu protein mỗi ngày (g). Thường 1.6–2.2g/kg cân nặng. |
| **DailyCarbTargetGram** | Mục tiêu carbohydrate mỗi ngày (g). |
| **DailyFatTargetGram** | Mục tiêu chất béo mỗi ngày (g). |

### Công thức nhanh
- Giảm mỡ: ăn thấp hơn TDEE 300–500 kcal/ngày, protein cao (2g/kg).
- Tăng cơ: ăn trên TDEE 200–300 kcal/ngày, protein 1.8–2.2g/kg.
- Duy trì: ăn bằng TDEE, protein 1.6g/kg.

---

## Quy tắc AI Coach khi dùng các thông số này

1. **Trước khi đề xuất cường độ tập**: luôn đọc RecoveryProfile — nếu CurrentRecoveryScore <50 hoặc FatigueLevel ≥7, giảm cường độ và thời lượng.
2. **Trước khi đề xuất bài tập**: kiểm tra injuries (BiometricProfile.Injuries) — tránh bài tập ảnh hưởng vùng chấn thương.
3. **Xác nhận trước khi write**: create_roadmap, delete_roadmap, reschedule_session, generate_week_plan đều phải qua pending_action + xác nhận user.
4. **Tuân thủ AllowAiReschedule**: nếu false, không được đổi lịch dù user yêu cầu — báo user chỉnh trong cài đặt.
