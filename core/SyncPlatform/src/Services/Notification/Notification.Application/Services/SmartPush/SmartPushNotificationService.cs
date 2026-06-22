using System.Text.Json;
using Microsoft.Extensions.Logging;
using Notification.Application.Clients;
using Notification.Application.DTOs;
using Notification.Application.DTOs.SmartPush;
using Notification.Domain.Enums;
using Notification.Domain.Repositories;
using Notification.Application.Services;

namespace Notification.Application.Services.SmartPush;

public class SmartPushNotificationService : ISmartPushNotificationService
{
    private readonly IIamSmartPushClient _iamClient;
    private readonly IRoadmapActivityClient _roadmapClient;
    private readonly INutritionClient _nutritionClient;
    private readonly ISmartPushDecisionService _decisionService;
    private readonly IDeepSeekClient _deepSeekClient;
    private readonly ISmartPushAiUsagePolicy _aiUsagePolicy;
    private readonly ISmartPushDeepLinkResolver _deepLinkResolver;
    private readonly ISmartPushTemplateService _templateService;
    private readonly INotificationService _notificationService;
    private readonly INotificationMessageRepository _messageRepository;
    private readonly ILogger<SmartPushNotificationService> _logger;

    public SmartPushNotificationService(
        IIamSmartPushClient iamClient,
        IRoadmapActivityClient roadmapClient,
        INutritionClient nutritionClient,
        ISmartPushDecisionService decisionService,
        IDeepSeekClient deepSeekClient,
        ISmartPushAiUsagePolicy aiUsagePolicy,
        ISmartPushDeepLinkResolver deepLinkResolver,
        ISmartPushTemplateService templateService,
        INotificationService notificationService,
        INotificationMessageRepository messageRepository,
        ILogger<SmartPushNotificationService> logger)
    {
        _iamClient = iamClient;
        _roadmapClient = roadmapClient;
        _nutritionClient = nutritionClient;
        _decisionService = decisionService;
        _deepSeekClient = deepSeekClient;
        _aiUsagePolicy = aiUsagePolicy;
        _deepLinkResolver = deepLinkResolver;
        _templateService = templateService;
        _notificationService = notificationService;
        _messageRepository = messageRepository;
        _logger = logger;
    }

    public async Task ProcessDueUsersAsync(
        DateTime utcNow, 
        Guid? targetUserId = null, 
        bool sendImmediately = false, 
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("SmartPush Notification Planner started at UTC {UtcNow}", utcNow);

        IReadOnlyList<DueSmartPushUserDto> dueUsers;
        try
        {
            if (targetUserId.HasValue)
            {
                var userContext = await _iamClient.GetContextAsync(targetUserId.Value, cancellationToken);
                if (userContext == null)
                {
                    _logger.LogWarning("User {UserId} not found in IAM. Cannot run test scan.", targetUserId.Value);
                    return;
                }
                
                dueUsers = new List<DueSmartPushUserDto>
                {
                    new DueSmartPushUserDto(
                        UserId: userContext.UserId,
                        PreferredReminderTime: TimeSpan.FromHours(22),
                        TimeZoneId: userContext.TimeZoneId,
                        MotivationStyle: userContext.MotivationStyle
                    )
                };
            }
            else
            {
                dueUsers = await _iamClient.GetDueUsersAsync(utcNow, cancellationToken);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch active users from IAM Service.");
            return;
        }

        _logger.LogInformation("Found {Count} active smart push users from IAM Service.", dueUsers.Count);

        foreach (var dueUser in dueUsers)
        {
            try
            {
                var tzId = string.IsNullOrWhiteSpace(dueUser.TimeZoneId) ? "Asia/Ho_Chi_Minh" : dueUser.TimeZoneId;
                TimeZoneInfo userTz;
                try
                {
                    userTz = TimeZoneInfo.FindSystemTimeZoneById(tzId);
                }
                catch (Exception)
                {
                    tzId = "Asia/Ho_Chi_Minh";
                    userTz = TimeZoneInfo.FindSystemTimeZoneById(tzId);
                }

                var userLocalNow = TimeZoneInfo.ConvertTime(utcNow, userTz);

                // 1. Only process user when local time is between 22:00 and 23:59 (bypass if sendImmediately)
                if (!sendImmediately && userLocalNow.Hour < 22)
                {
                    _logger.LogDebug("User {UserId} local time is {LocalTime}. Outside 22:00-23:59 planning window. Skipping.", dueUser.UserId, userLocalNow);
                    continue;
                }

                // 2. Calculate tomorrowLocalDate according to user's timezone.
                var tomorrowLocalDate = DateOnly.FromDateTime(userLocalNow.Date.AddDays(1));
                var tomorrowLocalDateStr = tomorrowLocalDate.ToString("yyyy-MM-dd");

                // 3. Get the topics already scheduled for tomorrowLocalDate (bypass if sendImmediately)
                var scheduledTopics = sendImmediately 
                    ? new List<string>() 
                    : await _messageRepository.GetScheduledTopicsForDateAsync(dueUser.UserId, tomorrowLocalDateStr, cancellationToken);
                _logger.LogInformation("User {UserId} has scheduled topics for tomorrow {Date}: [{Topics}]", dueUser.UserId, tomorrowLocalDateStr, string.Join(", ", scheduledTopics));

                // 4. Fetch context from IAM
                var iamContext = await _iamClient.GetContextAsync(dueUser.UserId, cancellationToken);
                if (iamContext == null)
                {
                    _logger.LogWarning("User profile context not found in IAM for user {UserId}. Skipping.", dueUser.UserId);
                    continue;
                }

                // 5. Fetch activity from Roadmap
                var roadmapActivity = await _roadmapClient.GetTodayActivityAsync(dueUser.UserId, tzId, cancellationToken);

                // 6. Fetch nutrition from Nutrition
                var todayLocalDateStr = userLocalNow.ToString("yyyy-MM-dd");
                TodayNutritionDto? nutrition = null;
                try
                {
                    nutrition = await _nutritionClient.GetTodayNutritionAsync(dueUser.UserId, todayLocalDateStr, cancellationToken);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to retrieve today nutrition summary for user {UserId}. Using default.", dueUser.UserId);
                }

                nutrition ??= new TodayNutritionDto(
                    UserId: dueUser.UserId,
                    Date: DateOnly.FromDateTime(userLocalNow.Date),
                    TargetCalories: 0,
                    ConsumedCalories: 0,
                    TargetProteinGram: 0,
                    ConsumedProteinGram: 0,
                    TargetCarbGram: 0,
                    ConsumedCarbGram: 0,
                    TargetFatGram: 0,
                    ConsumedFatGram: 0,
                    WaterIntakeMl: 0,
                    MealsLoggedCount: 0
                );

                // 7. Merge contexts
                var context = new SmartPushContextDto(
                    UserId: iamContext.UserId,
                    FullName: iamContext.FullName,
                    BurnoutRiskScore: iamContext.BurnoutRiskScore,
                    CurrentStreak: iamContext.CurrentStreak,
                    LongestStreak: iamContext.LongestStreak,
                    CurrentLevel: iamContext.CurrentLevel,
                    CurrentXP: iamContext.CurrentXP,
                    MotivationStyle: iamContext.MotivationStyle,
                    FitnessGoal: iamContext.FitnessGoal,
                    ActivityLevel: iamContext.ActivityLevel,
                    FitnessExperienceLevel: iamContext.FitnessExperienceLevel,
                    WorkoutLocationPreference: iamContext.WorkoutLocationPreference,
                    SmartPushEnabled: iamContext.SmartPushEnabled,
                    AllowAiGeneratedNotification: iamContext.AllowAiGeneratedNotification,
                    TimeZoneId: iamContext.TimeZoneId,
                    AgentPersona: iamContext.AgentPersona,
                    HasWorkoutScheduledToday: roadmapActivity?.HasWorkoutScheduledToday ?? false,
                    TodayWorkoutName: roadmapActivity?.TodayWorkoutName,
                    HasStartedWorkoutToday: roadmapActivity?.HasStartedWorkoutToday ?? false,
                    CompletedWorkoutToday: roadmapActivity?.CompletedWorkoutToday ?? false,
                    LatestStartedAt: roadmapActivity?.LatestStartedAt,
                    LatestCompletedAt: roadmapActivity?.LatestCompletedAt,
                    ActualDurationMinutes: roadmapActivity?.ActualDurationMinutes ?? 0,
                    CompletionRate: roadmapActivity?.CompletionRate ?? 0,
                    PerceivedDifficulty: roadmapActivity?.PerceivedDifficulty ?? 0,
                    EnergyLevelBefore: roadmapActivity?.EnergyLevelBefore ?? 0,
                    EnergyLevelAfter: roadmapActivity?.EnergyLevelAfter ?? 0,
                    CaloriesBurned: roadmapActivity?.CaloriesBurned ?? 0,
                    SkippedExercisesCount: roadmapActivity?.SkippedExercisesCount ?? 0,
                    SubscriptionTier: iamContext.SubscriptionTier,
                    HasWorkoutScheduledTomorrow: roadmapActivity?.HasWorkoutScheduledTomorrow ?? false,
                    TomorrowWorkoutName: roadmapActivity?.TomorrowWorkoutName,
                    TomorrowExerciseNames: roadmapActivity?.TomorrowExerciseNames ?? new List<string>(),
                    TodayWorkoutAiCoachFeedback: roadmapActivity?.TodayWorkoutAiCoachFeedback,
                    TodayWorkoutSessionFeedback: roadmapActivity?.TodayWorkoutSessionFeedback,
                    NutritionTargetCalories: nutrition.TargetCalories,
                    NutritionConsumedCalories: nutrition.ConsumedCalories,
                    NutritionTargetProtein: nutrition.TargetProteinGram,
                    NutritionConsumedProtein: nutrition.ConsumedProteinGram,
                    NutritionTargetCarbs: nutrition.TargetCarbGram,
                    NutritionConsumedCarbs: nutrition.ConsumedCarbGram,
                    NutritionTargetFat: nutrition.TargetFatGram,
                    NutritionConsumedFat: nutrition.ConsumedFatGram,
                    NutritionWaterIntakeMl: nutrition.WaterIntakeMl,
                    NutritionMealsLoggedCount: nutrition.MealsLoggedCount
                );

                // 8. Evaluate 3 topics: streak, exercise, nutrition
                var topics = new[] { "streak", "exercise", "nutrition" };
                foreach (var topic in topics)
                {
                    // If already scheduled for tomorrow, skip
                    if (scheduledTopics.Contains(topic, StringComparer.OrdinalIgnoreCase))
                    {
                        _logger.LogInformation("Topic {Topic} already scheduled for tomorrow for user {UserId}. Skipping.", topic, dueUser.UserId);
                        continue;
                    }

                    var decision = _decisionService.Decide(context, topic);
                    if (!decision.ShouldSend)
                    {
                        _logger.LogInformation("Decision engine resolved to SKIP topic {Topic} for user {UserId}. Reason: {Reason}", topic, dueUser.UserId, decision.Reason);
                        continue;
                    }

                    // Set ScheduledForUtc based on local tomorrow time milestones (bypass if sendImmediately)
                    DateTimeOffset? scheduledForUtc = null;
                    DateTime? tomorrowDateTimeLocal = null;

                    if (!sendImmediately)
                    {
                        var timeOfDay = topic.ToLowerInvariant() switch
                        {
                            "streak" => new TimeSpan(8, 30, 0),
                            "exercise" => new TimeSpan(12, 30, 0),
                            "nutrition" => new TimeSpan(18, 30, 0),
                            _ => new TimeSpan(12, 0, 0)
                        };

                        var dtLocal = userLocalNow.Date.AddDays(1).Add(timeOfDay);
                        tomorrowDateTimeLocal = dtLocal;
                        var offset = userTz.GetUtcOffset(dtLocal);
                        scheduledForUtc = new DateTimeOffset(dtLocal, offset);
                    }

                    var deepLink = _deepLinkResolver.ResolveDeepLink(context, decision);

                    _logger.LogInformation("Decision engine resolved to SCHEDULE/SEND topic {Topic} for user {UserId} at {ScheduledForUtc} (local {TomorrowDateTimeLocal}). TriggerType={TriggerType}, DeepLink={DeepLink}",
                        topic, dueUser.UserId, scheduledForUtc, tomorrowDateTimeLocal, decision.TriggerType, deepLink);

                    // Generate Message via DeepSeek or Fallback templates
                    GeneratedPushMessageDto generated;
                    bool isAiGenerated = false;
                    var shouldUseAi = _aiUsagePolicy.ShouldUseAi(context, decision);

                    if (shouldUseAi)
                    {
                        try
                        {
                            generated = await _deepSeekClient.GenerateAsync(context, decision, deepLink, cancellationToken);
                            isAiGenerated = true;
                            _logger.LogInformation("Successfully generated push message via DeepSeek for user {UserId} topic {Topic}.", dueUser.UserId, topic);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, "DeepSeek generation failed for user {UserId} topic {Topic}. Falling back to templates.", dueUser.UserId, topic);
                            generated = _templateService.BuildMessage(context, decision, deepLink);
                        }
                    }
                    else
                    {
                        generated = _templateService.BuildMessage(context, decision, deepLink);
                    }

                    var dataPayload = new Dictionary<string, object?>
                    {
                        { "source", "SmartPushNotificationEngine" },
                        { "generatedBy", isAiGenerated ? "DeepSeek" : "Template" },
                        { "aiGenerated", isAiGenerated },
                        { "triggerType", decision.TriggerType },
                        { "topic", topic },
                        { "deepLink", deepLink }
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
                        AiContextSnapshotJson = isAiGenerated ? JsonSerializer.Serialize(context) : null,
                        ScheduledFor = scheduledForUtc
                    };

                    // Creates in DB with Pending status since ScheduledFor is in the future
                    var msgDto = await _notificationService.SendNotificationAsync(sendDto, cancellationToken);

                    // Atomically populate custom fields: SmartPushTopic, SmartPushDecisionCode, UserLocalDate
                    var entity = await _messageRepository.GetByIdAsync(msgDto.Id, cancellationToken);
                    if (entity != null)
                    {
                        entity.SmartPushTopic = topic;
                        entity.SmartPushDecisionCode = decision.TriggerType;
                        entity.UserLocalDate = tomorrowLocalDateStr;
                        await _messageRepository.UpdateAsync(entity.Id, entity, cancellationToken);
                        _logger.LogInformation("Successfully scheduled and stored Pending Smart Push Notification to user {UserId} for topic {Topic}.", dueUser.UserId, topic);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while planning Smart Push Notification for user {UserId}", dueUser.UserId);
            }
        }
    }
}
