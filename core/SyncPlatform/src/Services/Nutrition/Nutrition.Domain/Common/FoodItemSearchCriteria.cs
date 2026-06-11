using Libs.Shared.Enums;

namespace Nutrition.Domain.Common;

public class FoodItemSearchCriteria
{
    public string? Query { get; set; }

    public FoodCategory? Category { get; set; }

    public IReadOnlyList<DietaryTag>? DietaryTags { get; set; }

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}
