using Marketplace.Application.DTOs;

namespace Marketplace.Application.Services;

public interface IInternalMarketplaceService
{
    Task<ValidateOrderItemsResultDto> ValidateOrderItemsAsync(
        ValidateOrderItemsRequestDto request,
        CancellationToken cancellationToken = default);

    Task<PartnerInternalDto?> GetPartnerInternalAsync(Guid partnerId, CancellationToken cancellationToken = default);
}
