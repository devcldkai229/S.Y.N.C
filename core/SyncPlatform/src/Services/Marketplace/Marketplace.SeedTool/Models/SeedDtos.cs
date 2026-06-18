using System.Text.Json.Serialization;

namespace Marketplace.SeedTool.Models;

public sealed class MarketplaceSeedFile
{
    [JsonPropertyName("kitchens")]
    public List<KitchenSeedDto> Kitchens { get; set; } = [];
}

public sealed class KitchenSeedDto
{
    public string Name { get; set; } = string.Empty;

    public string Slug { get; set; } = string.Empty;

    public string Type { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string PhoneNumber { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string Address { get; set; } = string.Empty;

    public string District { get; set; } = string.Empty;

    public LocationSeedDto Location { get; set; } = new();

    public decimal ServiceRadiusKm { get; set; }

    public decimal CommissionRate { get; set; }

    public decimal RatingAverage { get; set; }

    public int RatingCount { get; set; }

    public bool IsAiRecommendable { get; set; }

    public string LogoImageQuery { get; set; } = string.Empty;

    public string CoverImageQuery { get; set; } = string.Empty;

    [JsonPropertyName("LogoUrl")]
    public string? LogoUrl { get; set; }

    [JsonPropertyName("CoverImageUrl")]
    public string? CoverImageUrl { get; set; }

    public OperatingHoursSeedDto OperatingHours { get; set; } = new();

    public List<DishSeedDto> Menu { get; set; } = [];
}

public sealed class LocationSeedDto
{
    public double Lat { get; set; }

    public double Lng { get; set; }
}

public sealed class OperatingHoursSeedDto
{
    public string OpenTime { get; set; } = "08:00";

    public string CloseTime { get; set; } = "21:00";

    public List<int> ClosedDays { get; set; } = [];
}

public sealed class DishSeedDto
{
    public string NameVi { get; set; } = string.Empty;

    public string NameEn { get; set; } = string.Empty;

    public string Slug { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string Category { get; set; } = string.Empty;

    public decimal Price { get; set; }

    public int PrepTimeMinutes { get; set; }

    public NutritionSeedDto Nutrition { get; set; } = new();

    public List<string> DietaryTags { get; set; } = [];

    public string SpiceLevel { get; set; } = "None";

    public string Availability { get; set; } = "Available";

    public bool IsAiRecommended { get; set; }

    public string ImageQuery { get; set; } = string.Empty;

    public string S3Key { get; set; } = string.Empty;

    [JsonPropertyName("ImageUrls")]
    public List<string>? ImageUrls { get; set; }
}

public sealed class NutritionSeedDto
{
    public int Calories { get; set; }

    public decimal ProteinGram { get; set; }

    public decimal CarbGram { get; set; }

    public decimal FatGram { get; set; }

    public string ServingDescription { get; set; } = string.Empty;
}
