using Libs.Shared.Common;
using Libs.Shared.Enums;
using Marketplace.Domain.Enums;
using MongoDB.Bson.Serialization.Attributes;

namespace Marketplace.Domain.Models;

public class FoodMenuItem : BaseMongoEntity
{
    public Guid PartnerId { get; set; }

    public string NameVi { get; set; } = string.Empty;

    public string NameEn { get; set; } = string.Empty;

    public string Slug { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public List<string> ImageUrls { get; set; } = [];

    public FoodCategory Category { get; set; }

    public decimal Price { get; set; }

    public string Currency { get; set; } = string.Empty;

    public int PrepTimeMinutes { get; set; }

    public NutritionSnapshot Nutrition { get; set; } = new();

    public List<DietaryTag> DietaryTags { get; set; } = [];

    public SpiceLevel SpiceLevel { get; set; }

    public AvailabilityStatus Availability { get; set; }

    public bool IsAiRecommended { get; set; }

    public decimal RatingAverage { get; set; }

    public int RatingCount { get; set; }
}
