using Roadmap.Application.DTOs;

namespace Roadmap.Application.Services;

public interface IWorkoutExecutionService
{
    Task<WorkoutExecutionResultDto> SubmitExecutionAsync(
        Guid sessionId,
        SubmitWorkoutExecutionDto dto,
        CancellationToken cancellationToken = default);

    Task<WorkoutExecutionDetailDto> StartWorkoutAsync(Guid userId, StartWorkoutExecutionDto request, CancellationToken cancellationToken = default);
    Task<WorkoutExecutionDetailDto> GetWorkoutExecutionDetailAsync(Guid userId, Guid executionId, CancellationToken cancellationToken = default);
    Task<WorkoutExecutionSummaryDto> FinishWorkoutAsync(Guid userId, Guid executionId, FinishWorkoutExecutionDto request, CancellationToken cancellationToken = default);
    Task CancelWorkoutAsync(Guid userId, Guid executionId, CancellationToken cancellationToken = default);
}
