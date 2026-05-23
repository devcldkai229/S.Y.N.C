using Roadmap.Application.DTOs;

namespace Roadmap.Application.Services;

public interface IWorkoutExecutionService
{
    Task<WorkoutExecutionResultDto> SubmitExecutionAsync(
        Guid sessionId,
        SubmitWorkoutExecutionDto dto,
        CancellationToken cancellationToken = default);
}
