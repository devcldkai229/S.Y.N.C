using Libs.Shared.Enums;
using Nutrition.Domain.Enums;

namespace Nutrition.Application.DTOs;

public class FoodItemDto
{
    public Guid Id { get; set; }
    public string NameVi { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public FoodCategory Category { get; set; }
    public string? Brand { get; set; }
    public string? Barcode { get; set; }
    public decimal ServingSizeGram { get; set; }
    public string? ServingDescription { get; set; }
    public int CaloriesPer100g { get; set; }
    public decimal ProteinPer100g { get; set; }
    public decimal CarbPer100g { get; set; }
    public decimal FatPer100g { get; set; }
    public decimal? FiberPer100g { get; set; }
    public decimal? SugarPer100g { get; set; }
    public decimal? SodiumMgPer100g { get; set; }
    public IReadOnlyList<DietaryTag> DietaryTags { get; set; } = [];
    public string? ImageUrl { get; set; }
    public FoodDataSource Source { get; set; }
    public Guid? MarketplaceItemId { get; set; }
    public bool IsVerified { get; set; }
    public bool IsActive { get; set; }
}

public class FoodSearchRequest
{
    public string? Query { get; set; }
    public string? Category { get; set; }
    public List<string>? DietaryTags { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class CreateUserFoodItemDto
{
    public string NameVi { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public FoodCategory Category { get; set; }
    public string? Brand { get; set; }
    public string? Barcode { get; set; }
    public decimal ServingSizeGram { get; set; }
    public string? ServingDescription { get; set; }
    public int CaloriesPer100g { get; set; }
    public decimal ProteinPer100g { get; set; }
    public decimal CarbPer100g { get; set; }
    public decimal FatPer100g { get; set; }
    public decimal? FiberPer100g { get; set; }
    public decimal? SugarPer100g { get; set; }
    public decimal? SodiumMgPer100g { get; set; }
    public List<DietaryTag>? DietaryTags { get; set; }
    public string? ImageUrl { get; set; }
}

public class ImportSystemFoodItemDto
{
    public string NameVi { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public FoodCategory Category { get; set; }
    public string? Brand { get; set; }
    public string? Barcode { get; set; }
    public decimal ServingSizeGram { get; set; }
    public string? ServingDescription { get; set; }
    public int CaloriesPer100g { get; set; }
    public decimal ProteinPer100g { get; set; }
    public decimal CarbPer100g { get; set; }
    public decimal FatPer100g { get; set; }
    public List<DietaryTag>? DietaryTags { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsVerified { get; set; } = true;
}

public class ImportSystemFoodItemsRequest
{
    public List<ImportSystemFoodItemDto> Items { get; set; } = [];
}
