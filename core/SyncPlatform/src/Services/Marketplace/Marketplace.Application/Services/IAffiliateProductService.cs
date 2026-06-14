using Marketplace.Application.Common;
using Marketplace.Application.DTOs;

namespace Marketplace.Application.Services;

public interface IAffiliateProductService
{
    Task<(IReadOnlyList<AffiliateProductDto> Items, PaginationMetadata Pagination)> SearchAsync(
        AffiliateProductSearchRequest request,
        CancellationToken cancellationToken = default);

    Task<AffiliateProductDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AffiliateProductDto>> GetByPartnerAsync(Guid partnerId, CancellationToken cancellationToken = default);

    Task<AffiliateProductDto> CreateAsync(Guid ownerUserId, Guid partnerId, CreateAffiliateProductDto dto, CancellationToken cancellationToken = default);

    Task<AffiliateProductDto> UpdateAsync(Guid ownerUserId, Guid partnerId, Guid productId, UpdateAffiliateProductDto dto, CancellationToken cancellationToken = default);

    Task SoftDeleteAsync(Guid ownerUserId, Guid partnerId, Guid productId, CancellationToken cancellationToken = default);
}
