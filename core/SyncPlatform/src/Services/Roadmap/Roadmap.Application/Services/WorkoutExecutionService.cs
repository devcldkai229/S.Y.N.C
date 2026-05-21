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

    public WorkoutExecutionService(
        IRoadmapSessionRepository sessionRepository,
        IWorkoutExecutionLogRepository executionLogRepository,
        IExerciseSetLogRepository setLogRepository)
    {
        _sessionRepository = sessionRepository;
        _executionLogRepository = executionLogRepository;
        _setLogRepository = setLogRepository;
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
}
