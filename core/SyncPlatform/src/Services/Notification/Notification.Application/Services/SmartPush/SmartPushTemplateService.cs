using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Services.SmartPush;

public class SmartPushTemplateService : ISmartPushTemplateService
{
    private record Template(string Title, string Body);

    private static readonly Dictionary<string, List<Template>> Templates = new(StringComparer.OrdinalIgnoreCase)
    {
        ["TodayWorkoutReminder"] =
        [
            new("Đến giờ vận động rồi", "Buổi '{TodayWorkoutName}' lúc {ScheduledLocalTime} chưa xong. 15–20 phút cũng rất đáng 💪"),
            new("Sẵn sàng tập chưa?", "{WorkoutSourceHint}'{TodayWorkoutName}' đang chờ bạn hôm nay.")
        ],
        ["StreakProtection"] =
        [
            new("Giữ chuỗi nào 🔥", "Bạn đang có chuỗi {CurrentStreak} ngày. Một buổi ngắn hôm nay cũng giữ được đà."),
            new("Đừng để mất đà", "Streak {CurrentStreak} ngày rồi — tập nhẹ cũng được!")
        ],
        ["MissedWorkouts"] =
        [
            new("Quay lại nhịp tập nhé", "Bạn vừa bỏ {MissedRecentCount} buổi gần đây. Bắt đầu lại bằng buổi ngắn thôi."),
            new("Mình vẫn ở đây", "Lỡ nhịp không sao — hôm nay tập nhẹ là đủ để lấy lại guồng.")
        ],
        ["BurnoutRecovery"] =
        [
            new("Tập nhẹ thôi nhé 💚", "Hôm nay nên nghỉ nhẹ / chỉ 10–15 phút vận động nhẹ."),
            new("Nghe cơ thể một chút", "Burnout hơi cao — ưu tiên phục hồi và ngủ đủ nhé.")
        ],
        ["NutritionNudge"] =
        [
            new("Nhắc nhẹ dinh dưỡng", "Hôm nay mới log {MealsLoggedToday} bữa, còn ~{RemainingCaloriesPct}% calo mục tiêu."),
            new("Uống nước và ăn đủ nhé", "Nước ~{WaterPct}% mục tiêu — nhớ bổ sung bữa nhẹ giàu đạm.")
        ],
        ["ChurnReengage"] =
        [
            new("Nhớ bạn quá!", "Lâu rồi chưa ghé SYNC. Mở app 1 phút chọn buổi nhẹ nhé."),
            new("Quay lại cùng CYN", "Không cần buổi nặng — chỉ cần bắt đầu lại.")
        ],
        ["ProgressCelebrate"] =
        [
            new("Giỏi lắm! 🎉", "Hôm nay bạn đã tiến bộ rõ — giữ nhịp này nhé."),
            new("Một ngày đáng tự hào", "Hoàn thành mục tiêu hôm nay rồi. Tự thưởng xứng đáng!")
        ],
        ["GentleCheckIn"] =
        [
            new("Dạo này thế nào?", "CYN gửi lời hỏi thăm — hôm nay bạn muốn tập hay nghỉ nhẹ?"),
            new("Check-in nhẹ", "Không áp lực — chỉ muốn biết bạn ổn chứ?")
        ],
        ["WeighInReminder"] =
        [
            new("Nhắc cân nặng", "Đã hơn 1 tuần chưa cập nhật cân. Cân nhanh giúp CYN tinh chỉnh mục tiêu nhé."),
            new("Weigh-in thôi!", "Lịch sử cân trống / quá cũ — mở app log cân để Adaptive Coach theo dõi tiến độ.")
        ],
        // Backward-compatible aliases
        ["ScheduledWorkoutReminder"] =
        [
            new("Đến giờ vận động rồi", "Hôm nay có {TodayWorkoutName}. Bắt đầu nhẹ cũng được nhé 💪")
        ],
        ["FinishWorkoutReminder"] =
        [
            new("Tiếp nốt chút nhé", "Bạn đã hoàn thành {CompletionRate}%. Quay lại thêm một chút 🔥")
        ],
        ["StreakProtectionReminder"] =
        [
            new("Giữ chuỗi nào 🔥", "Chuỗi {CurrentStreak} ngày — tập nhẹ hôm nay cũng được.")
        ],
        ["RecoveryGentleReminder"] =
        [
            new("Tập nhẹ thôi nhé 💚", "Hôm nay chỉ cần 10–15 phút vận động nhẹ.")
        ]
    };

    public GeneratedPushMessageDto BuildMessage(SmartPushContextDto context, SmartPushDecision decision, string deepLink)
    {
        var triggerType = string.IsNullOrWhiteSpace(decision.TriggerType) ? "TodayWorkoutReminder" : decision.TriggerType;
        if (!Templates.TryGetValue(triggerType, out var list))
            list = Templates["GentleCheckIn"];

        var chosen = list[Random.Shared.Next(list.Count)];
        var sourceHint = context.WorkoutSource switch
        {
            "custom" => "Buổi bạn tự lên ",
            "both" => "Buổi lịch + custom ",
            _ => "Buổi lộ trình "
        };

        var body = chosen.Body
            .Replace("{TodayWorkoutName}", context.TodayWorkoutName ?? "buổi tập")
            .Replace("{ScheduledLocalTime}", context.ScheduledLocalTime ?? "hôm nay")
            .Replace("{WorkoutSourceHint}", sourceHint)
            .Replace("{CurrentStreak}", context.CurrentStreak.ToString())
            .Replace("{CompletionRate}", context.CompletionRate.ToString())
            .Replace("{MissedRecentCount}", context.MissedRecentCount.ToString())
            .Replace("{MealsLoggedToday}", context.MealsLoggedToday.ToString())
            .Replace("{RemainingCaloriesPct}", context.RemainingCaloriesPct.ToString())
            .Replace("{WaterPct}", context.WaterPct.ToString());

        return new GeneratedPushMessageDto(chosen.Title, body, deepLink);
    }
}
