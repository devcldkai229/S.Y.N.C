using Libs.Shared.Enums;
using MongoDB.Bson.Serialization.Attributes;
using Nutrition.Domain.Enums;

namespace Nutrition.Domain.Models;

public class FoodItem : BaseMongoEntity
{
    public string NameVi { get; set; } = string.Empty;

    public string NameEn { get; set; } = string.Empty;

    public string Slug { get; set; } = string.Empty;

    public FoodCategory Category { get; set; }

    [BsonIgnoreIfNull]
    public string? Brand { get; set; }

    [BsonIgnoreIfNull]
    public string? Barcode { get; set; }

    public decimal ServingSizeGram { get; set; }

    [BsonIgnoreIfNull]
    public string? ServingDescription { get; set; }

    public int CaloriesPer100g { get; set; }

    public decimal ProteinPer100g { get; set; }

    public decimal CarbPer100g { get; set; }

    public decimal FatPer100g { get; set; }

    [BsonIgnoreIfNull]
    public decimal? FiberPer100g { get; set; }

    [BsonIgnoreIfNull]
    public decimal? SugarPer100g { get; set; }

    [BsonIgnoreIfNull]
    public decimal? SodiumMgPer100g { get; set; }

    public List<DietaryTag> DietaryTags { get; set; } = [];

    [BsonIgnoreIfNull]
    public string? ImageUrl { get; set; }

    public FoodDataSource Source { get; set; }

    [BsonIgnoreIfNull]
    public Guid? MarketplaceItemId { get; set; }

    public bool IsVerified { get; set; }

    public bool IsActive { get; set; }
}
