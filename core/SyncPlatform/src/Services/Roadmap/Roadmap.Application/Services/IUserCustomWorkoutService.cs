using Roadmap.Application.Common;
using Roadmap.Application.DTOs;

namespace Roadmap.Application.Services;

public interface IUserCustomWorkoutService
{
    Task<UserCustomWorkoutDto> CreateAsync(CreateUserCustomWorkoutDto dto, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<UserCustomWorkoutDto>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<UserCustomWorkoutDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<MyWorkoutDetailDto> GetDetailByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<(IReadOnlyList<UserCustomWorkoutDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Guid? userId = null,
        CancellationToken cancellationToken = default);
    Task<UserCustomWorkoutDto> UpdateAsync(Guid id, UpdateUserCustomWorkoutDto dto, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}

