namespace Nutrition.Application.DTOs;

public class DailyNutritionSummaryDto
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

public class AddWaterIntakeDto
{
    public int Milliliters { get; set; }
    public DateOnly? Date { get; set; }
}

public class NutritionTargetsDto
{
    public int TargetCalories { get; set; }
    public int? TargetProteinGram { get; set; }
    public int? TargetCarbGram { get; set; }
    public int? TargetFatGram { get; set; }
}
