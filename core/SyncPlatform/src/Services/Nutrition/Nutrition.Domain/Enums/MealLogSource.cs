namespace Nutrition.Domain.Enums;

public enum MealLogSource
{
    Manual = 0,
    BarcodeScan = 1,
    FromMarketplaceOrder = 2,
    AiSuggested = 3,
}
