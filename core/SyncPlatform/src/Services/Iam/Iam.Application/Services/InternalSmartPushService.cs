using Iam.Application.DTOs;
using Iam.Domain.Repositories;
using Microsoft.Extensions.Logging;

namespace Iam.Application.Services;

public class InternalSmartPushService : IInternalSmartPushService
{
    private readonly IInternalSmartPushRepository _repository;
    private readonly ILogger<InternalSmartPushService> _logger;

    public InternalSmartPushService(
        IInternalSmartPushRepository repository,
        ILogger<InternalSmartPushService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<IReadOnlyList<DueSmartPushUserDto>> GetDueUsersAsync(DateTime utcNow, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Getting due smart push users for UTC time {UtcNow}", utcNow);

        var users = await _repository.GetUsersForSmartPushAsync(cancellationToken);
        var dueUsers = new List<DueSmartPushUserDto>();

        foreach (var user in users)
        {
            if (user.UserPreference == null)
                continue;

            var preferredTime = user.UserPreference.PreferredReminderTime;
            if (preferredTime == null)
                continue;

            var tzId = string.IsNullOrWhiteSpace(user.TimeZone) ? "Asia/Ho_Chi_Minh" : user.TimeZone;
            TimeZoneInfo userTz;
            try
            {
                userTz = TimeZoneInfo.FindSystemTimeZoneById(tzId);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to load timezone '{TimeZoneId}' for user {UserId}. Falling back to Asia/Ho_Chi_Minh.", tzId, user.Id);
                tzId = "Asia/Ho_Chi_Minh";
                userTz = TimeZoneInfo.FindSystemTimeZoneById(tzId);
            }

            var userLocalTime = TimeZoneInfo.ConvertTime(utcNow, userTz);

            if (userLocalTime.TimeOfDay >= preferredTime.Value)
            {
                dueUsers.Add(new DueSmartPushUserDto(
                    user.Id,
                    preferredTime.Value,
                    tzId,
                    user.UserPreference.MotivationStyle.ToString()
                ));
            }
        }

        _logger.LogInformation("Found {DueCount} due users out of {TotalActiveCount} users with smart push enabled", dueUsers.Count, users.Count);
        return dueUsers;
    }

    public async Task<IamSmartPushContextDto?> GetSmartPushContextAsync(Guid userId, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Fetching smart push context for user {UserId}", userId);

        var user = await _repository.GetUserSmartPushContextAsync(userId, cancellationToken);
        if (user == null)
        {
            _logger.LogWarning("User {UserId} not found for smart push context query", userId);
            return null;
        }

        var pref = user.UserPreference;
        var aiProfile = user.AIContextProfile;
        var gamification = user.GamificationProfile;
        var biometric = user.BiometricProfile;

        var tzId = string.IsNullOrWhiteSpace(user.TimeZone) ? "Asia/Ho_Chi_Minh" : user.TimeZone;

        return new IamSmartPushContextDto(
            user.Id,
            user.FullName,
            aiProfile != null ? (int)aiProfile.BurnoutRiskScore : 0,
            gamification != null ? gamification.CurrentStreak : 0,
            gamification != null ? gamification.LongestStreak : 0,
            gamification != null ? gamification.CurrentLevel : 0,
            gamification != null ? gamification.CurrentXP : 0,
            pref?.MotivationStyle.ToString() ?? "Supportive",
            biometric != null ? biometric.FitnessGoal.ToString() : "Maintain",
            biometric != null ? biometric.ActivityLevel.ToString() : "Sedentary",
            biometric != null ? biometric.FitnessExperienceLevel.ToString() : "Beginner",
            biometric != null ? biometric.WorkoutLocationPreference.ToString() : "Home",
            pref?.SmartPushEnabled ?? false,
            pref?.AllowAiGeneratedNotification ?? false,
            tzId,
            pref?.AgentPersona.ToString() ?? "FriendlyBuddy",
            user.SubscriptionTier.ToString()
        );
    }
}
