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

    Task<RoadmapSessionDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<RoadmapSessionDto>> GetByRoadmapIdAsync(Guid roadmapId, CancellationToken cancellationToken = default);
}
