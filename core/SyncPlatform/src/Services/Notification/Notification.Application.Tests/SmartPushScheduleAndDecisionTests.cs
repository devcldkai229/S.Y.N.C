using Microsoft.Extensions.Options;
using Moq;
using Notification.Application.DTOs.SmartPush;
using Notification.Application.Options;
using Notification.Application.Services.SmartPush;
using Notification.Domain.Models;
using Xunit;
using MsOptions = Microsoft.Extensions.Options.Options;

namespace Notification.Application.Tests;

public class SmartPushScheduleServiceTests
{
    private static SmartPushScheduleService CreateService(SmartPushOptions? opts = null)
    {
        opts ??= new SmartPushOptions
        {
            MaxPerDay = 2,
            MinGapHours = 5,
            WindowStartLocal = "06:00",
            WindowEndLocal = "20:00",
            JitterMinutes = 0 // deterministic
        };
        return new SmartPushScheduleService(MsOptions.Create(opts));
    }

    [Fact]
    public void ComputeNextFire_UsesPeakEnergyMidpoint_WithinWindow()
    {
        var svc = CreateService();
        var user = new SmartPushEnabledUserDto(
            Guid.NewGuid(),
            "Asia/Ho_Chi_Minh",
            PreferredReminderTime: new TimeSpan(7, 0, 0),
            PeakEnergyTimeWindow: "07:00-10:00",
            LastActiveAt: null,
            SmartPushEnabled: true,
            AllowAiGeneratedNotification: true);

        // Fixed morning UTC before local window
        var utcNow = new DateTimeOffset(2026, 7, 14, 0, 0, 0, TimeSpan.Zero);
        var next = svc.ComputeNextFire(user, utcNow, existing: null);

        Assert.NotNull(next);
        var tz = TimeZoneInfo.FindSystemTimeZoneById("Asia/Ho_Chi_Minh");
        var local = TimeZoneInfo.ConvertTime(next!.Value, tz);
        Assert.InRange(local.TimeOfDay, new TimeSpan(6, 0, 0), new TimeSpan(20, 0, 0));
    }

    [Fact]
    public void ComputeNextFire_ReturnsNull_WhenDisabled()
    {
        var svc = CreateService();
        var user = new SmartPushEnabledUserDto(
            Guid.NewGuid(),
            "Asia/Ho_Chi_Minh",
            null, null, null,
            SmartPushEnabled: false,
            AllowAiGeneratedNotification: true);

        var next = svc.ComputeNextFire(user, DateTimeOffset.UtcNow, null);
        Assert.Null(next);
    }

    [Fact]
    public void MarkSent_IncrementsSentToday_AndResetsOnNewDay()
    {
        var svc = CreateService();
        var schedule = new SmartPushSchedule
        {
            UserId = Guid.NewGuid(),
            Timezone = "Asia/Ho_Chi_Minh",
            SentToday = 1,
            DayKeyLocal = new DateOnly(2020, 1, 1)
        };

        svc.MarkSent(schedule, "TodayWorkoutReminder", DateTimeOffset.UtcNow);
        Assert.Equal(1, schedule.SentToday); // day changed → reset then +1
        Assert.Equal("TodayWorkoutReminder", schedule.LastTrigger);
    }
}

public class SmartPushDecisionServiceTests
{
    private static SmartPushContextDto BaseContext(Action<SmartPushContextDtoBuilder>? configure = null)
    {
        var b = new SmartPushContextDtoBuilder();
        configure?.Invoke(b);
        return b.Build();
    }

    private sealed class SmartPushContextDtoBuilder
    {
        public Guid UserId { get; set; } = Guid.NewGuid();
        public bool SmartPushEnabled { get; set; } = true;
        public bool AllowAiGeneratedNotification { get; set; } = true;
        public bool HasWorkoutScheduledToday { get; set; }
        public bool CompletedWorkoutToday { get; set; }
        public bool HasStartedWorkoutToday { get; set; }
        public int CurrentStreak { get; set; }
        public int MissedRecentCount { get; set; }
        public int BurnoutRiskScore { get; set; }
        public int RecoveryScore { get; set; } = 100;
        public int ChurnRiskScore { get; set; }
        public int MealsLoggedToday { get; set; } = 2;
        public int RemainingCaloriesPct { get; set; } = 40;
        public int WaterPct { get; set; } = 80;
        public DateTime UtcNow { get; set; } = new DateTime(2026, 7, 14, 10, 0, 0, DateTimeKind.Utc);
        public DateOnly LocalDate { get; set; } = new(2026, 7, 14);
        public int? DaysSinceLastWeighIn { get; set; } = 1;

        public SmartPushContextDto Build() => new(
            UserId, "Nguyen Van A", BurnoutRiskScore, CurrentStreak, 10, 1, 100,
            "Gentle", "LoseWeight", "Active", "Beginner", "Home",
            SmartPushEnabled, AllowAiGeneratedNotification, "Asia/Ho_Chi_Minh", "FriendlyBuddy",
            HasWorkoutScheduledToday, "Buổi chạy", HasStartedWorkoutToday, CompletedWorkoutToday,
            null, null, 0, 0, 0, 0, 0, 0, 0,
            SubscriptionTier: "Free",
            RecoveryScore: RecoveryScore,
            ChurnRiskScore: ChurnRiskScore,
            MissedRecentCount: MissedRecentCount,
            MealsLoggedToday: MealsLoggedToday,
            RemainingCaloriesPct: RemainingCaloriesPct,
            WaterPct: WaterPct,
            UtcNow: UtcNow,
            LocalDate: LocalDate,
            DaysSinceLastWeighIn: DaysSinceLastWeighIn);
    }

    private static SmartPushDecisionService Create(Mock<ISmartPushScheduleRepository>? repo = null)
    {
        repo ??= new Mock<ISmartPushScheduleRepository>();
        repo.Setup(r => r.HasDedupKeyAsync(It.IsAny<string>(), It.IsAny<CancellationToken>())).ReturnsAsync(false);
        repo.Setup(r => r.GetLastTriggerSentAtAsync(It.IsAny<Guid>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((DateTimeOffset?)null);

        return new SmartPushDecisionService(MsOptions.Create(new SmartPushOptions()), repo.Object);
    }

    [Fact]
    public async Task Decide_PrefersTodayWorkoutReminder()
    {
        var svc = Create();
        var decision = await svc.DecideAsync(BaseContext(b =>
        {
            b.HasWorkoutScheduledToday = true;
            b.CompletedWorkoutToday = false;
        }), CancellationToken.None);

        Assert.True(decision.ShouldSend);
        Assert.Equal("TodayWorkoutReminder", decision.TriggerType);
    }

    [Fact]
    public async Task Decide_Skips_WhenDisabled()
    {
        var svc = Create();
        var decision = await svc.DecideAsync(BaseContext(b => b.SmartPushEnabled = false), CancellationToken.None);
        Assert.False(decision.ShouldSend);
    }

    [Fact]
    public async Task Decide_Skips_WhenDedupExists()
    {
        var repo = new Mock<ISmartPushScheduleRepository>();
        repo.Setup(r => r.HasDedupKeyAsync(It.IsAny<string>(), It.IsAny<CancellationToken>())).ReturnsAsync(true);
        repo.Setup(r => r.GetLastTriggerSentAtAsync(It.IsAny<Guid>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((DateTimeOffset?)null);

        var svc = new SmartPushDecisionService(MsOptions.Create(new SmartPushOptions()), repo.Object);
        var decision = await svc.DecideAsync(BaseContext(b =>
        {
            b.HasWorkoutScheduledToday = true;
            b.CompletedWorkoutToday = false;
        }), CancellationToken.None);

        Assert.False(decision.ShouldSend);
    }

    [Fact]
    public async Task Decide_WeighInReminder_WhenStale()
    {
        var svc = Create();
        var decision = await svc.DecideAsync(BaseContext(b =>
        {
            b.HasWorkoutScheduledToday = false;
            b.DaysSinceLastWeighIn = 10;
        }), CancellationToken.None);

        Assert.True(decision.ShouldSend);
        Assert.Equal("WeighInReminder", decision.TriggerType);
    }
}
