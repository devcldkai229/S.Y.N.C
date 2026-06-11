namespace Nutrition.Domain.Models;

public class DailyNutritionSummary : BaseMongoEntity
{
    public Guid UserId { get; set; }

    public DateOnly Date { get; set; }

    public int TargetCalories { get; set; }

    public int ConsumedCalories { get; set; }

    public decimal TargetProteinGram { get; set; }

    public decimal ConsumedProteinGram { get; set; }

    public decimal TargetCarbGram { get; set; }

    public decimal ConsumedCarbGram { get; set; }

    public decimal TargetFatGram { get; set; }

    public decimal ConsumedFatGram { get; set; }

    public int WaterIntakeMl { get; set; }

    public int MealsLoggedCount { get; set; }
}
