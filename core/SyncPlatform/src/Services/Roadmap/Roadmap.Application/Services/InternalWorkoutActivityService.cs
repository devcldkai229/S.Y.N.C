using Libs.Shared.Enums;
using Microsoft.Extensions.Logging;
using Roadmap.Application.DTOs;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Application.Services;

public class InternalWorkoutActivityService : IInternalWorkoutActivityService
{
    private readonly IWorkoutExecutionLogRepository _workoutLogRepository;
    private readonly IScheduledWorkoutRepository _scheduledWorkoutRepository;
    private readonly IRoadmapSessionRepository _sessionRepository;
    private readonly IPersonalizedRoadmapRepository _personalizedRoadmapRepository;
    private readonly IExerciseSetLogRepository _exerciseSetLogRepository;
    private readonly ILogger<InternalWorkoutActivityService> _logger;

    public InternalWorkoutActivityService(
        IWorkoutExecutionLogRepository workoutLogRepository,
        IScheduledWorkoutRepository scheduledWorkoutRepository,
        IRoadmapSessionRepository sessionRepository,
        IPersonalizedRoadmapRepository personalizedRoadmapRepository,
        IExerciseSetLogRepository exerciseSetLogRepository,
        ILogger<InternalWorkoutActivityService> logger)
    {
        _workoutLogRepository = workoutLogRepository;
        _scheduledWorkoutRepository = scheduledWorkoutRepository;
        _sessionRepository = sessionRepository;
        _personalizedRoadmapRepository = personalizedRoadmapRepository;
        _exerciseSetLogRepository = exerciseSetLogRepository;
        _logger = logger;
    }

    public async Task<TodayWorkoutActivityDto> GetTodayWorkoutActivityAsync(Guid userId, string? timeZoneId, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Getting today's workout activity for user {UserId} with timezone {TimeZoneId}", userId, timeZoneId);

        var tzId = string.IsNullOrWhiteSpace(timeZoneId) ? "Asia/Ho_Chi_Minh" : timeZoneId;
        TimeZoneInfo userTz;
        try
        {
            userTz = TimeZoneInfo.FindSystemTimeZoneById(tzId);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to load timezone '{TimeZoneId}' for user {UserId}. Falling back to Asia/Ho_Chi_Minh.", tzId, userId);
            tzId = "Asia/Ho_Chi_Minh";
            userTz = TimeZoneInfo.FindSystemTimeZoneById(tzId);
        }

        var userLocalNow = TimeZoneInfo.ConvertTime(DateTimeOffset.UtcNow, userTz);
        var localStartOfToday = new DateTime(userLocalNow.Year, userLocalNow.Month, userLocalNow.Day, 0, 0, 0, DateTimeKind.Unspecified);
        var startOfToday = new DateTimeOffset(localStartOfToday, userTz.GetUtcOffset(localStartOfToday));
        var startOfTomorrow = startOfToday.AddDays(1);
        var lookbackStart = startOfToday.AddDays(-7);

        var roadmaps = await _personalizedRoadmapRepository.GetByUserIdAsync(userId, cancellationToken);
        var allSessions = new List<RoadmapSession>();
        foreach (var roadmap in roadmaps)
        {
            var sessions = await _sessionRepository.GetByRoadmapIdAsync(roadmap.Id, cancellationToken);
            allSessions.AddRange(sessions);
        }

        var todaySessions = allSessions
            .Where(s => s.ScheduledDate >= startOfToday && s.ScheduledDate < startOfTomorrow)
            .ToList();

        var hasRoadmapSession = todaySessions.Any(s => s.AiGenerated);
        var hasCustomSession = todaySessions.Any(s => !s.AiGenerated);
        var workoutSource = (hasRoadmapSession, hasCustomSession) switch
        {
            (true, true) => "both",
            (true, false) => "roadmap",
            (false, true) => "custom",
            _ => "none"
        };

        var primaryToday = todaySessions
            .OrderByDescending(s => s.AiGenerated ? 0 : 1) // prefer calling out custom when present
            .ThenBy(s => s.ScheduledDate)
            .FirstOrDefault();

        var hasWorkoutScheduledToday = todaySessions.Count > 0;
        var todayWorkoutName = primaryToday?.SessionTitle;
        var todayWorkoutType = primaryToday?.SessionType;
        var scheduledLocalTime = string.IsNullOrWhiteSpace(primaryToday?.ScheduledTime)
            ? null
            : primaryToday!.ScheduledTime;

        // Missed: session in past 7 days (not today) that is still Pending / not Completed
        var missedRecentCount = allSessions.Count(s =>
            s.ScheduledDate >= lookbackStart
            && s.ScheduledDate < startOfToday
            && s.SessionStatus is SessionStatus.Scheduled or SessionStatus.InProgress or SessionStatus.Skipped);

        var logs = await _workoutLogRepository.GetByUserIdAndDateRangeAsync(userId, startOfToday, startOfTomorrow, cancellationToken);

        bool hasStartedWorkoutToday = logs.Any();
        bool completedWorkoutToday = logs.Any(l => l.CompletedAt != null && l.CompletionRate >= 80);

        Guid? sessionId = null;
        DateTimeOffset? latestStartedAt = null;
        DateTimeOffset? latestCompletedAt = null;
        int actualDurationMinutes = 0;
        int completionRate = 0;
        int perceivedDifficulty = 0;
        int energyLevelBefore = 0;
        int energyLevelAfter = 0;
        int caloriesBurned = 0;
        int skippedExercisesCount = 0;
        int completedSetsCount = 0;
        int totalLoggedSetsCount = 0;

        if (hasStartedWorkoutToday)
        {
            var latestLog = logs.First();
            sessionId = latestLog.SessionId;
            latestStartedAt = latestLog.StartedAt;
            latestCompletedAt = latestLog.CompletedAt;
            actualDurationMinutes = latestLog.ActualDurationMinutes;
            completionRate = latestLog.CompletionRate;
            perceivedDifficulty = latestLog.PerceivedDifficulty;
            energyLevelBefore = latestLog.EnergyLevelBefore;
            energyLevelAfter = latestLog.EnergyLevelAfter;
            caloriesBurned = latestLog.CaloriesBurned;
            skippedExercisesCount = latestLog.SkippedExercises?.Count ?? 0;

            var setLogs = await _exerciseSetLogRepository.GetByExecutionIdAsync(latestLog.Id, cancellationToken);
            totalLoggedSetsCount = setLogs.Count;
            completedSetsCount = setLogs.Count(s => s.Completed);
        }

        return new TodayWorkoutActivityDto(
            userId,
            hasWorkoutScheduledToday,
            sessionId,
            todayWorkoutName,
            hasStartedWorkoutToday,
            completedWorkoutToday,
            latestStartedAt,
            latestCompletedAt,
            actualDurationMinutes,
            completionRate,
            perceivedDifficulty,
            energyLevelBefore,
            energyLevelAfter,
            caloriesBurned,
            skippedExercisesCount,
            completedSetsCount,
            totalLoggedSetsCount,
            workoutSource,
            todayWorkoutType,
            scheduledLocalTime,
            missedRecentCount
        );
    }
}
