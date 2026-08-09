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
    Task<PersonalizedRoadmapDto?> GetActiveByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<PersonalizedRoadmapDto> PatchForAiAsync(Guid id, InternalPatchPersonalizedRoadmapDto dto, CancellationToken cancellationToken = default);
    /// <summary>Patch weight/fat/phase on the active roadmap; returns null when user has none.</summary>
    Task<PersonalizedRoadmapDto?> SyncBodyMetricsAsync(
        Guid userId,
        InternalSyncBodyMetricsDto dto,
        CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
