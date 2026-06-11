using Libs.Shared.Enums;
using MongoDB.Driver;
using Nutrition.Domain.Enums;
using Nutrition.Domain.Models;

namespace Nutrition.Infrastructure.Persistence.Seed;

public static class NutritionSeedData
{
    public static async Task SeedAsync(IMongoDatabase database, CancellationToken cancellationToken = default)
    {
        var collection = database.GetCollection<FoodItem>("FoodItems");
        if (await collection.Find(_ => true).AnyAsync(cancellationToken))
            return;

        foreach (var item in GetSystemFoodItems())
            await collection.InsertOneAsync(item, cancellationToken: cancellationToken);
    }

    public static IReadOnlyList<FoodItem> GetSystemFoodItems() =>
    [
        new FoodItem
        {
            Id = Guid.Parse("f1000001-0000-0000-0000-000000000001"),
            NameVi = "Cơm trắng",
            NameEn = "White rice",
            Slug = "com-trang",
            Category = FoodCategory.Grains,
            ServingSizeGram = 100,
            ServingDescription = "1 chén",
            CaloriesPer100g = 130,
            ProteinPer100g = 2.7m,
            CarbPer100g = 28m,
            FatPer100g = 0.3m,
            DietaryTags = [],
            Source = FoodDataSource.System,
            IsVerified = true,
            IsActive = true,
        },
        new FoodItem
        {
            Id = Guid.Parse("f1000002-0000-0000-0000-000000000002"),
            NameVi = "Ức gà",
            NameEn = "Chicken breast",
            Slug = "uc-ga",
            Category = FoodCategory.Protein,
            ServingSizeGram = 100,
            CaloriesPer100g = 165,
            ProteinPer100g = 31m,
            CarbPer100g = 0m,
            FatPer100g = 3.6m,
            DietaryTags = [DietaryTag.HighProtein, DietaryTag.LowCarb],
            Source = FoodDataSource.System,
            IsVerified = true,
            IsActive = true,
        },
        new FoodItem
        {
            Id = Guid.Parse("f1000003-0000-0000-0000-000000000003"),
            NameVi = "Bơ",
            NameEn = "Avocado",
            Slug = "bo",
            Category = FoodCategory.Fat,
            ServingSizeGram = 100,
            CaloriesPer100g = 160,
            ProteinPer100g = 2m,
            CarbPer100g = 9m,
            FatPer100g = 15m,
            DietaryTags = [DietaryTag.Vegan, DietaryTag.LowCarb],
            Source = FoodDataSource.System,
            IsVerified = true,
            IsActive = true,
        },
    ];
}
