using Roadmap.Application.DTOs;

namespace Roadmap.Application.Services;

public interface IInternalWorkoutActivityService
{
    Task<TodayWorkoutActivityDto> GetTodayWorkoutActivityAsync(Guid userId, string? timeZoneId, CancellationToken cancellationToken);
}
