using Libs.Shared.Enums;
using Roadmap.Application.DTOs;
using Roadmap.Application.Exceptions;
using Roadmap.Application.Mappers;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Application.Services;

public class RoadmapSessionService : IRoadmapSessionService
{
    private readonly IRoadmapSessionRepository _sessionRepository;
    private readonly IScheduledWorkoutRepository _scheduledWorkoutRepository;
    private readonly IUserCustomWorkoutRepository _customWorkoutRepository;

    public RoadmapSessionService(
        IRoadmapSessionRepository sessionRepository,
        IScheduledWorkoutRepository scheduledWorkoutRepository,
        IUserCustomWorkoutRepository customWorkoutRepository)
    {
        _sessionRepository = sessionRepository;
        _scheduledWorkoutRepository = scheduledWorkoutRepository;
        _customWorkoutRepository = customWorkoutRepository;
    }

    // ── AI Flow ──────────────────────────────────────────────────────────────

    public async Task<ScheduledSessionResultDto> ScheduleAsync(
        ScheduleSessionDto dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.UserId == Guid.Empty)
            throw new BadRequestException("UserId is required.");

        if (string.IsNullOrWhiteSpace(dto.SessionTitle))
            throw new BadRequestException("SessionTitle is required.");

        if (dto.ExecutionBlocks.Count == 0)
            throw new BadRequestException("At least one execution block is required.");

        if (dto.ScheduledDate == default)
            throw new BadRequestException("ScheduledDate is required.");

        // null RoadmapId = Free Workout (no roadmap context)
        var session = new RoadmapSession { SessionStatus = SessionStatus.Scheduled };
        session.UpdateEntity(dto);

        await _sessionRepository.CreateAsync(session, cancellationToken);

        var scheduledWorkout = BuildScheduledWorkout(dto.UserId, session.Id, dto.ScheduledDate, dto.EstimatedDurationMinutes);
        await _scheduledWorkoutRepository.CreateAsync(scheduledWorkout, cancellationToken);

        return new ScheduledSessionResultDto
        {
            Session = session.ToDto(),
            ScheduledWorkout = scheduledWorkout.ToDto()
        };
    }

    // ── Custom Flow ──────────────────────────────────────────────────────────

    public async Task<ScheduledSessionResultDto> ScheduleFromCustomWorkoutAsync(
        Guid customWorkoutId,
        ScheduleFromCustomWorkoutDto dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.UserId == Guid.Empty)
            throw new BadRequestException("UserId is required.");

        if (dto.ScheduledDate == default)
            throw new BadRequestException("ScheduledDate is required.");

        // 1. Load the template (immutable — never modified by this flow)
        var template = await _customWorkoutRepository.GetByIdAsync(customWorkoutId, cancellationToken)
            ?? throw new NotFoundException(nameof(UserCustomWorkout), customWorkoutId);

        // 2. Copy CustomBlocks → ExecutionBlocks (stamp current weight/reps as targets)
        var executionBlocks = template.CustomBlocks
            .Select((block, index) => new RoadmapSession.ExecutionBlock
            {
                Order = index + 1,
                ExerciseId = block.ExerciseId,
                ExerciseName = string.Empty, // enriched by client or future exercise lookup
                TargetSets = block.Sets,
                TargetReps = block.Reps,
                TargetWeightKg = block.WeightKg,
                RestSeconds = block.RestSeconds,
                Tempo = string.Empty
            })
            .ToList();

        // 3. Create RoadmapSession — RoadmapId = Guid.Empty = "Free Workout"
        var session = new RoadmapSession
        {
            RoadmapId = Guid.Empty,
            SessionTitle = template.WorkoutName,
            SessionType = dto.SessionType,
            ScheduledDate = dto.ScheduledDate,
            ScheduledTime = dto.ScheduledTime,
            Timezone = dto.Timezone,
            EstimatedDurationMinutes = dto.EstimatedDurationMinutes,
            NotificationEnabled = dto.NotificationEnabled,
            NotificationMinutesBefore = dto.NotificationMinutesBefore,
            AiGenerated = false,
            SessionStatus = SessionStatus.Scheduled,
            ExecutionBlocks = executionBlocks
        };
        await _sessionRepository.CreateAsync(session, cancellationToken);

        // 4. Create ScheduledWorkout calendar entry
        var scheduledWorkout = BuildScheduledWorkout(dto.UserId, session.Id, dto.ScheduledDate, dto.EstimatedDurationMinutes);
        await _scheduledWorkoutRepository.CreateAsync(scheduledWorkout, cancellationToken);

        return new ScheduledSessionResultDto
        {
            Session = session.ToDto(),
            ScheduledWorkout = scheduledWorkout.ToDto()
        };
    }

    // ── Queries ──────────────────────────────────────────────────────────────

    public async Task<RoadmapSessionDto> GetByIdAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var entity = await _sessionRepository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(RoadmapSession), id);

        return entity.ToDto();
    }

    public async Task<IReadOnlyList<RoadmapSessionDto>> GetByRoadmapIdAsync(
        Guid roadmapId,
        CancellationToken cancellationToken = default)
    {
        var entities = await _sessionRepository.GetByRoadmapIdAsync(roadmapId, cancellationToken);
        return entities.Select(e => e.ToDto()).ToList();
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private static ScheduledWorkout BuildScheduledWorkout(
        Guid userId,
        Guid sessionId,
        DateTimeOffset scheduledDate,
        int estimatedDurationMinutes)
    {
        return new ScheduledWorkout
        {
            UserId = userId,
            SessionId = sessionId,
            ScheduledStartTime = scheduledDate,
            ScheduledEndTime = scheduledDate.AddMinutes(estimatedDurationMinutes),
            RepeatPattern = "none",
            Status = SessionStatus.Scheduled
        };
    }
}
