using Marketplace.Application.DTOs;

namespace Marketplace.Application.Services;

public interface IAffiliateClickService
{
    Task<AffiliateClickResponseDto> TrackClickAsync(
        Guid userId,
        Guid productId,
        AffiliateClickRequest request,
        CancellationToken cancellationToken = default);
}
