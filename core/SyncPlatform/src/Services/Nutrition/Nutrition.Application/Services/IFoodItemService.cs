using Nutrition.Application.Common;
using Nutrition.Application.DTOs;

namespace Nutrition.Application.Services;

public interface IFoodItemService
{
    Task<(IReadOnlyList<FoodItemDto> Items, PaginationMetadata Pagination)> SearchAsync(
        FoodSearchRequest request,
        CancellationToken cancellationToken = default);

    Task<FoodItemDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<FoodItemDto> GetByBarcodeAsync(string barcode, CancellationToken cancellationToken = default);

    Task<FoodItemDto> CreateUserSubmittedAsync(
        Guid userId,
        CreateUserFoodItemDto dto,
        CancellationToken cancellationToken = default);

    Task<int> ImportSystemFoodsAsync(
        ImportSystemFoodItemsRequest request,
        CancellationToken cancellationToken = default);
}
