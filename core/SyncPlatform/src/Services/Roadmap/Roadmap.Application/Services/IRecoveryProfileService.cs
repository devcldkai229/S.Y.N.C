using Roadmap.Application.Common;
using Roadmap.Application.DTOs;

namespace Roadmap.Application.Services;

public interface IRecoveryProfileService
{
    Task<RecoveryProfileDto> CreateAsync(CreateRecoveryProfileDto dto, CancellationToken cancellationToken = default);
    Task<RecoveryProfileDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<(IReadOnlyList<RecoveryProfileDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Guid? userId = null,
        CancellationToken cancellationToken = default);
    Task<RecoveryProfileDto> UpdateAsync(Guid id, UpdateRecoveryProfileDto dto, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
