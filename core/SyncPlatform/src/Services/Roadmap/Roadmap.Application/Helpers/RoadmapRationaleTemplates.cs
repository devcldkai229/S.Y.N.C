namespace Roadmap.Application.Helpers;

public static class RoadmapRationaleTemplates
{
    public static (string Vi, string En) PhaseRationale(
        string normalizedGoal,
        string normalizedExperience,
        string currentPhaseKey)
    {
        var phaseVi = currentPhaseKey switch
        {
            RoadmapPhaseCatalog.Build => "Tăng cường",
            RoadmapPhaseCatalog.Peak => "Bứt phá",
            _ => "Nền tảng",
        };
        var phaseEn = currentPhaseKey switch
        {
            RoadmapPhaseCatalog.Build => "Build",
            RoadmapPhaseCatalog.Peak => "Peak",
            _ => "Foundation",
        };

        return (normalizedGoal, normalizedExperience) switch
        {
            ("FatLoss", "Beginner") => (
                "Giai đoạn nền tảng xây sức bền và kỹ thuật trước khi tăng tải — vì bạn mới tập, mục tiêu giảm mỡ.",
                "Foundation phase builds endurance and technique before load increases — you are new to training with a fat-loss goal."),
            ("FatLoss", "Intermediate") => (
                "Giai đoạn tăng cường kết hợp sức mạnh và cardio để đẩy tốc độ giảm mỡ, vẫn giữ kỹ thuật ổn định.",
                "Build phase combines strength and cardio to accelerate fat loss while keeping technique solid."),
            ("FatLoss", "Advanced") => (
                "Giai đoạn bứt phá tối ưu đốt mỡ và duy trì cơ — tải cao hơn vì bạn đã có nền tảng vững.",
                "Peak phase optimizes fat burn and muscle retention — higher load because you already have a solid base."),
            ("MuscleGain", "Beginner") => (
                "Nền tảng học động tác compound và phục hồi đủ trước khi tăng volume — mục tiêu tăng cơ.",
                "Foundation focuses on compound lifts and recovery before increasing volume — muscle-gain goal."),
            ("MuscleGain", "Intermediate") => (
                "Tăng volume và progressive overload có kiểm soát để kích thích hypertrophy.",
                "Controlled volume and progressive overload to drive hypertrophy."),
            ("MuscleGain", "Advanced") => (
                "Giai đoạn chuyên sâu tinh chỉnh volume/intensity theo nhóm cơ ưu tiên.",
                "Advanced phase fine-tunes volume and intensity for priority muscle groups."),
            ("GeneralHealth", _) => (
                "Duy trì thói quen vận động đều, cân bằng sức mạnh – cardio – phục hồi theo thể trạng hiện tại.",
                "Keep a steady training habit balancing strength, cardio, and recovery for your current condition."),
            _ => (
                $"Lộ trình đang ở giai đoạn {phaseVi} — điều chỉnh theo mục tiêu và mức sẵn sàng của bạn.",
                $"Your roadmap is in the {phaseEn} phase — adjusted to your goal and readiness."),
        };
    }

    public static (string Vi, string En) SessionRationale(
        string sessionType,
        string normalizedGoal,
        int energyDemandScore,
        int recoveryRequirementScore)
    {
        var type = (sessionType ?? string.Empty).Trim().ToLowerInvariant();

        if (type.Contains("mobility") || type.Contains("recovery") || recoveryRequirementScore >= 7)
        {
            return (
                "Buổi phục hồi giúp giảm đau cơ và chuẩn bị cho các buổi nặng tiếp theo.",
                "This recovery session helps reduce soreness and prepare you for harder workouts ahead.");
        }

        if (energyDemandScore <= 4)
        {
            return (
                "Buổi nhẹ để duy trì nhịp tập mà không làm quá tải hệ thần kinh.",
                "A lighter session to keep momentum without overloading your nervous system.");
        }

        if (type.Contains("cardio") && normalizedGoal == "FatLoss")
        {
            return (
                "Cardio hỗ trợ thâm hụt calo và sức bền tim mạch trong giai đoạn giảm mỡ.",
                "Cardio supports a calorie deficit and cardiovascular endurance during fat loss.");
        }

        if (type.Contains("strength") || type.Contains("hypertrophy"))
        {
            if (normalizedGoal == "FatLoss" && energyDemandScore >= 6)
            {
                return (
                    "Buổi sức mạnh kích thích nhóm cơ lớn, giúp đốt mỡ hiệu quả hơn ở giai đoạn này.",
                    "Strength work hits large muscle groups to burn fat more effectively in this phase.");
            }

            if (normalizedGoal == "MuscleGain")
            {
                return (
                    "Buổi sức mạnh tạo kích thích hypertrophy — tập trung kiểm soát nhịp và nghỉ giữa hiệp.",
                    "Strength session drives hypertrophy — focus on tempo and rest between sets.");
            }
        }

        return (
            "Buổi này nằm trong kế hoạch tuần để tiến tới mục tiêu lộ trình của bạn.",
            "This session is part of your weekly plan toward your roadmap goal.");
    }

    public static (string Vi, string En) AiAdjustmentNote(
        bool allowAiIntensityAdjustment,
        string readinessLevel)
    {
        if (!allowAiIntensityAdjustment)
        {
            return (
                "Kế hoạch giữ nguyên theo lịch đã đặt.",
                "The plan stays as scheduled.");
        }

        if (readinessLevel.Equals("Rest", StringComparison.OrdinalIgnoreCase))
        {
            return (
                "AI đã giảm nhẹ buổi hôm nay vì bạn hơi mệt.",
                "AI eased today's session because you seem a bit fatigued.");
        }

        return (
            "AI giữ nguyên kế hoạch hôm nay vì bạn đủ khoẻ.",
            "AI keeps today's plan as-is because you are ready enough.");
    }

    public static string ReadinessLevel(int recoveryScore)
    {
        if (recoveryScore >= 70) return "Ready";
        if (recoveryScore >= 40) return "Moderate";
        return "Rest";
    }
}
