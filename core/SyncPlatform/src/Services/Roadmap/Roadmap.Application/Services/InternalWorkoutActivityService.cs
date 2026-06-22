using Libs.Shared.Enums;
using Microsoft.Extensions.Logging;
using Roadmap.Application.DTOs;
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

        // Get the current local time of the user based on current UTC
        var userLocalNow = TimeZoneInfo.ConvertTime(DateTimeOffset.UtcNow, userTz);

        // Start of today in user's local time
        var localStartOfToday = new DateTime(userLocalNow.Year, userLocalNow.Month, userLocalNow.Day, 0, 0, 0, DateTimeKind.Unspecified);
        var startOfToday = new DateTimeOffset(localStartOfToday, userTz.GetUtcOffset(localStartOfToday));
        var startOfTomorrow = startOfToday.AddDays(1);

        _logger.LogInformation("Determined user's local day range: {StartOfToday} to {StartOfTomorrow} (Offset: {Offset})", 
            startOfToday, startOfTomorrow, userTz.GetUtcOffset(localStartOfToday));

        // 1. Scheduled Workout Info (using RoadmapSession only, via PersonalizedRoadmap mapping)
        bool hasWorkoutScheduledToday = false;
        string? todayWorkoutName = null;
        bool hasWorkoutScheduledTomorrow = false;
        string? tomorrowWorkoutName = null;
        List<string> tomorrowExerciseNames = new();

        var roadmaps = await _personalizedRoadmapRepository.GetByUserIdAsync(userId, cancellationToken);
        var activeRoadmap = roadmaps.FirstOrDefault(r => r.RoadmapStatus == RoadmapStatus.Active) ?? roadmaps.FirstOrDefault();

        if (activeRoadmap != null)
        {
            var sessions = await _sessionRepository.GetByRoadmapIdAsync(activeRoadmap.Id, cancellationToken);
            var todaySession = sessions.FirstOrDefault(s => s.ScheduledDate >= startOfToday && s.ScheduledDate < startOfTomorrow);

            if (todaySession != null)
            {
                hasWorkoutScheduledToday = true;
                todayWorkoutName = todaySession.SessionTitle;
                _logger.LogInformation("Found scheduled session today: {SessionTitle} (RoadmapId={RoadmapId})", todayWorkoutName, activeRoadmap.Id);
            }

            var tomorrowSession = sessions.FirstOrDefault(s => s.ScheduledDate >= startOfTomorrow && s.ScheduledDate < startOfTomorrow.AddDays(1));
            if (tomorrowSession != null)
            {
                hasWorkoutScheduledTomorrow = true;
                tomorrowWorkoutName = tomorrowSession.SessionTitle;
                tomorrowExerciseNames = tomorrowSession.ExecutionBlocks.Select(eb => eb.ExerciseName).ToList();
                _logger.LogInformation("Found scheduled session tomorrow: {SessionTitle} (RoadmapId={RoadmapId})", tomorrowWorkoutName, activeRoadmap.Id);
            }
        }
        else
        {
            _logger.LogInformation("No personalized roadmap found for user {UserId}", userId);
        }

        // 2. Workout Execution Logs Info
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
        string? todayWorkoutAiCoachFeedback = null;
        string? todayWorkoutSessionFeedback = null;

        if (hasStartedWorkoutToday)
        {
            // First item is the latest sorted by StartedAt descending
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
            todayWorkoutAiCoachFeedback = latestLog.AiCoachFeedback;
            todayWorkoutSessionFeedback = latestLog.SessionFeedback;

            // Query ExerciseSetLog for extra details
            var setLogs = await _exerciseSetLogRepository.GetByExecutionIdAsync(latestLog.Id, cancellationToken);
            totalLoggedSetsCount = setLogs.Count;
            completedSetsCount = setLogs.Count(s => s.Completed);

            _logger.LogInformation("Latest execution log details: Id={ExecutionId}, TotalSets={TotalSets}, CompletedSets={CompletedSets}", 
                latestLog.Id, totalLoggedSetsCount, completedSetsCount);
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
            hasWorkoutScheduledTomorrow,
            tomorrowWorkoutName,
            tomorrowExerciseNames,
            todayWorkoutAiCoachFeedback,
            todayWorkoutSessionFeedback
        );
    }
}
