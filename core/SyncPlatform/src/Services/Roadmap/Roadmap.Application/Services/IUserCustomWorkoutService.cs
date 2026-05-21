using Roadmap.Application.DTOs;

namespace Roadmap.Application.Services;

public interface IUserCustomWorkoutService
{
    Task<UserCustomWorkoutDto> CreateAsync(CreateUserCustomWorkoutDto dto, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<UserCustomWorkoutDto>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<UserCustomWorkoutDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
}
