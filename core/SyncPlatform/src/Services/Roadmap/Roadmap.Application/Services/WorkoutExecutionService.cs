using Libs.Shared.Enums;
using Roadmap.Application.DTOs;
using Roadmap.Application.Exceptions;
using Roadmap.Application.Mappers;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Application.Services;

public class WorkoutExecutionService : IWorkoutExecutionService
{
    private readonly IRoadmapSessionRepository _sessionRepository;
    private readonly IWorkoutExecutionLogRepository _executionLogRepository;
    private readonly IExerciseSetLogRepository _setLogRepository;
    private readonly IScheduledWorkoutRepository _scheduledWorkoutRepository;
    private readonly IPersonalizedRoadmapRepository _personalizedRoadmapRepository;
    private readonly IUserCustomWorkoutRepository _customWorkoutRepository;

    public WorkoutExecutionService(
        IRoadmapSessionRepository sessionRepository,
        IWorkoutExecutionLogRepository executionLogRepository,
        IExerciseSetLogRepository setLogRepository,
        IScheduledWorkoutRepository scheduledWorkoutRepository,
        IPersonalizedRoadmapRepository personalizedRoadmapRepository,
        IUserCustomWorkoutRepository customWorkoutRepository)
    {
        _sessionRepository = sessionRepository;
        _executionLogRepository = executionLogRepository;
        _setLogRepository = setLogRepository;
        _scheduledWorkoutRepository = scheduledWorkoutRepository;
        _personalizedRoadmapRepository = personalizedRoadmapRepository;
        _customWorkoutRepository = customWorkoutRepository;
    }

    public async Task<WorkoutExecutionResultDto> SubmitExecutionAsync(
        Guid sessionId,
        SubmitWorkoutExecutionDto dto,
        CancellationToken cancellationToken = default)
    {
        // 1. Validate session exists
        var session = await _sessionRepository.GetByIdAsync(sessionId, cancellationToken)
            ?? throw new NotFoundException(nameof(RoadmapSession), sessionId);

        if (session.SessionStatus == SessionStatus.Completed)
            throw new ConflictException($"Session '{sessionId}' has already been completed.");

        if (dto.UserId == Guid.Empty)
            throw new BadRequestException("UserId is required.");

        if (dto.StartedAt == default)
            throw new BadRequestException("StartedAt is required.");

        // 2. Compute derived fields
        var completedAt = dto.CompletedAt ?? DateTimeOffset.UtcNow;
        var actualDurationMinutes = (int)(completedAt - dto.StartedAt).TotalMinutes;

        var totalExercises = session.ExecutionBlocks
            .Select(b => b.ExerciseId)
            .Distinct()
            .Count();

        var skippedCount = dto.SkippedExercises.Distinct().Count();
        var completionRate = totalExercises > 0
            ? (int)Math.Round((totalExercises - skippedCount) / (double)totalExercises * 100)
            : 100;

        // 3. Create WorkoutExecutionLog
        var executionLog = new WorkoutExecutionLog
        {
            UserId = dto.UserId,
            SessionId = sessionId,
            StartedAt = dto.StartedAt,
            CompletedAt = completedAt,
            ActualDurationMinutes = actualDurationMinutes,
            PerceivedDifficulty = dto.PerceivedDifficulty,
            EnergyLevelBefore = dto.EnergyLevelBefore,
            EnergyLevelAfter = dto.EnergyLevelAfter,
            CaloriesBurned = dto.CaloriesBurned,
            CompletionRate = completionRate,
            SessionFeedback = dto.SessionFeedback,
            SkippedExercises = dto.SkippedExercises.Distinct().ToList()
        };
        await _executionLogRepository.CreateAsync(executionLog, cancellationToken);

        // 4. Create ExerciseSetLog records (bulk)
        var setLogs = dto.SetsPerformed.Select(s => new ExerciseSetLog
        {
            ExecutionId = executionLog.Id,
            ExerciseId = s.ExerciseId,
            SetNumber = s.SetNumber,
            TargetReps = s.TargetReps,
            ActualReps = s.ActualReps,
            WeightKg = s.WeightKg,
            Rir = s.Rir,
            RestTakenSeconds = s.RestTakenSeconds,
            FormScore = s.FormScore,
            Completed = s.ActualReps > 0
        }).ToList();

        if (setLogs.Count > 0)
            await _setLogRepository.CreateManyAsync(setLogs, cancellationToken);

        // 5. Update session status to Completed
        await _sessionRepository.UpdateStatusAsync(sessionId, SessionStatus.Completed, cancellationToken);

        return executionLog.ToResultDto(setLogs);
    }

    private async Task ValidateSessionOwnerAsync(Guid userId, RoadmapSession session, CancellationToken cancellationToken)
    {
        var personalizedRoadmap = await _personalizedRoadmapRepository.GetByIdAsync(session.RoadmapId, cancellationToken);
        if (personalizedRoadmap != null)
        {
            if (personalizedRoadmap.UserId != userId)
                throw new ForbiddenException("You do not own this session.");
            return;
        }

        var customWorkout = await _customWorkoutRepository.GetByIdAsync(session.RoadmapId, cancellationToken);
        if (customWorkout != null)
        {
            if (customWorkout.UserId != userId)
                throw new ForbiddenException("You do not own this session.");
            return;
        }

        throw new BadRequestException("The session does not belong to any valid roadmap.");
    }

    public async Task<WorkoutExecutionDetailDto> StartWorkoutAsync(
        Guid userId,
        StartWorkoutExecutionDto request,
        CancellationToken cancellationToken = default)
    {
        // 1. Fetch RoadmapSession
        var session = await _sessionRepository.GetByIdAsync(request.SessionId, cancellationToken)
            ?? throw new NotFoundException(nameof(RoadmapSession), request.SessionId);

        // 2. Validate Session Ownership
        await ValidateSessionOwnerAsync(userId, session, cancellationToken);

        // 3. Validate ExecutionBlocks
        if (session.ExecutionBlocks == null || session.ExecutionBlocks.Count == 0)
        {
            throw new BadRequestException("RoadmapSession has no execution blocks/exercises configured.");
        }

        var validBlocks = session.ExecutionBlocks.Where(b => b.TargetSets > 0).ToList();
        if (validBlocks.Count == 0)
        {
            throw new BadRequestException("The session must have at least one exercise block with TargetSets > 0.");
        }

        // 4. Prevent duplicate active executions
        var activeExecution = await _executionLogRepository.GetActiveExecutionAsync(userId, request.SessionId, cancellationToken);
        if (activeExecution != null)
        {
            var activeSets = await _setLogRepository.GetByExecutionIdAsync(activeExecution.Id, cancellationToken);
            return activeExecution.ToDetailDto(session, activeSets);
        }

        // 5. Create WorkoutExecutionLog
        var execution = new WorkoutExecutionLog
        {
            UserId = userId,
            SessionId = request.SessionId,
            StartedAt = DateTimeOffset.UtcNow,
            CompletedAt = null,
            ActualDurationMinutes = 0,
            PerceivedDifficulty = 0,
            EnergyLevelBefore = request.EnergyLevelBefore ?? 0,
            EnergyLevelAfter = 0,
            CaloriesBurned = 0,
            CompletionRate = 0,
            SkippedExercises = [],
            AiCoachFeedback = null,
            SessionFeedback = null
        };
        await _executionLogRepository.CreateAsync(execution, cancellationToken);

        // 6. Pre-create ExerciseSetLog rows (Disabled under Option 2: On-the-fly Set Creation)
        var setLogs = new List<ExerciseSetLog>();

        // 7. Update RoadmapSession status
        await _sessionRepository.UpdateStatusAsync(request.SessionId, SessionStatus.InProgress, cancellationToken);

        // 8. Update nearest pending ScheduledWorkout status
        var schedules = await _scheduledWorkoutRepository.GetBySessionIdsAsync(new[] { request.SessionId }, cancellationToken);
        var pendingSchedule = schedules
            .Where(s => s.Status == SessionStatus.Scheduled || s.Status == SessionStatus.InProgress)
            .OrderBy(s => Math.Abs((s.ScheduledStartTime - DateTimeOffset.UtcNow).Ticks))
            .FirstOrDefault();
        if (pendingSchedule != null)
        {
            pendingSchedule.Status = SessionStatus.InProgress;
            await _scheduledWorkoutRepository.UpdateAsync(pendingSchedule.Id, pendingSchedule, cancellationToken);
        }

        return execution.ToDetailDto(session, setLogs);
    }

    public async Task<WorkoutExecutionDetailDto> GetWorkoutExecutionDetailAsync(
        Guid userId,
        Guid executionId,
        CancellationToken cancellationToken = default)
    {
        var log = await _executionLogRepository.GetByIdAsync(executionId, cancellationToken)
            ?? throw new NotFoundException(nameof(WorkoutExecutionLog), executionId);

        if (log.UserId != userId)
            throw new ForbiddenException("You do not own this workout execution.");

        var session = await _sessionRepository.GetByIdAsync(log.SessionId, cancellationToken)
            ?? throw new NotFoundException(nameof(RoadmapSession), log.SessionId);

        var setLogs = await _setLogRepository.GetByExecutionIdAsync(executionId, cancellationToken);

        return log.ToDetailDto(session, setLogs);
    }

    public async Task<WorkoutExecutionSummaryDto> FinishWorkoutAsync(
        Guid userId,
        Guid executionId,
        FinishWorkoutExecutionDto request,
        CancellationToken cancellationToken = default)
    {
        // 1. Fetch Execution Log and Validate Ownership
        var log = await _executionLogRepository.GetByIdAsync(executionId, cancellationToken)
            ?? throw new NotFoundException(nameof(WorkoutExecutionLog), executionId);

        if (log.UserId != userId)
            throw new ForbiddenException("You do not own this workout execution.");

        // 2. Fetch all set logs
        var setLogs = await _setLogRepository.GetByExecutionIdAsync(executionId, cancellationToken);

        // 3. Fetch RoadmapSession
        var session = await _sessionRepository.GetByIdAsync(log.SessionId, cancellationToken)
            ?? throw new NotFoundException(nameof(RoadmapSession), log.SessionId);

        // 4. Compute derived fields
        var completedAt = DateTimeOffset.UtcNow;
        var actualDurationMinutes = (int)(completedAt - log.StartedAt).TotalMinutes;

        var totalSets = session.ExecutionBlocks.Sum(b => b.TargetSets);
        var completedSets = setLogs.Count(x => x.Completed);
        var completionRate = totalSets == 0 ? 0.0 : Math.Round((double)completedSets / totalSets * 100, 2);

        var allExerciseIds = session.ExecutionBlocks.Select(b => b.ExerciseId).Distinct().ToList();
        var completedExerciseIds = setLogs.Where(x => x.Completed).Select(x => x.ExerciseId).Distinct().ToList();
        var skippedExercises = allExerciseIds.Except(completedExerciseIds).ToList();

        // 5. Update Execution Log properties
        log.CompletedAt = completedAt;
        log.ActualDurationMinutes = actualDurationMinutes;
        log.CompletionRate = (int)completionRate; // Convert double to int for Entity field
        log.SkippedExercises = skippedExercises;
        log.PerceivedDifficulty = request.PerceivedDifficulty ?? 0;
        log.EnergyLevelAfter = request.EnergyLevelAfter ?? 0;
        log.SessionFeedback = request.SessionFeedback;
        log.AiCoachFeedback = GenerateFeedback(completionRate, skippedExercises.Count);

        // Estimate calories burned (e.g. 5 kcal/minute base, scaled by perceived difficulty and completed sets)
        var difficultyMultiplier = 1.0 + (request.PerceivedDifficulty ?? 0) / 10.0;
        var baseBurnRate = 5.0; // kcal/min
        var estimatedCalories = actualDurationMinutes * baseBurnRate * difficultyMultiplier;
        estimatedCalories += completedSets * 10; // Extra 10 kcal per completed set
        log.CaloriesBurned = (int)Math.Round(estimatedCalories);

        await _executionLogRepository.UpdateAsync(executionId, log, cancellationToken);

        // 6. Update RoadmapSession status
        var nextSessionStatus = completionRate == 0 ? SessionStatus.Skipped : SessionStatus.Completed;
        await _sessionRepository.UpdateStatusAsync(log.SessionId, nextSessionStatus, cancellationToken);

        // 7. Update nearest pending ScheduledWorkout status
        var schedules = await _scheduledWorkoutRepository.GetBySessionIdsAsync(new[] { log.SessionId }, cancellationToken);
        var pendingSchedule = schedules
            .Where(s => s.Status == SessionStatus.Scheduled || s.Status == SessionStatus.InProgress)
            .OrderBy(s => Math.Abs((s.ScheduledStartTime - DateTimeOffset.UtcNow).Ticks))
            .FirstOrDefault();
        if (pendingSchedule != null)
        {
            pendingSchedule.Status = nextSessionStatus;
            await _scheduledWorkoutRepository.UpdateAsync(pendingSchedule.Id, pendingSchedule, cancellationToken);
        }

        return log.ToSummaryDto(session.SessionTitle, completedSets, totalSets);
    }

    public async Task CancelWorkoutAsync(
        Guid userId,
        Guid executionId,
        CancellationToken cancellationToken = default)
    {
        // 1. Fetch Execution Log and Validate Ownership
        var log = await _executionLogRepository.GetByIdAsync(executionId, cancellationToken)
            ?? throw new NotFoundException(nameof(WorkoutExecutionLog), executionId);

        if (log.UserId != userId)
            throw new ForbiddenException("You do not own this workout execution.");

        // 2. Delete the execution and pre-created set logs
        await _setLogRepository.DeleteManyByExecutionIdAsync(executionId, cancellationToken);
        await _executionLogRepository.DeleteAsync(executionId, cancellationToken);

        // 3. Revert RoadmapSession status to Scheduled
        await _sessionRepository.UpdateStatusAsync(log.SessionId, SessionStatus.Scheduled, cancellationToken);

        // 4. Revert nearest InProgress/current ScheduledWorkout status back to Scheduled
        var schedules = await _scheduledWorkoutRepository.GetBySessionIdsAsync(new[] { log.SessionId }, cancellationToken);
        var inProgressSchedule = schedules
            .Where(s => s.Status == SessionStatus.InProgress)
            .OrderBy(s => Math.Abs((s.ScheduledStartTime - DateTimeOffset.UtcNow).Ticks))
            .FirstOrDefault();
        if (inProgressSchedule != null)
        {
            inProgressSchedule.Status = SessionStatus.Scheduled;
            await _scheduledWorkoutRepository.UpdateAsync(inProgressSchedule.Id, inProgressSchedule, cancellationToken);
        }
    }

    private string GenerateFeedback(double completionRate, int skippedCount)
    {
        if (completionRate >= 90)
            return "Bạn hoàn thành rất tốt buổi tập hôm nay. Hãy duy trì phong độ này cho buổi sau.";
        if (completionRate >= 60)
            return $"Bạn hoàn thành {completionRate}% buổi tập. Có thể cải thiện thêm ở các set cuối.";
        if (completionRate > 0)
            return $"Bạn chỉ hoàn thành {completionRate}% buổi tập. Hãy nghỉ ngơi đủ và thử giảm cường độ ở buổi sau.";
        return "Bạn chưa hoàn thành set nào trong buổi tập này. Hãy thử lại khi cơ thể sẵn sàng hơn.";
    }
}
