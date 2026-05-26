using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Services.SmartPush;

public class SmartPushTemplateService : ISmartPushTemplateService
{
    private record Template(string Title, string Body);

    private static readonly Dictionary<string, List<Template>> Templates = new(StringComparer.OrdinalIgnoreCase)
    {
        {
            "ScheduledWorkoutReminder",
            new List<Template>
            {
                new("Đến giờ vận động rồi", "Hôm nay có {TodayWorkoutName}. Bắt đầu nhẹ 10 phút trước cũng được nhé 💪"),
                new("Tập nhẹ một chút nhé", "Một buổi tập ngắn hôm nay sẽ giúp bạn tiến gần hơn tới mục tiêu."),
                new("Sẵn sàng tập chưa?", "Bắt đầu {TodayWorkoutName} ngay nào. Chỉ cần vào guồng trước đã 🔥")
            }
        },
        {
            "FinishWorkoutReminder",
            new List<Template>
            {
                new("Tiếp nốt chút nhé", "Bạn đã hoàn thành {CompletionRate}% rồi. Quay lại thêm một chút là rất đáng giá 🔥"),
                new("Gần tới rồi đó", "Buổi tập đã bắt đầu rồi. Hoàn thành thêm vài phút nữa để giữ nhịp nhé."),
                new("Đừng bỏ giữa chừng nha", "Bạn đã vào guồng rồi. Tập tiếp nhẹ nhàng thêm một chút thôi 💪")
            }
        },
        {
            "StreakProtectionReminder",
            new List<Template>
            {
                new("Giữ chuỗi nào 🔥", "Bạn đang có chuỗi {CurrentStreak} ngày. Một buổi tập ngắn hôm nay cũng giúp giữ đà rất tốt."),
                new("Chuỗi đang đẹp đó", "Streak {CurrentStreak} ngày rồi. Hôm nay chỉ cần tập nhẹ là vẫn giữ được nhịp."),
                new("Đừng để mất đà", "Bạn đã duy trì {CurrentStreak} ngày. Thêm một buổi ngắn hôm nay nhé 💪")
            }
        },
        {
            "RecoveryGentleReminder",
            new List<Template>
            {
                new("Tập nhẹ thôi nhé 💚", "Hôm nay bạn có vẻ hơi mệt. Chỉ cần 10-15 phút vận động nhẹ cũng đủ để giữ nhịp."),
                new("Nhẹ nhàng thôi nha", "Không cần tập nặng hôm nay. Một chút vận động nhẹ cũng là một bước tốt cho cơ thể.")
            }
        }
    };

    public GeneratedPushMessageDto BuildMessage(SmartPushContextDto context, SmartPushDecision decision, string deepLink)
    {
        var triggerType = string.IsNullOrWhiteSpace(decision.TriggerType) ? "ScheduledWorkoutReminder" : decision.TriggerType;
        
        if (!Templates.TryGetValue(triggerType, out var list))
        {
            // Fallback to ScheduledWorkoutReminder if triggerType is unknown
            list = Templates["ScheduledWorkoutReminder"];
        }

        var idx = Random.Shared.Next(list.Count);
        var chosen = list[idx];

        var todayWorkoutName = context.TodayWorkoutName ?? "buổi tập";
        var body = chosen.Body
            .Replace("{TodayWorkoutName}", todayWorkoutName)
            .Replace("{CurrentStreak}", context.CurrentStreak.ToString())
            .Replace("{CompletionRate}", context.CompletionRate.ToString())
            .Replace("{ActualDurationMinutes}", context.ActualDurationMinutes.ToString());

        return new GeneratedPushMessageDto(
            Title: chosen.Title,
            Body: body,
            DeepLink: deepLink
        );
    }
}
