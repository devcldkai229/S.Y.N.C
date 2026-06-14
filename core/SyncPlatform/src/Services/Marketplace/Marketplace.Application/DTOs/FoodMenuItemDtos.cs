using Libs.Shared.Enums;
using Marketplace.Domain.Enums;

namespace Marketplace.Application.DTOs;

public class FoodMenuItemDto
{
    public Guid Id { get; set; }

    public Guid PartnerId { get; set; }

    public string NameVi { get; set; } = string.Empty;

    public string NameEn { get; set; } = string.Empty;

    public string Slug { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public IReadOnlyList<string> ImageUrls { get; set; } = [];

    public FoodCategory Category { get; set; }

    public decimal Price { get; set; }

    public string Currency { get; set; } = string.Empty;

    public int PrepTimeMinutes { get; set; }

    public NutritionSnapshotDto Nutrition { get; set; } = new();

    public IReadOnlyList<DietaryTag> DietaryTags { get; set; } = [];

    public SpiceLevel SpiceLevel { get; set; }

    public AvailabilityStatus Availability { get; set; }

    public bool IsAiRecommended { get; set; }

    public decimal RatingAverage { get; set; }

    public int RatingCount { get; set; }
}

public class FoodMenuItemSearchRequest
{
    public string? Query { get; set; }

    public string? Category { get; set; }

    public List<string>? DietaryTags { get; set; }

    public decimal? MinPrice { get; set; }

    public decimal? MaxPrice { get; set; }

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    public double? RadiusKm { get; set; }

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}

public class FoodMenuItemSuggestionsRequest
{
    public int Count { get; set; } = 10;

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    public double? RadiusKm { get; set; }
}

public class CreateFoodMenuItemDto
{
    public string NameVi { get; set; } = string.Empty;

    public string NameEn { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public List<string>? ImageUrls { get; set; }

    public FoodCategory Category { get; set; }

    public decimal Price { get; set; }

    public string Currency { get; set; } = "VND";

    public int PrepTimeMinutes { get; set; }

    public NutritionSnapshotDto Nutrition { get; set; } = new();

    public List<DietaryTag>? DietaryTags { get; set; }

    public SpiceLevel SpiceLevel { get; set; }

    public AvailabilityStatus Availability { get; set; } = AvailabilityStatus.Available;

    public bool IsAiRecommended { get; set; }
}

public class UpdateFoodMenuItemDto
{
    public string? NameVi { get; set; }

    public string? NameEn { get; set; }

    public string? Description { get; set; }

    public List<string>? ImageUrls { get; set; }

    public FoodCategory? Category { get; set; }

    public decimal? Price { get; set; }

    public string? Currency { get; set; }

    public int? PrepTimeMinutes { get; set; }

    public NutritionSnapshotDto? Nutrition { get; set; }

    public List<DietaryTag>? DietaryTags { get; set; }

    public SpiceLevel? SpiceLevel { get; set; }

    public AvailabilityStatus? Availability { get; set; }

    public bool? IsAiRecommended { get; set; }
}
