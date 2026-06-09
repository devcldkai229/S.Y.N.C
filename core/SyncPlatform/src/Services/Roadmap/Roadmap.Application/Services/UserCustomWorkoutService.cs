using System.Linq.Expressions;
using Libs.Shared.Enums;
using Roadmap.Application.Common;
using Roadmap.Application.DTOs;
using Roadmap.Application.Exceptions;
using Roadmap.Application.Mappers;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;


namespace Roadmap.Application.Services;

public class UserCustomWorkoutService : IUserCustomWorkoutService
{
    private readonly IUserCustomWorkoutRepository _repository;
    private readonly IRoadmapSessionRepository _sessionRepository;
    private readonly IScheduledWorkoutRepository _scheduledRepository;

    public UserCustomWorkoutService(
        IUserCustomWorkoutRepository repository,
        IRoadmapSessionRepository sessionRepository,
        IScheduledWorkoutRepository scheduledRepository)
    {
        _repository = repository;
        _sessionRepository = sessionRepository;
        _scheduledRepository = scheduledRepository;
    }

    public async Task<UserCustomWorkoutDto> CreateAsync(
        CreateUserCustomWorkoutDto dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.UserId == Guid.Empty)
            throw new BadRequestException("UserId is required.");

        if (string.IsNullOrWhiteSpace(dto.WorkoutName))
            throw new BadRequestException("WorkoutName is required.");

        var entity = new UserCustomWorkout();
        entity.UpdateEntity(dto);

        await _repository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<IReadOnlyList<UserCustomWorkoutDto>> GetByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        if (userId == Guid.Empty)
            throw new BadRequestException("UserId is required.");

        var entities = await _repository.GetByUserIdAsync(userId, cancellationToken);
        return entities.Select(e => e.ToDto()).ToList();
    }

    public async Task<UserCustomWorkoutDto> GetByIdAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(UserCustomWorkout), id);

        var sessions = await _sessionRepository.GetByRoadmapIdAsync(entity.Id, cancellationToken);
        var dto = entity.ToDto();
        dto.Sessions = sessions.Select(s => new WorkoutSessionDto
        {
            Id = s.Id,
            SessionTitle = s.SessionTitle,
            ExerciseCount = s.ExecutionBlocks.Count,
            TotalSetCount = s.ExecutionBlocks.Sum(b => b.TargetSets)
        }).ToList();
        return dto;
    }

    public async Task<MyWorkoutDetailDto> GetDetailByIdAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(UserCustomWorkout), id);

        var sessions = await _sessionRepository.GetByRoadmapIdAsync(id, cancellationToken);
        var sessionIds = sessions.Select(s => s.Id).ToList();

        var schedules = await _scheduledRepository.GetBySessionIdsAsync(sessionIds, cancellationToken);

        return entity.ToDetailDto(sessions.ToList(), schedules.ToList());
    }

    public async Task<(IReadOnlyList<UserCustomWorkoutDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Guid? userId = null,
        CancellationToken cancellationToken = default)
    {
        var (entities, totalCount) = await _repository.GetPagedAsync(
            pageNumber,
            pageSize,
            userId.HasValue ? x => x.UserId == userId.Value : null,
            cancellationToken);

        var dtos = new List<UserCustomWorkoutDto>();
        foreach (var entity in entities)
        {
            var sessions = await _sessionRepository.GetByRoadmapIdAsync(entity.Id, cancellationToken);
            var dto = entity.ToDto();
            dto.Sessions = sessions.Select(s => new WorkoutSessionDto
            {
                Id = s.Id,
                SessionTitle = s.SessionTitle,
                ExerciseCount = s.ExecutionBlocks.Count,
                TotalSetCount = s.ExecutionBlocks.Sum(b => b.TargetSets)
            }).ToList();
            dtos.Add(dto);
        }

        var metadata = new PaginationMetadata(pageNumber, pageSize, totalCount);
        return (dtos, metadata);
    }

    public async Task<(IReadOnlyList<UserCustomWorkoutDto> Items, PaginationMetadata Metadata)> GetPublicWorkoutsAsync(
        int pageNumber,
        int pageSize,
        string? search = null,
        string? sortBy = null,
        CancellationToken cancellationToken = default)
    {
        var (entities, totalCount) = await _repository.GetPublicPagedAsync(
            pageNumber,
            pageSize,
            search,
            sortBy,
            cancellationToken);

        var dtos = new List<UserCustomWorkoutDto>();
        foreach (var entity in entities)
        {
            var sessions = await _sessionRepository.GetByRoadmapIdAsync(entity.Id, cancellationToken);
            var dto = entity.ToDto();
            dto.Sessions = sessions.Select(s => new WorkoutSessionDto
            {
                Id = s.Id,
                SessionTitle = s.SessionTitle,
                ExerciseCount = s.ExecutionBlocks.Count,
                TotalSetCount = s.ExecutionBlocks.Sum(b => b.TargetSets)
            }).ToList();
            dtos.Add(dto);
        }

        var metadata = new PaginationMetadata(pageNumber, pageSize, totalCount);
        return (dtos, metadata);
    }

    public async Task<UserCustomWorkoutDto> CloneWorkoutAsync(
        Guid originalWorkoutId,
        Guid targetUserId,
        CancellationToken cancellationToken = default)
    {
        if (targetUserId == Guid.Empty)
            throw new BadRequestException("TargetUserId is required.");

        var original = await _repository.GetByIdAsync(originalWorkoutId, cancellationToken)
            ?? throw new NotFoundException(nameof(UserCustomWorkout), originalWorkoutId);

        if (original.Visibility != Visibility.Public && original.UserId != targetUserId)
            throw new BadRequestException("You can only clone public workouts or your own workouts.");

        var clone = new UserCustomWorkout
        {
            UserId = targetUserId,
            WorkoutName = $"{original.WorkoutName} (Cloned)",
            Visibility = Visibility.Private,
            ParentWorkoutId = originalWorkoutId,
            ScheduleMode = original.ScheduleMode,
            AllowAiOptimization = original.AllowAiOptimization,
            CustomBlocks = original.CustomBlocks.Select(b => new UserCustomWorkout.CustomBlock
            {
                ExerciseId = b.ExerciseId,
                Sets = b.Sets,
                Reps = b.Reps,
                WeightKg = b.WeightKg,
                RestSeconds = b.RestSeconds
            }).ToList()
        };

        await _repository.CreateAsync(clone, cancellationToken);

        // Increment saves count on the original workout
        original.SavesCount++;
        await _repository.UpdateAsync(original.Id, original, cancellationToken);

        // Retrieve and clone associated sessions
        var originalSessions = await _sessionRepository.GetByRoadmapIdAsync(originalWorkoutId, cancellationToken);
        foreach (var originalSession in originalSessions)
        {
            var clonedSession = new RoadmapSession
            {
                RoadmapId = clone.Id,
                ScheduledDate = originalSession.ScheduledDate,
                ScheduledTime = originalSession.ScheduledTime,
                Timezone = originalSession.Timezone,
                SessionType = originalSession.SessionType,
                SessionTitle = originalSession.SessionTitle,
                EstimatedDurationMinutes = originalSession.EstimatedDurationMinutes,
                EnergyDemandScore = originalSession.EnergyDemandScore,
                RecoveryRequirementScore = originalSession.RecoveryRequirementScore,
                NotificationEnabled = originalSession.NotificationEnabled,
                NotificationMinutesBefore = originalSession.NotificationMinutesBefore,
                AiGenerated = originalSession.AiGenerated,
                SessionStatus = SessionStatus.Scheduled,
                ExecutionBlocks = originalSession.ExecutionBlocks.Select(b => new RoadmapSession.ExecutionBlock
                {
                    Order = b.Order,
                    ExerciseId = b.ExerciseId,
                    ExerciseName = b.ExerciseName,
                    ExerciseAssetId = b.ExerciseAssetId,
                    TargetSets = b.TargetSets,
                    TargetReps = b.TargetReps,
                    TargetWeightKg = b.TargetWeightKg,
                    RestSeconds = b.RestSeconds,
                    Tempo = b.Tempo,
                    ExerciseNotes = b.ExerciseNotes
                }).ToList()
            };
            await _sessionRepository.CreateAsync(clonedSession, cancellationToken);
        }

        return clone.ToDto();
    }

    public async Task<UserCustomWorkoutDto> UpdateAsync(Guid id, UpdateUserCustomWorkoutDto dto, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.WorkoutName))
            throw new BadRequestException("WorkoutName is required.");

        var entity = await _repository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(UserCustomWorkout), id);

        entity.UpdateEntity(dto);
        await _repository.UpdateAsync(id, entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        if (!await _repository.ExistsAsync(id, cancellationToken))
            throw new NotFoundException(nameof(UserCustomWorkout), id);

        await _repository.DeleteAsync(id, cancellationToken);
    }
}

