using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Notification.Application.Clients;
using Notification.Application.DTOs;
using Notification.Application.DTOs.SmartPush;
using Notification.Application.Options;
using Notification.Domain.Enums;
using Notification.Domain.Models;
using Notification.Application.Services;

namespace Notification.Application.Services.SmartPush;

public class SmartPushNotificationService : ISmartPushNotificationService
{
    private readonly IIamSmartPushClient _iamClient;
    private readonly IRoadmapActivityClient _roadmapClient;
    private readonly INutritionActivityClient _nutritionClient;
    private readonly IAdaptiveAiClient _adaptiveAiClient;
    private readonly ISmartPushDecisionService _decisionService;
    private readonly IOpenAiClient _openAiClient;
    private readonly ISmartPushAiUsagePolicy _aiUsagePolicy;
    private readonly ISmartPushDeepLinkResolver _deepLinkResolver;
    private readonly ISmartPushTemplateService _templateService;
    private readonly ISmartPushGenerationCache _generationCache;
    private readonly ISmartPushScheduleRepository _scheduleRepo;
    private readonly ISmartPushScheduleService _scheduleService;
    private readonly INotificationService _notificationService;
    private readonly SmartPushOptions _options;
    private readonly ILogger<SmartPushNotificationService> _logger;

    public SmartPushNotificationService(
        IIamSmartPushClient iamClient,
        IRoadmapActivityClient roadmapClient,
        INutritionActivityClient nutritionClient,
        IAdaptiveAiClient adaptiveAiClient,
        ISmartPushDecisionService decisionService,
        IOpenAiClient openAiClient,
        ISmartPushAiUsagePolicy aiUsagePolicy,
        ISmartPushDeepLinkResolver deepLinkResolver,
        ISmartPushTemplateService templateService,
        ISmartPushGenerationCache generationCache,
        ISmartPushScheduleRepository scheduleRepo,
        ISmartPushScheduleService scheduleService,
        INotificationService notificationService,
        IOptions<SmartPushOptions> options,
        ILogger<SmartPushNotificationService> logger)
    {
        _iamClient = iamClient;
        _roadmapClient = roadmapClient;
        _nutritionClient = nutritionClient;
        _adaptiveAiClient = adaptiveAiClient;
        _decisionService = decisionService;
        _openAiClient = openAiClient;
        _aiUsagePolicy = aiUsagePolicy;
        _deepLinkResolver = deepLinkResolver;
        _templateService = templateService;
        _generationCache = generationCache;
        _scheduleRepo = scheduleRepo;
        _scheduleService = scheduleService;
        _notificationService = notificationService;
        _options = options.Value;
        _logger = logger;
    }

    public async Task ProcessDueUsersAsync(DateTime utcNow, CancellationToken cancellationToken)
    {
        var now = new DateTimeOffset(DateTime.SpecifyKind(utcNow, DateTimeKind.Utc));
        var batch = Math.Clamp(_options.ClaimBatchSize, 1, 500);
        _logger.LogInformation("Claiming due smart push schedules at {UtcNow} (batch={Batch})", now, batch);

        IReadOnlyList<SmartPushSchedule> claimed;
        try
        {
            claimed = await _scheduleRepo.ClaimDueAsync(now, batch, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to claim due smart push schedules.");
            return;
        }

        _logger.LogInformation("Claimed {Count} due schedules.", claimed.Count);
        var dueScanned = claimed.Count;
        var triggered = 0;
        var suppressed = 0;
        var sent = 0;
        var llmFallback = 0;

        foreach (var schedule in claimed)
        {
            try
            {
                var outcome = await ProcessClaimedScheduleAsync(schedule, now, force: false, cancellationToken);
                switch (outcome)
                {
                    case ProcessOutcome.Sent:
                        sent++;
                        triggered++;
                        break;
                    case ProcessOutcome.Suppressed:
                        suppressed++;
                        break;
                    case ProcessOutcome.LlmFallbackSent:
                        sent++;
                        triggered++;
                        llmFallback++;
                        break;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing smart push for user {UserId}", schedule.UserId);
                try
                {
                    schedule.NextFireAtUtc = now.AddHours(1);
                    schedule.UpdatedAt = DateTimeOffset.UtcNow;
                    await _scheduleRepo.UpsertAsync(schedule, cancellationToken);
                }
                catch (Exception rescheduleEx)
                {
                    _logger.LogError(rescheduleEx, "Failed to backoff-reschedule user {UserId}", schedule.UserId);
                }
            }
        }

        _logger.LogInformation(
            "Smart push cycle metrics: due_scanned={Due}, triggered={Triggered}, suppressed={Suppressed}, sent={Sent}, llm_fallback={Fallback}",
            dueScanned, triggered, suppressed, sent, llmFallback);
    }

    public async Task SeedUserScheduleAsync(Guid userId, CancellationToken cancellationToken)
    {
        var iam = await _iamClient.GetContextAsync(userId, cancellationToken)
            ?? throw new InvalidOperationException($"IAM context not found for user {userId}.");

        var enabled = new SmartPushEnabledUserDto(
            iam.UserId,
            iam.TimeZoneId,
            iam.PreferredReminderTime,
            iam.PeakEnergyTimeWindow,
            iam.LastActiveAt,
            iam.SmartPushEnabled,
            iam.AllowAiGeneratedNotification);

        var existing = await _scheduleRepo.GetAsync(userId, cancellationToken);
        var schedule = _scheduleService.BuildOrRefreshSchedule(enabled, DateTimeOffset.UtcNow, existing);
        // Force soon fire for test seed
        schedule.NextFireAtUtc = DateTimeOffset.UtcNow.AddSeconds(5);
        schedule.Enabled = enabled.SmartPushEnabled && enabled.AllowAiGeneratedNotification;
        await _scheduleRepo.UpsertAsync(schedule, cancellationToken);
        _logger.LogInformation("Seeded smart push schedule for user {UserId}, next_fire={Next}", userId, schedule.NextFireAtUtc);
    }

    public async Task ProcessUserNowAsync(Guid userId, CancellationToken cancellationToken)
    {
        var existing = await _scheduleRepo.GetAsync(userId, cancellationToken);
        if (existing is null)
            await SeedUserScheduleAsync(userId, cancellationToken);

        var schedule = await _scheduleRepo.GetAsync(userId, cancellationToken)
            ?? throw new InvalidOperationException("Schedule missing after seed.");

        schedule.NextFireAtUtc = DateTimeOffset.UtcNow;
        await _scheduleRepo.UpsertAsync(schedule, cancellationToken);
        await ProcessClaimedScheduleAsync(schedule, DateTimeOffset.UtcNow, force: true, cancellationToken);
    }

    public async Task NightlyRecomputeAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Starting nightly smart push schedule recompute.");
        IReadOnlyList<SmartPushEnabledUserDto> users;
        try
        {
            users = await _iamClient.GetEnabledUsersAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Nightly recompute failed to load enabled users from IAM.");
            return;
        }

        var now = DateTimeOffset.UtcNow;
        foreach (var user in users)
        {
            try
            {
                var existing = await _scheduleRepo.GetAsync(user.UserId, cancellationToken);
                var schedule = _scheduleService.BuildOrRefreshSchedule(user, now, existing);
                await _scheduleRepo.UpsertAsync(schedule, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to refresh schedule for user {UserId}", user.UserId);
            }
        }

        _logger.LogInformation("Nightly recompute finished for {Count} users.", users.Count);

        // Weekly Adaptive Coaching recalibration (Premium/Ultra) — best-effort.
        try
        {
            var premiumIds = await _iamClient.GetPremiumUserIdsAsync(cancellationToken);
            await _adaptiveAiClient.TriggerWeeklyRecalcAsync(premiumIds, cancellationToken);
            _logger.LogInformation("Adaptive weekly-recalc triggered for {Count} premium users.", premiumIds.Count);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Adaptive weekly-recalc skipped (IAM/AI unavailable).");
        }
    }

    private enum ProcessOutcome { None, Sent, Suppressed, LlmFallbackSent }

    private async Task<ProcessOutcome> ProcessClaimedScheduleAsync(
        SmartPushSchedule schedule,
        DateTimeOffset utcNow,
        bool force,
        CancellationToken ct)
    {
        var iam = await _iamClient.GetContextAsync(schedule.UserId, ct);
        if (iam is null)
        {
            schedule.Enabled = false;
            schedule.NextFireAtUtc = null;
            schedule.UpdatedAt = DateTimeOffset.UtcNow;
            await _scheduleRepo.UpsertAsync(schedule, ct);
            return ProcessOutcome.None;
        }

        var enabledUser = new SmartPushEnabledUserDto(
            iam.UserId,
            iam.TimeZoneId,
            iam.PreferredReminderTime,
            iam.PeakEnergyTimeWindow,
            iam.LastActiveAt,
            iam.SmartPushEnabled,
            iam.AllowAiGeneratedNotification);

        if (!(iam.SmartPushEnabled && iam.AllowAiGeneratedNotification))
        {
            schedule.Enabled = false;
            schedule.NextFireAtUtc = null;
            schedule.UpdatedAt = DateTimeOffset.UtcNow;
            await _scheduleRepo.UpsertAsync(schedule, ct);
            return ProcessOutcome.None;
        }

        // Quota already used today
        var tz = ResolveTz(iam.TimeZoneId);
        var localNow = TimeZoneInfo.ConvertTime(utcNow, tz);
        var localDate = DateOnly.FromDateTime(localNow.DateTime);
        if (schedule.DayKeyLocal != localDate)
        {
            schedule.SentToday = 0;
            schedule.DayKeyLocal = localDate;
        }

        if (!force && schedule.SentToday >= schedule.SlotsPerDay)
        {
            _scheduleService.RescheduleAfterSuppress(schedule, utcNow, enabledUser);
            await _scheduleRepo.UpsertAsync(schedule, ct);
            return ProcessOutcome.Suppressed;
        }

        TodayWorkoutActivityDto? roadmap = null;
        try
        {
            roadmap = await _roadmapClient.GetTodayActivityAsync(schedule.UserId, iam.TimeZoneId, ct);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Roadmap activity fetch failed for {UserId}", schedule.UserId);
        }

        TodayNutritionSignalDto? nutrition = null;
        try
        {
            nutrition = await _nutritionClient.GetTodaySummaryAsync(schedule.UserId, iam.TimeZoneId, ct);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Nutrition summary fetch failed for {UserId}", schedule.UserId);
        }

        var context = BuildContext(iam, roadmap, nutrition, utcNow, localDate);
        var decision = await _decisionService.DecideAsync(context, ct);

        if (!decision.ShouldSend)
        {
            _logger.LogInformation("Suppressing push for {UserId}: {Reason}", schedule.UserId, decision.Reason);
            _scheduleService.RescheduleAfterSuppress(schedule, utcNow, enabledUser);
            await _scheduleRepo.UpsertAsync(schedule, ct);
            return ProcessOutcome.Suppressed;
        }

        var deepLink = _deepLinkResolver.ResolveDeepLink(context, decision);
        var cacheKey = BuildCacheKey(context, decision);
        GeneratedPushMessageDto generated;
        var isAiGenerated = false;
        var usedFallback = false;
        var shouldUseAi = _aiUsagePolicy.ShouldUseAi(context, decision);

        if (_generationCache.TryGet(cacheKey, out var cached))
        {
            generated = new GeneratedPushMessageDto(cached.Title, cached.Body, deepLink);
            isAiGenerated = true;
        }
        else if (shouldUseAi)
        {
            try
            {
                generated = await _openAiClient.GenerateAsync(context, decision, deepLink, ct);
                isAiGenerated = true;
                _generationCache.Set(cacheKey, generated.Title, generated.Body);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "OpenAI generation failed for {UserId}; using template.", schedule.UserId);
                generated = _templateService.BuildMessage(context, decision, deepLink);
                usedFallback = true;
            }
        }
        else
        {
            generated = _templateService.BuildMessage(context, decision, deepLink);
        }

        var dedupKey = $"{context.UserId:D}:{localDate:yyyy-MM-dd}:{decision.TriggerType}";
        var log = new SmartPushLog
        {
            UserId = context.UserId,
            SentAtUtc = utcNow,
            LocalDate = localDate,
            Trigger = decision.TriggerType,
            DedupKey = dedupKey,
            Channel = "inapp",
            Title = generated.Title,
            Body = generated.Body
        };

        if (!await _scheduleRepo.TryInsertLogAsync(log, ct))
        {
            _logger.LogInformation("Dedup prevented send for {UserId} key={Dedup}", schedule.UserId, dedupKey);
            _scheduleService.RescheduleAfterSuppress(schedule, utcNow, enabledUser);
            await _scheduleRepo.UpsertAsync(schedule, ct);
            return ProcessOutcome.Suppressed;
        }

        var dataPayload = new Dictionary<string, object?>
        {
            ["source"] = "SmartPushNotificationEngine",
            ["generatedBy"] = isAiGenerated ? "OpenAI" : "Template",
            ["aiGenerated"] = isAiGenerated,
            ["triggerType"] = decision.TriggerType,
            ["model"] = isAiGenerated ? (_options.Model ?? "gpt-4o-mini") : null,
            ["deepLink"] = deepLink,
            ["currentStreak"] = context.CurrentStreak,
            ["burnoutRiskScore"] = context.BurnoutRiskScore,
            ["completionRate"] = context.CompletionRate
        };

        var sendDto = new SendNotificationDto
        {
            UserId = context.UserId,
            Type = NotificationType.WorkoutReminder,
            Channel = NotificationChannel.Push,
            Priority = NotificationPriority.Normal,
            Title = generated.Title,
            Body = generated.Body,
            DeepLink = deepLink,
            DataPayloadJson = JsonSerializer.Serialize(dataPayload),
            AiContextSnapshotJson = isAiGenerated ? JsonSerializer.Serialize(BuildAnonSnapshot(context, decision)) : null
        };

        var message = await _notificationService.SendNotificationAsync(sendDto, ct);
        _logger.LogInformation(
            "Sent Smart Push to {UserId}. MessageId={MessageId}, Trigger={Trigger}",
            schedule.UserId, message.Id, decision.TriggerType);

        _scheduleService.MarkSent(schedule, decision.TriggerType, utcNow);
        schedule.NextFireAtUtc = _scheduleService.ComputeNextFire(enabledUser, utcNow, schedule);
        schedule.UpdatedAt = DateTimeOffset.UtcNow;
        await _scheduleRepo.UpsertAsync(schedule, ct);

        return usedFallback ? ProcessOutcome.LlmFallbackSent : ProcessOutcome.Sent;
    }

    private static SmartPushContextDto BuildContext(
        IamSmartPushContextDto iam,
        TodayWorkoutActivityDto? roadmap,
        TodayNutritionSignalDto? nutrition,
        DateTimeOffset utcNow,
        DateOnly localDate) =>
        new(
            UserId: iam.UserId,
            FullName: iam.FullName,
            BurnoutRiskScore: iam.BurnoutRiskScore,
            CurrentStreak: iam.CurrentStreak,
            LongestStreak: iam.LongestStreak,
            CurrentLevel: iam.CurrentLevel,
            CurrentXP: iam.CurrentXP,
            MotivationStyle: iam.MotivationStyle,
            FitnessGoal: iam.FitnessGoal,
            ActivityLevel: iam.ActivityLevel,
            FitnessExperienceLevel: iam.FitnessExperienceLevel,
            WorkoutLocationPreference: iam.WorkoutLocationPreference,
            SmartPushEnabled: iam.SmartPushEnabled,
            AllowAiGeneratedNotification: iam.AllowAiGeneratedNotification,
            TimeZoneId: iam.TimeZoneId,
            AgentPersona: iam.AgentPersona,
            HasWorkoutScheduledToday: roadmap?.HasWorkoutScheduledToday ?? false,
            TodayWorkoutName: roadmap?.TodayWorkoutName,
            HasStartedWorkoutToday: roadmap?.HasStartedWorkoutToday ?? false,
            CompletedWorkoutToday: roadmap?.CompletedWorkoutToday ?? false,
            LatestStartedAt: roadmap?.LatestStartedAt,
            LatestCompletedAt: roadmap?.LatestCompletedAt,
            ActualDurationMinutes: roadmap?.ActualDurationMinutes ?? 0,
            CompletionRate: roadmap?.CompletionRate ?? 0,
            PerceivedDifficulty: roadmap?.PerceivedDifficulty ?? 0,
            EnergyLevelBefore: roadmap?.EnergyLevelBefore ?? 0,
            EnergyLevelAfter: roadmap?.EnergyLevelAfter ?? 0,
            CaloriesBurned: roadmap?.CaloriesBurned ?? 0,
            SkippedExercisesCount: roadmap?.SkippedExercisesCount ?? 0,
            SubscriptionTier: iam.SubscriptionTier,
            RecoveryScore: iam.RecoveryScore,
            ChurnRiskScore: iam.ChurnRiskScore,
            PeakEnergyTimeWindow: iam.PeakEnergyTimeWindow,
            LastActiveAt: iam.LastActiveAt,
            PreferredReminderTime: iam.PreferredReminderTime,
            WorkoutSource: roadmap?.WorkoutSource ?? "none",
            TodayWorkoutType: roadmap?.TodayWorkoutType,
            ScheduledLocalTime: roadmap?.ScheduledLocalTime,
            MissedRecentCount: roadmap?.MissedRecentCount ?? 0,
            MealsLoggedToday: nutrition?.MealsLoggedToday ?? 0,
            RemainingCaloriesPct: nutrition?.RemainingCaloriesPct ?? 100,
            WaterPct: nutrition?.WaterPct ?? 100,
            LastMealLoggedAt: nutrition?.LastMealLoggedAt,
            UtcNow: utcNow.UtcDateTime,
            LocalDate: localDate,
            DaysSinceLastWeighIn: iam.DaysSinceLastWeighIn
        );

    private static string BuildCacheKey(SmartPushContextDto context, SmartPushDecision decision)
    {
        var bucket =
            $"{(context.HasWorkoutScheduledToday ? 1 : 0)}" +
            $"{(context.CompletedWorkoutToday ? 1 : 0)}" +
            $"{Math.Clamp(context.MissedRecentCount, 0, 3)}" +
            $"{Math.Clamp(context.MealsLoggedToday, 0, 4)}" +
            $"{context.RemainingCaloriesPct / 25}" +
            $"{context.WaterPct / 25}" +
            $"{context.WorkoutSource}";
        return $"{decision.TriggerType}|{context.AgentPersona}|{context.MotivationStyle}|{bucket}|vi";
    }

    private static object BuildAnonSnapshot(SmartPushContextDto context, SmartPushDecision decision) => new
    {
        trigger = decision.TriggerType,
        motivationStyle = context.MotivationStyle,
        agentPersona = context.AgentPersona,
        streak = context.CurrentStreak,
        burnout = context.BurnoutRiskScore,
        recovery = context.RecoveryScore,
        hasWorkoutToday = context.HasWorkoutScheduledToday,
        workoutSource = context.WorkoutSource,
        completedToday = context.CompletedWorkoutToday,
        missedRecentCount = context.MissedRecentCount,
        mealsLoggedToday = context.MealsLoggedToday,
        remainingCaloriesPct = context.RemainingCaloriesPct,
        waterPct = context.WaterPct
    };

    private static TimeZoneInfo ResolveTz(string? tzId)
    {
        var id = string.IsNullOrWhiteSpace(tzId) ? "Asia/Ho_Chi_Minh" : tzId;
        try { return TimeZoneInfo.FindSystemTimeZoneById(id); }
        catch { return TimeZoneInfo.FindSystemTimeZoneById("Asia/Ho_Chi_Minh"); }
    }
}
