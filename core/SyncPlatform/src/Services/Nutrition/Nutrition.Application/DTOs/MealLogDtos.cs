using Libs.Shared.Enums;
using Nutrition.Domain.Enums;

namespace Nutrition.Application.DTOs;

public class MealLogItemInputDto
{
    public Guid? FoodItemId { get; set; }
    public string? FoodName { get; set; }
    public decimal QuantityGram { get; set; }
    public int? Calories { get; set; }
    public decimal? ProteinGram { get; set; }
    public decimal? CarbGram { get; set; }
    public decimal? FatGram { get; set; }
}

public class MealLogItemDto
{
    public Guid? FoodItemId { get; set; }
    public string FoodNameSnapshot { get; set; } = string.Empty;
    public decimal QuantityGram { get; set; }
    public int Calories { get; set; }
    public decimal ProteinGram { get; set; }
    public decimal CarbGram { get; set; }
    public decimal FatGram { get; set; }
}

public class MealLogDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public MealType MealType { get; set; }
    public DateTimeOffset LoggedAt { get; set; }
    public MealLogSource Source { get; set; }
    public IReadOnlyList<MealLogItemDto> Items { get; set; } = [];
    public int TotalCalories { get; set; }
    public decimal TotalProteinGram { get; set; }
    public decimal TotalCarbGram { get; set; }
    public decimal TotalFatGram { get; set; }
    public string? PhotoUrl { get; set; }
    public string? Notes { get; set; }
    public Guid? RelatedOrderId { get; set; }
}

public class CreateMealLogDto
{
    public MealType MealType { get; set; }
    public DateTimeOffset? LoggedAt { get; set; }
    public List<MealLogItemInputDto> Items { get; set; } = [];
    public string? PhotoUrl { get; set; }
    public string? Notes { get; set; }
}

public class UpdateMealLogDto
{
    public MealType MealType { get; set; }
    public DateTimeOffset LoggedAt { get; set; }
    public List<MealLogItemInputDto> Items { get; set; } = [];
    public string? PhotoUrl { get; set; }
    public string? Notes { get; set; }
}

public class MealLogListRequest
{
    public DateOnly? Date { get; set; }
    public DateOnly? From { get; set; }
    public DateOnly? To { get; set; }
}
