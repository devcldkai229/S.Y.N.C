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
        },
        {
            "StreakCelebrateReminder",
            new List<Template>
            {
                new("Bảo toàn chuỗi thành công! 🔥", "Chúc mừng bạn đã duy trì chuỗi {CurrentStreak} ngày liên tục. Hãy tiếp tục giữ vững phong độ nhé!"),
                new("Chuỗi {CurrentStreak} ngày thật tuyệt! 🌟", "Bạn đang làm rất xuất sắc! Duy trì chuỗi tập luyện {CurrentStreak} ngày là một thành tích đáng tự hào.")
            }
        },
        {
            "StreakEncourageReminder",
            new List<Template>
            {
                new("Giữ chuỗi tập luyện nào! 🔥", "Đừng để mất chuỗi {CurrentStreak} ngày tập luyện nhé. Ngày mai chỉ cần vận động một chút thôi!"),
                new("Duy trì đà tập luyện 💪", "Chuỗi {CurrentStreak} ngày của bạn rất đáng quý. Ngày mai cố gắng hoàn thành buổi tập nhé!")
            }
        },
        {
            "TomorrowWorkoutPreview",
            new List<Template>
            {
                new("Kế hoạch tập luyện ngày mai 📅", "Ngày mai bạn có lịch tập '{TomorrowWorkoutName}'. Hãy chuẩn bị sẵn sàng nhé!"),
                new("Sẵn sàng cho ngày mai chưa? 🔥", "Buổi tập '{TomorrowWorkoutName}' đang chờ bạn ngày mai với các bài tập như {TomorrowExercises}. Lên lịch thôi!")
            }
        },
        {
            "TodayWorkoutSummary",
            new List<Template>
            {
                new("Tóm tắt buổi tập hôm nay 💪", "Bạn đã hoàn thành buổi tập: {ActualDurationMinutes} phút, đốt cháy {CaloriesBurned} kcal. Rất tuyệt vời!"),
                new("Hoàn thành {CompletionRate}% buổi tập 👍", "Bạn đã làm tốt hôm nay! AI Coach nhận xét: {TodayWorkoutAiCoachFeedback}")
            }
        },
        {
            "NutritionWaterReminder",
            new List<Template>
            {
                new("Bổ sung nước bạn ơi! 💧", "Hôm nay bạn đã uống {NutritionWaterIntakeMl}ml nước. Hãy nhớ uống đủ nước để cơ thể luôn tràn đầy năng lượng."),
                new("Đã đủ nước chưa? 🥤", "Uống nước đều đặn giúp tăng hiệu quả tập luyện. Hôm nay bạn đã uống {NutritionWaterIntakeMl}ml.")
            }
        },
        {
            "NutritionProteinReminder",
            new List<Template>
            {
                new("Mục tiêu Protein hôm nay 🥚", "Bạn đã nạp {NutritionConsumedProtein}g protein trên mục tiêu {NutritionTargetProtein}g. Hãy bổ sung thêm đạm nhé!"),
                new("Cung cấp đủ đạm cho cơ bắp 💪", "Để phục hồi tốt nhất, hãy nhớ nạp đủ protein. Bạn hiện nạp {NutritionConsumedProtein}g/{NutritionTargetProtein}g.")
            }
        },
        {
            "NutritionCalorieUnder",
            new List<Template>
            {
                new("Nhắc nhở dinh dưỡng 🍽️", "Bạn đã nạp {NutritionConsumedCalories}/{NutritionTargetCalories} kcal hôm nay. Hãy ăn nhẹ để nạp đủ năng lượng nhé!"),
                new("Theo dõi năng lượng nạp vào 🥗", "Đảm bảo cung cấp đủ calo cho cơ thể. Bạn đang ở mức {NutritionConsumedCalories}/{NutritionTargetCalories} kcal.")
            }
        },
        {
            "NutritionLogMeals",
            new List<Template>
            {
                new("Ghi chép bữa ăn hôm nay 📝", "Hôm nay bạn ăn gì nhỉ? Ghi chép lại các bữa ăn giúp AI đưa ra gợi ý thực đơn chính xác hơn cho bạn."),
                new("Đừng quên log bữa ăn nhé 🥗", "Hãy dành 1 phút để ghi chép các món đã ăn hôm nay để theo dõi sát sao mục tiêu dinh dưỡng.")
            }
        }
    };

    public GeneratedPushMessageDto BuildMessage(SmartPushContextDto context, SmartPushDecision decision, string deepLink)
    {
        var triggerType = string.IsNullOrWhiteSpace(decision.TriggerType) ? "ScheduledWorkoutReminder" : decision.TriggerType;
        
        if (!Templates.TryGetValue(triggerType, out var list))
        {
            list = Templates["ScheduledWorkoutReminder"];
        }

        var idx = Random.Shared.Next(list.Count);
        var chosen = list[idx];

        var todayWorkoutName = context.TodayWorkoutName ?? "buổi tập";
        var tomorrowWorkoutName = context.TomorrowWorkoutName ?? "buổi tập tiếp theo";
        var tomorrowExercises = context.TomorrowExerciseNames != null && context.TomorrowExerciseNames.Count > 0 
            ? string.Join(", ", context.TomorrowExerciseNames.Take(3)) 
            : "các bài tập cá nhân";
        var aiCoachFeedback = context.TodayWorkoutAiCoachFeedback ?? "hãy duy trì tinh thần này!";

        var body = chosen.Body
            .Replace("{TodayWorkoutName}", todayWorkoutName)
            .Replace("{TomorrowWorkoutName}", tomorrowWorkoutName)
            .Replace("{TomorrowExercises}", tomorrowExercises)
            .Replace("{TodayWorkoutAiCoachFeedback}", aiCoachFeedback)
            .Replace("{CurrentStreak}", context.CurrentStreak.ToString())
            .Replace("{CompletionRate}", context.CompletionRate.ToString())
            .Replace("{ActualDurationMinutes}", context.ActualDurationMinutes.ToString())
            .Replace("{CaloriesBurned}", context.CaloriesBurned.ToString())
            .Replace("{NutritionWaterIntakeMl}", context.NutritionWaterIntakeMl.ToString())
            .Replace("{NutritionConsumedProtein}", ((int)context.NutritionConsumedProtein).ToString())
            .Replace("{NutritionTargetProtein}", ((int)context.NutritionTargetProtein).ToString())
            .Replace("{NutritionConsumedCalories}", context.NutritionConsumedCalories.ToString())
            .Replace("{NutritionTargetCalories}", context.NutritionTargetCalories.ToString());

        return new GeneratedPushMessageDto(
            Title: chosen.Title,
            Body: body,
            DeepLink: deepLink
        );
    }
}
