using Roadmap.Application.Common;
using Roadmap.Application.DTOs;

namespace Roadmap.Application.Services;

public interface IRoadmapSessionService
{
    /// <summary>AI Flow — schedule a session with explicit ExecutionBlocks.</summary>
    Task<ScheduledSessionResultDto> ScheduleAsync(ScheduleSessionDto dto, CancellationToken cancellationToken = default);

    /// <summary>Custom Flow — build a session from an existing UserCustomWorkout, then schedule it.</summary>
    Task<ScheduledSessionResultDto> ScheduleFromCustomWorkoutAsync(
        Guid customWorkoutId,
        ScheduleFromCustomWorkoutDto dto,
        CancellationToken cancellationToken = default);

    Task<RoadmapSessionDto> CreateAsync(CreateRoadmapSessionDto dto, CancellationToken cancellationToken = default);
    Task<RoadmapSessionDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<RoadmapSessionDto>> GetByRoadmapIdAsync(Guid roadmapId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<RoadmapSessionDto>> GetByRoadmapIdAndDateRangeAsync(Guid roadmapId, DateTimeOffset from, DateTimeOffset to, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ScheduledSessionResultDto>> ScheduleWeekAsync(IReadOnlyList<ScheduleSessionDto> sessions, CancellationToken cancellationToken = default);
    Task<RoadmapSessionDto> RescheduleSessionAsync(Guid sessionId, Guid userId, DateTimeOffset newDate, string newTime, CancellationToken cancellationToken = default);
    Task<(IReadOnlyList<RoadmapSessionDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Guid? roadmapId = null,
        CancellationToken cancellationToken = default);
    Task<RoadmapSessionDto> UpdateAsync(Guid id, UpdateRoadmapSessionDto dto, CancellationToken cancellationToken = default);
    Task<RoadmapSessionDto> AdjustIntensityAsync(Guid sessionId, Guid userId, double factor, CancellationToken cancellationToken = default);

    /// <summary>
    /// Adaptive Engine — chỉnh volume/load các session sắp tới (deload/progress).
    /// </summary>
    Task<ApplyTrainingAdjustmentResultDto> ApplyTrainingAdjustmentAsync(
        Guid userId,
        ApplyTrainingAdjustmentRequestDto request,
        CancellationToken cancellationToken = default);

    Task<RoadmapSessionDto> SubstituteExerciseAsync(
        Guid sessionId,
        Guid userId,
        Guid newExerciseId,
        Guid? replaceExerciseId,
        string? exerciseName,
        string reason,
        CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}

