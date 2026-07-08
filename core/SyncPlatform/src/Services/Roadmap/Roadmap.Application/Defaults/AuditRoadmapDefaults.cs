using Libs.Shared.Enums;
using Roadmap.Application.DTOs;

namespace Roadmap.Application.Defaults;

/// <summary>Starter PersonalizedRoadmap template for newly verified users (AI audit / onboarding).</summary>
public static class AuditRoadmapDefaults
{
    public const string RoadmapName = "AI Audit Fat Loss 12W";
    public const string FitnessGoal = "FatLoss";
    public const string CurrentPhase = "Foundation";
    public const int DurationWeeks = 12;

    public static CreatePersonalizedRoadmapDto ForUser(Guid userId, DateTimeOffset? utcNow = null)
    {
        var now = utcNow ?? DateTimeOffset.UtcNow;
        var start = now.Date;

        return new CreatePersonalizedRoadmapDto
        {
            UserId = userId,
            RoadmapName = RoadmapName,
            FitnessGoal = FitnessGoal,
            CurrentPhase = CurrentPhase,
            StartDate = start,
            ExpectedEndDate = start.AddDays(DurationWeeks * 7),
            CurrentWeightKg = 78,
            TargetWeightKg = 72,
            InitialFatPercentage = 22,
            TargetFatPercentage = 16,
            AdaptiveAiEnabled = true,
            AllowAiReschedule = true,
            AllowAiIntensityAdjustment = true,
            AllowAiRecoveryDeload = true,
            RoadmapStatus = RoadmapStatus.Active,
        };
    }
}
