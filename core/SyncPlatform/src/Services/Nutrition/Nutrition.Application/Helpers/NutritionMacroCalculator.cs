using Nutrition.Domain.Models;

namespace Nutrition.Application.Helpers;

public static class NutritionMacroCalculator
{
    public static MealLog.MealLogItem CalculateFromFoodItem(FoodItem food, decimal quantityGram, string? nameOverride = null)
    {
        var factor = quantityGram / 100m;
        return new MealLog.MealLogItem
        {
            FoodItemId = food.Id,
            FoodNameSnapshot = nameOverride ?? food.NameVi,
            QuantityGram = quantityGram,
            Calories = (int)Math.Round(food.CaloriesPer100g * factor),
            ProteinGram = Math.Round(food.ProteinPer100g * factor, 2),
            CarbGram = Math.Round(food.CarbPer100g * factor, 2),
            FatGram = Math.Round(food.FatPer100g * factor, 2),
        };
    }

    public static MealLog.MealLogItem CalculateFromFreeText(
        string foodName,
        decimal quantityGram,
        int calories,
        decimal proteinGram,
        decimal carbGram,
        decimal fatGram)
    {
        return new MealLog.MealLogItem
        {
            FoodNameSnapshot = foodName,
            QuantityGram = quantityGram,
            Calories = calories,
            ProteinGram = proteinGram,
            CarbGram = carbGram,
            FatGram = fatGram,
        };
    }

    public static void ApplyTotals(MealLog log)
    {
        log.TotalCalories = log.Items.Sum(i => i.Calories);
        log.TotalProteinGram = log.Items.Sum(i => i.ProteinGram);
        log.TotalCarbGram = log.Items.Sum(i => i.CarbGram);
        log.TotalFatGram = log.Items.Sum(i => i.FatGram);
    }

    public static string SlugFromName(string name)
    {
        var slug = name.Trim().ToLowerInvariant();
        slug = System.Text.RegularExpressions.Regex.Replace(slug, @"[^a-z0-9\s-]", string.Empty);
        slug = System.Text.RegularExpressions.Regex.Replace(slug, @"\s+", "-");
        slug = System.Text.RegularExpressions.Regex.Replace(slug, @"-+", "-").Trim('-');
        return string.IsNullOrWhiteSpace(slug) ? Guid.NewGuid().ToString("N")[..8] : slug;
    }
}
