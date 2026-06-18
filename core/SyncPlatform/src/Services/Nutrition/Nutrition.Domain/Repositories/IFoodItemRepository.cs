using Nutrition.Domain.Common;
using Nutrition.Domain.Models;

namespace Nutrition.Domain.Repositories;

public interface IFoodItemRepository : IGenericRepository<FoodItem>
{
    Task<FoodItem?> GetByBarcodeAsync(string barcode, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<FoodItem> Items, int TotalRecords)> SearchPagedAsync(
        FoodItemSearchCriteria criteria,
        CancellationToken cancellationToken = default);
}
