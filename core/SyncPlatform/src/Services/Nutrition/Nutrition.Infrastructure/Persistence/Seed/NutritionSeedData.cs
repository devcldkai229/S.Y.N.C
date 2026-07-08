using Libs.Shared.Enums;
using MongoDB.Driver;
using Nutrition.Domain.Enums;
using Nutrition.Domain.Models;

namespace Nutrition.Infrastructure.Persistence.Seed;

public static class NutritionSeedData
{
    public static readonly Guid DemoUserId = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");

    public static readonly Guid RiceFoodId = Guid.Parse("f1000001-0000-0000-0000-000000000001");
    public static readonly Guid ChickenFoodId = Guid.Parse("f1000002-0000-0000-0000-000000000002");
    public static readonly Guid AvocadoFoodId = Guid.Parse("f1000003-0000-0000-0000-000000000003");

    private const int TargetCalories = 2180;
    private const int TargetProtein = 150;
    private const int TargetCarb = 220;
    private const int TargetFat = 65;

    public static async Task SeedAsync(IMongoDatabase database, CancellationToken cancellationToken = default)
    {
        await SeedFoodItemsAsync(database, cancellationToken);

        var utcNow = DateTimeOffset.UtcNow;
        await SeedCollectionAsync(
            database.GetCollection<MealLog>("MealLogs"),
            GetDemoMealLogs(utcNow),
            cancellationToken);
        await SeedCollectionAsync(
            database.GetCollection<DailyNutritionSummary>("DailyNutritionSummaries"),
            GetDemoDailySummaries(utcNow),
            cancellationToken);
    }

    private static async Task SeedFoodItemsAsync(IMongoDatabase database, CancellationToken cancellationToken)
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
            Id = RiceFoodId,
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
            Id = ChickenFoodId,
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
            Id = AvocadoFoodId,
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

    public static IReadOnlyList<MealLog> GetDemoMealLogs(DateTimeOffset utcNow)
    {
        var logs = new List<MealLog>();
        var mealId = 1;

        void AddDay(int dayOffset, IReadOnlyList<(MealType type, int hour, (Guid id, string name, decimal g, int cal, decimal p, decimal c, decimal f)[] items, MealLogSource source)> meals)
        {
            var date = utcNow.Date.AddDays(dayOffset);
            foreach (var meal in meals)
            {
                var loggedAt = new DateTimeOffset(date.AddHours(meal.hour), TimeSpan.Zero);
                var items = meal.items.Select(i => new MealLog.MealLogItem
                {
                    FoodItemId = i.id,
                    FoodNameSnapshot = i.name,
                    QuantityGram = i.g,
                    Calories = i.cal,
                    ProteinGram = i.p,
                    CarbGram = i.c,
                    FatGram = i.f,
                }).ToList();

                logs.Add(new MealLog
                {
                    Id = Guid.Parse($"a1000001-0000-4000-8000-{mealId:D012}"),
                    UserId = DemoUserId,
                    MealType = meal.type,
                    LoggedAt = loggedAt,
                    Source = meal.source,
                    Items = items,
                    TotalCalories = items.Sum(x => x.Calories),
                    TotalProteinGram = items.Sum(x => x.ProteinGram),
                    TotalCarbGram = items.Sum(x => x.CarbGram),
                    TotalFatGram = items.Sum(x => x.FatGram),
                    Notes = dayOffset == 0 ? "Đang log dở trong ngày" : null,
                });
                mealId++;
            }
        }

        // Hôm nay — ~1450 kcal (chưa đủ target)
        AddDay(0,
        [
            (MealType.Breakfast, 7, [Item(RiceFoodId, "Cơm trắng", 180), Item(ChickenFoodId, "Ức gà", 130)], MealLogSource.Manual),
            (MealType.Lunch, 12, [Item(RiceFoodId, "Cơm trắng", 150), Item(AvocadoFoodId, "Bơ", 60), Item(ChickenFoodId, "Ức gà", 80)], MealLogSource.AiSuggested),
            (MealType.Snack, 16, [Item(AvocadoFoodId, "Bơ", 50), Item(RiceFoodId, "Cơm trắng", 100)], MealLogSource.Manual),
        ]);

        // Hôm qua — ~2100 kcal
        AddDay(-1,
        [
            (MealType.Breakfast, 7, [Item(RiceFoodId, "Cơm trắng", 200), Item(ChickenFoodId, "Ức gà", 150)], MealLogSource.Manual),
            (MealType.Lunch, 12, [Item(RiceFoodId, "Cơm trắng", 220), Item(ChickenFoodId, "Ức gà", 180), Item(AvocadoFoodId, "Bơ", 50)], MealLogSource.Manual),
            (MealType.Dinner, 19, [Item(RiceFoodId, "Cơm trắng", 200), Item(ChickenFoodId, "Ức gà", 200), Item(AvocadoFoodId, "Bơ", 80)], MealLogSource.Manual),
        ]);

        // 2–13 ngày trước — biến thiên adherence
        var patterns = new[]
        {
            (day: -2, rice: 180, chicken: 140, avocado: 40, meals: 3),
            (day: -3, rice: 150, chicken: 100, avocado: 30, meals: 2),
            (day: -4, rice: 220, chicken: 200, avocado: 70, meals: 3),
            (day: -5, rice: 160, chicken: 120, avocado: 0, meals: 2),
            (day: -6, rice: 200, chicken: 180, avocado: 50, meals: 3),
            (day: -7, rice: 140, chicken: 90, avocado: 20, meals: 2),
            (day: -8, rice: 230, chicken: 210, avocado: 80, meals: 3),
            (day: -9, rice: 170, chicken: 130, avocado: 40, meals: 2),
            (day: -10, rice: 210, chicken: 190, avocado: 60, meals: 3),
            (day: -11, rice: 150, chicken: 100, avocado: 30, meals: 2),
            (day: -12, rice: 240, chicken: 220, avocado: 90, meals: 3),
            (day: -13, rice: 160, chicken: 110, avocado: 25, meals: 2),
        };

        foreach (var p in patterns)
        {
            var dayMeals = new List<(MealType, int, (Guid, string, decimal, int, decimal, decimal, decimal)[], MealLogSource)>
            {
                (MealType.Breakfast, 7, [Item(RiceFoodId, "Cơm trắng", p.rice * 0.45m), Item(ChickenFoodId, "Ức gà", p.chicken * 0.4m)], MealLogSource.Manual),
            };
            if (p.meals >= 2)
                dayMeals.Add((MealType.Lunch, 12, [Item(RiceFoodId, "Cơm trắng", p.rice * 0.55m), Item(ChickenFoodId, "Ức gà", p.chicken * 0.6m), Item(AvocadoFoodId, "Bơ", p.avocado)], MealLogSource.Manual));
            if (p.meals >= 3)
                dayMeals.Add((MealType.Dinner, 19, [Item(RiceFoodId, "Cơm trắng", p.rice * 0.5m), Item(ChickenFoodId, "Ức gà", p.chicken * 0.5m)], MealLogSource.AiSuggested));
            AddDay(p.day, dayMeals);
        }

        return logs;
    }

    public static IReadOnlyList<DailyNutritionSummary> GetDemoDailySummaries(DateTimeOffset utcNow)
    {
        var mealsByDate = GetDemoMealLogs(utcNow)
            .GroupBy(m => DateOnly.FromDateTime(m.LoggedAt.Date))
            .ToDictionary(g => g.Key, g => g.ToList());

        var summaries = new List<DailyNutritionSummary>();
        var waterByDay = new Dictionary<int, int>
        {
            [0] = 1200, [-1] = 2400, [-2] = 2100, [-3] = 1600, [-4] = 2300,
            [-5] = 1800, [-6] = 2200, [-7] = 1500, [-8] = 2500, [-9] = 1700,
            [-10] = 2000, [-11] = 1400, [-12] = 2600, [-13] = 1650,
        };

        for (var dayOffset = 0; dayOffset >= -13; dayOffset--)
        {
            var date = DateOnly.FromDateTime(utcNow.Date.AddDays(dayOffset));
            mealsByDate.TryGetValue(date, out var meals);
            meals ??= [];

            summaries.Add(new DailyNutritionSummary
            {
                Id = Guid.Parse($"a2000001-0000-4000-8000-{(14 + dayOffset):D012}"),
                UserId = DemoUserId,
                Date = date,
                TargetCalories = TargetCalories,
                TargetProteinGram = TargetProtein,
                TargetCarbGram = TargetCarb,
                TargetFatGram = TargetFat,
                ConsumedCalories = meals.Sum(m => m.TotalCalories),
                ConsumedProteinGram = meals.Sum(m => m.TotalProteinGram),
                ConsumedCarbGram = meals.Sum(m => m.TotalCarbGram),
                ConsumedFatGram = meals.Sum(m => m.TotalFatGram),
                WaterIntakeMl = waterByDay.GetValueOrDefault(dayOffset, 1800),
                MealsLoggedCount = meals.Count,
            });
        }

        return summaries;
    }

    private static (Guid id, string name, decimal g, int cal, decimal p, decimal c, decimal f) Item(
        Guid foodId, string name, decimal grams) =>
        foodId switch
        {
            var id when id == RiceFoodId => (id, name, grams, Scale(130, grams), Scale(2.7m, grams), Scale(28m, grams), Scale(0.3m, grams)),
            var id when id == ChickenFoodId => (id, name, grams, Scale(165, grams), Scale(31m, grams), 0, Scale(3.6m, grams)),
            var id when id == AvocadoFoodId => (id, name, grams, Scale(160, grams), Scale(2m, grams), Scale(9m, grams), Scale(15m, grams)),
            _ => (foodId, name, grams, 0, 0, 0, 0),
        };

    private static int Scale(int per100, decimal grams) =>
        (int)Math.Round(per100 * grams / 100m, MidpointRounding.AwayFromZero);

    private static decimal Scale(decimal per100, decimal grams) =>
        Math.Round(per100 * grams / 100m, 1, MidpointRounding.AwayFromZero);

    private static async Task SeedCollectionAsync<T>(
        IMongoCollection<T> collection,
        IReadOnlyList<T> seeds,
        CancellationToken cancellationToken) where T : BaseMongoEntity
    {
        if (seeds.Count == 0)
            return;

        var ids = seeds.Select(s => s.Id).ToList();
        var existingIds = await collection
            .Find(Builders<T>.Filter.In(x => x.Id, ids))
            .Project(x => x.Id)
            .ToListAsync(cancellationToken);

        var toInsert = seeds.Where(s => !existingIds.Contains(s.Id)).ToList();
        if (toInsert.Count == 0)
            return;

        var now = DateTimeOffset.UtcNow;
        foreach (var entity in toInsert)
        {
            entity.CreatedAt = now;
            entity.UpdatedAt = now;
        }

        await collection.InsertManyAsync(toInsert, cancellationToken: cancellationToken);
    }
}
