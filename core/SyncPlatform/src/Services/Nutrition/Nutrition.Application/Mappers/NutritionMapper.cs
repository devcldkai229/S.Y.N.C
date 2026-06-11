using Nutrition.Application.DTOs;
using Nutrition.Domain.Models;

namespace Nutrition.Application.Mappers;

public static class NutritionMapper
{
    public static FoodItemDto ToDto(this FoodItem entity) => new()
    {
        Id = entity.Id,
        NameVi = entity.NameVi,
        NameEn = entity.NameEn,
        Slug = entity.Slug,
        Category = entity.Category,
        Brand = entity.Brand,
        Barcode = entity.Barcode,
        ServingSizeGram = entity.ServingSizeGram,
        ServingDescription = entity.ServingDescription,
        CaloriesPer100g = entity.CaloriesPer100g,
        ProteinPer100g = entity.ProteinPer100g,
        CarbPer100g = entity.CarbPer100g,
        FatPer100g = entity.FatPer100g,
        FiberPer100g = entity.FiberPer100g,
        SugarPer100g = entity.SugarPer100g,
        SodiumMgPer100g = entity.SodiumMgPer100g,
        DietaryTags = entity.DietaryTags,
        ImageUrl = entity.ImageUrl,
        Source = entity.Source,
        MarketplaceItemId = entity.MarketplaceItemId,
        IsVerified = entity.IsVerified,
        IsActive = entity.IsActive,
    };

    public static MealLogDto ToDto(this MealLog entity) => new()
    {
        Id = entity.Id,
        UserId = entity.UserId,
        MealType = entity.MealType,
        LoggedAt = entity.LoggedAt,
        Source = entity.Source,
        Items = entity.Items.Select(i => new MealLogItemDto
        {
            FoodItemId = i.FoodItemId,
            FoodNameSnapshot = i.FoodNameSnapshot,
            QuantityGram = i.QuantityGram,
            Calories = i.Calories,
            ProteinGram = i.ProteinGram,
            CarbGram = i.CarbGram,
            FatGram = i.FatGram,
        }).ToList(),
        TotalCalories = entity.TotalCalories,
        TotalProteinGram = entity.TotalProteinGram,
        TotalCarbGram = entity.TotalCarbGram,
        TotalFatGram = entity.TotalFatGram,
        PhotoUrl = entity.PhotoUrl,
        Notes = entity.Notes,
        RelatedOrderId = entity.RelatedOrderId,
    };

    public static DailyNutritionSummaryDto ToDto(
        this DailyNutritionSummary entity,
        NutritionTargetsDto? targets = null) => new()
    {
        UserId = entity.UserId,
        Date = entity.Date,
        TargetCalories = targets?.TargetCalories ?? entity.TargetCalories,
        ConsumedCalories = entity.ConsumedCalories,
        TargetProteinGram = targets?.TargetProteinGram ?? entity.TargetProteinGram,
        ConsumedProteinGram = entity.ConsumedProteinGram,
        TargetCarbGram = targets?.TargetCarbGram ?? entity.TargetCarbGram,
        ConsumedCarbGram = entity.ConsumedCarbGram,
        TargetFatGram = targets?.TargetFatGram ?? entity.TargetFatGram,
        ConsumedFatGram = entity.ConsumedFatGram,
        WaterIntakeMl = entity.WaterIntakeMl,
        MealsLoggedCount = entity.MealsLoggedCount,
    };
}
