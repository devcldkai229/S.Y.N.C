using Libs.Shared.Enums;
using MongoDB.Bson.Serialization.Attributes;
using Nutrition.Domain.Enums;

namespace Nutrition.Domain.Models;

public class MealLog : BaseMongoEntity
{
    public Guid UserId { get; set; }

    public MealType MealType { get; set; }

    public DateTimeOffset LoggedAt { get; set; }

    public MealLogSource Source { get; set; }

    public List<MealLogItem> Items { get; set; } = [];

    public int TotalCalories { get; set; }

    public decimal TotalProteinGram { get; set; }

    public decimal TotalCarbGram { get; set; }

    public decimal TotalFatGram { get; set; }

    [BsonIgnoreIfNull]
    public string? PhotoUrl { get; set; }

    [BsonIgnoreIfNull]
    public string? Notes { get; set; }

    [BsonIgnoreIfNull]
    public Guid? RelatedOrderId { get; set; }

    public class MealLogItem
    {
        [BsonIgnoreIfNull]
        public Guid? FoodItemId { get; set; }

        public string FoodNameSnapshot { get; set; } = string.Empty;

        public decimal QuantityGram { get; set; }

        public int Calories { get; set; }

        public decimal ProteinGram { get; set; }

        public decimal CarbGram { get; set; }

        public decimal FatGram { get; set; }
    }
}
