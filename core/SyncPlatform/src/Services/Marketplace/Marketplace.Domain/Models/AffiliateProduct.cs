using Libs.Shared.Common;
using Libs.Shared.Enums;
using Marketplace.Domain.Enums;
using MongoDB.Bson.Serialization.Attributes;

namespace Marketplace.Domain.Models;

public class AffiliateProduct : BaseMongoEntity
{
    [BsonIgnoreIfNull]
    public Guid? PartnerId { get; set; }

    public string BrandName { get; set; } = string.Empty;

    public string NameVi { get; set; } = string.Empty;

    public string NameEn { get; set; } = string.Empty;

    public string Slug { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public List<string> ImageUrls { get; set; } = [];

    public AffiliateCategory Category { get; set; }

    public decimal Price { get; set; }

    public string Currency { get; set; } = string.Empty;

    public string AffiliateUrl { get; set; } = string.Empty;

    [BsonIgnoreIfNull]
    public string? ExternalProductId { get; set; }

    public decimal CommissionRate { get; set; }

    [BsonIgnoreIfNull]
    public NutritionSnapshot? Nutrition { get; set; }

    [BsonIgnoreIfNull]
    public List<DietaryTag>? DietaryTags { get; set; }

    public AvailabilityStatus Availability { get; set; }

    public decimal RatingAverage { get; set; }

    public int RatingCount { get; set; }
}
