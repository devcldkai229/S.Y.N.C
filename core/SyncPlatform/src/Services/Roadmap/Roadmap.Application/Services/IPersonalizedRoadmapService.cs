using Roadmap.Application.Common;
using Roadmap.Application.DTOs;

namespace Roadmap.Application.Services;

public interface IPersonalizedRoadmapService
{
    Task<PersonalizedRoadmapDto> CreateAsync(CreatePersonalizedRoadmapDto dto, CancellationToken cancellationToken = default);
    Task<PersonalizedRoadmapDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<(IReadOnlyList<PersonalizedRoadmapDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Guid? userId = null,
        CancellationToken cancellationToken = default);
    Task<PersonalizedRoadmapDto> UpdateAsync(Guid id, UpdatePersonalizedRoadmapDto dto, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
