using Marketplace.Application.Common;
using Marketplace.Application.DTOs;

namespace Marketplace.Application.Services;

public interface IFoodMenuItemService
{
    Task<(IReadOnlyList<FoodMenuItemDto> Items, PaginationMetadata Pagination)> SearchAsync(
        FoodMenuItemSearchRequest request,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<FoodMenuItemDto>> GetSuggestionsAsync(
        FoodMenuItemSuggestionsRequest request,
        CancellationToken cancellationToken = default);

    Task<FoodMenuItemDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<FoodMenuItemDto>> GetByPartnerAsync(Guid partnerId, CancellationToken cancellationToken = default);

    Task<FoodMenuItemDto> CreateAsync(Guid ownerUserId, Guid partnerId, CreateFoodMenuItemDto dto, CancellationToken cancellationToken = default);

    Task<FoodMenuItemDto> UpdateAsync(Guid ownerUserId, Guid partnerId, Guid itemId, UpdateFoodMenuItemDto dto, CancellationToken cancellationToken = default);

    Task SoftDeleteAsync(Guid ownerUserId, Guid partnerId, Guid itemId, CancellationToken cancellationToken = default);
}
