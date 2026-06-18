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
        _decisionService = decisionService;
        _deepSeekClient = deepSeekClient;
        _aiUsagePolicy = aiUsagePolicy;
        _deepLinkResolver = deepLinkResolver;
        _templateService = templateService;
        _notificationService = notificationService;
        _messageRepository = messageRepository;
        _logger = logger;
    }

    public async Task ProcessDueUsersAsync(DateTime utcNow, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Processing due smart push users for UTC time {UtcNow}", utcNow);

        IReadOnlyList<DueSmartPushUserDto> dueUsers;
        try
        {
            dueUsers = await _iamClient.GetDueUsersAsync(utcNow, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch due users from IAM Service.");
            return;
        }

        _logger.LogInformation("Found {Count} due users from IAM Service.", dueUsers.Count);

        foreach (var dueUser in dueUsers)
        {
            try
            {
                _logger.LogInformation("Processing due user {UserId} in timezone {TimeZoneId}", dueUser.UserId, dueUser.TimeZoneId);

                // 1. Duplicate send check
                var alreadySent = await _messageRepository.HasSmartPushSentTodayAsync(
                dueUser.UserId,
                utcNow,
                dueUser.TimeZoneId,
                cancellationToken);

                if (alreadySent)
                {
                    _logger.LogInformation("User {UserId} has already received a Smart Push notification today. Skipping.", dueUser.UserId);
                    continue;
                }

                // 2. Fetch context from IAM
                var iamContext = await _iamClient.GetContextAsync(dueUser.UserId, cancellationToken);
                if (iamContext == null)
                {
                    _logger.LogWarning("User profile context not found in IAM for user {UserId}. Skipping.", dueUser.UserId);
                    continue;
                }

                // 3. Fetch activity from Roadmap
                var roadmapActivity = await _roadmapClient.GetTodayActivityAsync(
                    dueUser.UserId, 
                    iamContext.TimeZoneId, 
                    cancellationToken);

                if (roadmapActivity == null)
                {
                    _logger.LogInformation("No workout activity returned from Roadmap today for user {UserId}. Using default activity context.", dueUser.UserId);
                }

                // 4. Merge contexts
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
                    SubscriptionTier: iamContext.SubscriptionTier
                );

                // 5. Evaluate decision
                var decision = _decisionService.Decide(context);
                if (!decision.ShouldSend)
                {
                    _logger.LogInformation("Decision engine resolved to SKIP sending for user {UserId}. Reason: {Reason}", dueUser.UserId, decision.Reason);
                    continue;
                }

                // 5b. Resolve deep link on backend
                var deepLink = _deepLinkResolver.ResolveDeepLink(context, decision);

                _logger.LogInformation("Decision engine resolved to SEND for user {UserId}. TriggerType={TriggerType}, DeepLink={DeepLink}", 
                    dueUser.UserId, decision.TriggerType, deepLink);

                // 6. Generate Message via DeepSeek or Fallback templates
                GeneratedPushMessageDto generated;
                bool isAiGenerated = false;
                var shouldUseAi = _aiUsagePolicy.ShouldUseAi(context, decision);

                if (shouldUseAi)
                {
                    try
                      {
                        generated = await _deepSeekClient.GenerateAsync(context, decision, deepLink, cancellationToken);
                        isAiGenerated = true;
                        _logger.LogInformation("Successfully generated push message via DeepSeek for user {UserId}. TriggerType={TriggerType}, DeepLink={DeepLink}", dueUser.UserId, decision.TriggerType, deepLink);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "DeepSeek generation failed for user {UserId}. Falling back to default Vietnamese message templates. Reason: {Message}", dueUser.UserId, ex.Message);
                        generated = _templateService.BuildMessage(context, decision, deepLink);
                    }
                }
                else
                {
                    _logger.LogInformation("SmartPush AI Usage Policy resolved to USE TEMPLATE for user {UserId}. TriggerType={TriggerType}, DeepLink={DeepLink}", dueUser.UserId, decision.TriggerType, deepLink);
                    generated = _templateService.BuildMessage(context, decision, deepLink);
                }

                // 7. Send the notification
                var dataPayload = new Dictionary<string, object?>
                {
                    { "source", "SmartPushNotificationEngine" },
                    { "generatedBy", isAiGenerated ? "DeepSeek" : "Template" },
                    { "aiGenerated", isAiGenerated },
                    { "triggerType", decision.TriggerType },
                    { "model", isAiGenerated ? "deepseek-chat" : null },
                    { "deepLink", deepLink },
                    { "currentStreak", context.CurrentStreak },
                    { "burnoutRiskScore", context.BurnoutRiskScore },
                    { "completionRate", context.CompletionRate }
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
                    AiContextSnapshotJson = isAiGenerated ? JsonSerializer.Serialize(context) : null
                };

                var message = await _notificationService.SendNotificationAsync(sendDto, cancellationToken);
                _logger.LogInformation("Successfully sent Smart Push Notification to user {UserId}. MessageId={MessageId}", dueUser.UserId, message.Id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while processing Smart Push Notification for user {UserId}", dueUser.UserId);
            }
        }
    }
}
