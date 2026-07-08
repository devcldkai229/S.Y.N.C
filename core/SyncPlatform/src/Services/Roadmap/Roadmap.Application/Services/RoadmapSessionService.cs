using Libs.Shared.Enums;
using Roadmap.Application.Common;
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
    private readonly IPersonalizedRoadmapRepository _personalizedRoadmapRepository;

    public RoadmapSessionService(
        IRoadmapSessionRepository sessionRepository,
        IScheduledWorkoutRepository scheduledWorkoutRepository,
        IUserCustomWorkoutRepository customWorkoutRepository,
        IPersonalizedRoadmapRepository personalizedRoadmapRepository)
    {
        _sessionRepository = sessionRepository;
        _scheduledWorkoutRepository = scheduledWorkoutRepository;
        _customWorkoutRepository = customWorkoutRepository;
        _personalizedRoadmapRepository = personalizedRoadmapRepository;
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

    public async Task<IReadOnlyList<RoadmapSessionDto>> GetByRoadmapIdAndDateRangeAsync(
        Guid roadmapId,
        DateTimeOffset from,
        DateTimeOffset to,
        CancellationToken cancellationToken = default)
    {
        var entities = await _sessionRepository.GetByRoadmapIdAndDateRangeAsync(roadmapId, from, to, cancellationToken);
        return entities.Select(e => e.ToDto()).ToList();
    }

    public async Task<IReadOnlyList<ScheduledSessionResultDto>> ScheduleWeekAsync(
        IReadOnlyList<ScheduleSessionDto> sessions,
        CancellationToken cancellationToken = default)
    {
        var results = new List<ScheduledSessionResultDto>();
        foreach (var dto in sessions)
        {
            var result = await ScheduleAsync(dto, cancellationToken);
            results.Add(result);
        }
        return results;
    }

    public async Task<RoadmapSessionDto> RescheduleSessionAsync(
        Guid sessionId,
        Guid userId,
        DateTimeOffset newDate,
        string newTime,
        CancellationToken cancellationToken = default)
    {
        var entity = await _sessionRepository.GetByIdAsync(sessionId, cancellationToken)
            ?? throw new NotFoundException(nameof(RoadmapSession), sessionId);

        if (entity.SessionStatus != SessionStatus.Scheduled)
            throw new BadRequestException(
                $"Cannot reschedule session with status '{entity.SessionStatus}'. Only 'Scheduled' sessions can be rescheduled.");

        // Week guard: if the week this session belongs to has any Completed/InProgress sessions, block
        var weekStart = entity.ScheduledDate.Date;
        var dayOfWeek = (int)entity.ScheduledDate.DayOfWeek;
        var startOfWeek = entity.ScheduledDate.AddDays(-dayOfWeek);
        var endOfWeek = startOfWeek.AddDays(7);
        if (entity.RoadmapId != Guid.Empty)
        {
            var weekSessions = await _sessionRepository.GetByRoadmapIdAndDateRangeAsync(
                entity.RoadmapId, startOfWeek, endOfWeek, cancellationToken);
            var hasProgress = weekSessions.Any(s =>
                s.Id != entity.Id &&
                (s.SessionStatus == SessionStatus.Completed || s.SessionStatus == SessionStatus.InProgress));
            if (hasProgress)
                throw new BadRequestException(
                    "Cannot reschedule: the week already has completed or in-progress sessions. Only individual unstarted sessions can be rescheduled within a week that has no progress.");
        }

        entity.ScheduledDate = newDate;
        entity.ScheduledTime = newTime;
        entity.UpdatedAt = DateTimeOffset.UtcNow;
        await _sessionRepository.UpdateAsync(sessionId, entity, cancellationToken);

        // Sync ScheduledWorkout
        var scheduledWorkout = await _scheduledWorkoutRepository.GetBySessionIdAsync(sessionId, cancellationToken);
        if (scheduledWorkout is not null)
        {
            scheduledWorkout.ScheduledStartTime = newDate;
            scheduledWorkout.ScheduledEndTime = newDate.AddMinutes(entity.EstimatedDurationMinutes);
            await _scheduledWorkoutRepository.UpdateAsync(scheduledWorkout.Id, scheduledWorkout, cancellationToken);
        }

        return entity.ToDto();
    }

    public async Task<RoadmapSessionDto> CreateAsync(CreateRoadmapSessionDto dto, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.SessionTitle))
            throw new BadRequestException("SessionTitle is required.");

        var entity = dto.ToEntity();
        await _sessionRepository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<(IReadOnlyList<RoadmapSessionDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Guid? roadmapId = null,
        CancellationToken cancellationToken = default)
    {
        var (entities, totalCount) = await _sessionRepository.GetPagedAsync(
            pageNumber,
            pageSize,
            roadmapId.HasValue ? x => x.RoadmapId == roadmapId.Value : null,
            cancellationToken);

        var dtos = entities.Select(e => e.ToDto()).ToList();
        var metadata = new PaginationMetadata(pageNumber, pageSize, totalCount);
        return (dtos, metadata);
    }

    public async Task<RoadmapSessionDto> UpdateAsync(Guid id, UpdateRoadmapSessionDto dto, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.SessionTitle))
            throw new BadRequestException("SessionTitle is required.");

        var entity = await _sessionRepository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(RoadmapSession), id);

        entity.UpdateEntity(dto);
        await _sessionRepository.UpdateAsync(id, entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<RoadmapSessionDto> AdjustIntensityAsync(
        Guid sessionId,
        Guid userId,
        double factor,
        CancellationToken cancellationToken = default)
    {
        var entity = await _sessionRepository.GetByIdAsync(sessionId, cancellationToken)
            ?? throw new NotFoundException(nameof(RoadmapSession), sessionId);

        await EnsureAiIntensityAllowedAsync(entity.RoadmapId, cancellationToken);

        factor = Math.Clamp(factor, 0.5, 1.5);
        foreach (var block in entity.ExecutionBlocks)
        {
            block.TargetWeightKg = Math.Round(block.TargetWeightKg * (decimal)factor, 2);
            block.TargetReps = Math.Max(1, (int)Math.Round(block.TargetReps * factor));
        }

        await _sessionRepository.UpdateAsync(sessionId, entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<RoadmapSessionDto> SubstituteExerciseAsync(
        Guid sessionId,
        Guid userId,
        Guid newExerciseId,
        Guid? replaceExerciseId,
        string? exerciseName,
        string reason,
        CancellationToken cancellationToken = default)
    {
        _ = userId;
        _ = reason;

        var entity = await _sessionRepository.GetByIdAsync(sessionId, cancellationToken)
            ?? throw new NotFoundException(nameof(RoadmapSession), sessionId);

        if (entity.ExecutionBlocks.Count == 0)
            throw new BadRequestException("Session has no execution blocks to substitute.");

        var block = replaceExerciseId.HasValue
            ? entity.ExecutionBlocks.FirstOrDefault(b => b.ExerciseId == replaceExerciseId.Value)
            : entity.ExecutionBlocks.OrderBy(b => b.Order).FirstOrDefault();

        if (block is null)
            throw new NotFoundException("ExecutionBlock", replaceExerciseId ?? Guid.Empty);

        block.ExerciseId = newExerciseId;
        block.ExerciseName = string.IsNullOrWhiteSpace(exerciseName)
            ? block.ExerciseName
            : exerciseName;

        await _sessionRepository.UpdateAsync(sessionId, entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        if (!await _sessionRepository.ExistsAsync(id, cancellationToken))
            throw new NotFoundException(nameof(RoadmapSession), id);

        await _sessionRepository.DeleteAsync(id, cancellationToken);
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private async Task EnsureAiIntensityAllowedAsync(Guid roadmapId, CancellationToken cancellationToken)
    {
        var roadmap = await _personalizedRoadmapRepository.GetByIdAsync(roadmapId, cancellationToken);
        if (roadmap is not null && !roadmap.AllowAiIntensityAdjustment)
            throw new BadRequestException("AI intensity adjustment is disabled for this roadmap.");
    }

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

