using Iam.Application.DTOs;

namespace Iam.Application.Abstractions;

public interface IShopService
{
    Task<IReadOnlyList<ShopItemDto>> GetCatalogAsync(CancellationToken cancellationToken = default);
    Task<PurchaseResultDto> PurchaseAsync(string itemCode, CancellationToken cancellationToken = default);
}
