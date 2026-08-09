using Libs.Shared.Enums;
using Libs.Shared.Seed;
using MongoDB.Driver;
using Nutrition.Domain.Enums;
using Nutrition.Domain.Models;

namespace Nutrition.Infrastructure.Persistence.Seed;

/// <summary>
/// Nutrition seed: 25 Vietnamese FoodItems + 14-day MealLog / DailyNutritionSummary for users 02–21.
/// All IDs are deterministic for idempotent re-seeding.
/// </summary>
public static class NutritionSeedData
{
    // ─── Stable ID helpers ───────────────────────────────────────────────────
    // FoodItem:         f1000{n:D3}-0000-4000-a000-000000000000
    // MealLog:          a3{uu:D2}{slot:D2}{ml:D2}00-0000-4000-a000-000000000000  (8 + rest)
    // DailyNutrition:   a4{uu:D2}{slot:D4}-0000-4000-a000-000000000000

    private static Guid FoodId(int n) =>
        Guid.Parse($"f1000{n:D3}-0000-4000-a000-000000000000");

    // slot = day-index within the user's logged-days list (00–13); ml = meal-index (01–05)
    // First GUID segment = 8 hex chars: a3 + uu(2) + slot(2) + ml(2) = 8 ✓
    private static Guid MealLogId(int uu, int slot, int ml) =>
        Guid.Parse($"a3{uu:D2}{slot:D2}{ml:D2}-0000-4000-a000-000000000000");

    private static Guid SummaryId(int uu, int slot) =>
        Guid.Parse($"a4{uu:D2}{slot:D4}-0000-4000-a000-000000000000");

    // ─── Food macros per 100g (Cal, Protein, Carb, Fat) ─────────────────────
    private static readonly (int Cal, decimal P, decimal C, decimal F)[] FoodMacros =
    [
        default,                           // 0 unused
        (130,  2.7m, 28.0m,  0.3m),      // 01 Cơm trắng
        (111,  2.6m, 22.8m,  0.9m),      // 02 Cơm gạo lứt
        (165, 31.0m,  0.0m,  3.6m),      // 03 Ức gà
        (208, 20.0m,  0.0m, 13.0m),      // 04 Cá hồi
        (143, 12.5m,  1.1m,  9.7m),      // 05 Trứng gà
        (389, 17.0m, 66.0m,  7.0m),      // 06 Yến mạch
        ( 86,  1.6m, 20.0m,  0.1m),      // 07 Khoai lang
        ( 89,  1.1m, 23.0m,  0.3m),      // 08 Chuối
        (160,  2.0m,  9.0m, 15.0m),      // 09 Bơ
        (100, 10.0m,  4.0m,  0.4m),      // 10 Sữa chua Hy Lạp
        ( 90,  4.4m, 11.0m,  2.4m),      // 11 Phở bò
        ( 84,  4.0m, 12.0m,  2.0m),      // 12 Bún bò
        (190,  8.0m, 28.0m,  5.0m),      // 13 Bánh mì
        (400, 80.0m, 10.0m,  5.0m),      // 14 Whey protein
        ( 19,  2.6m,  1.0m,  0.2m),      // 15 Rau muống luộc
        (579, 21.0m, 20.0m, 50.0m),      // 16 Hạnh nhân
        ( 83,  8.3m,  7.3m,  1.7m),      // 17 Smoothie protein (per 100ml)
        (127, 10.0m,  6.7m,  5.3m),      // 18 Salad ức gà
        (138,  6.3m, 17.5m,  3.8m),      // 19 Cơm tấm
        (270, 26.0m,  0.0m, 18.0m),      // 20 Bò bít tết
        (120,  4.4m, 21.3m,  1.9m),      // 21 Quinoa
        ( 40,  1.3m,  4.0m,  2.0m),      // 22 Sữa hạt (per 100 ml)
        ( 19,  0.2m,  4.5m,  0.1m),      // 23 Nước dừa (per 100 ml)
        (485, 16.5m, 42.0m, 31.0m),      // 24 Hạt chia
        ( 72,  2.8m, 12.3m,  1.5m),      // 25 Cháo yến mạch
    ];

    private static readonly string[] FoodNames =
    [
        string.Empty,
        "Cơm trắng", "Cơm gạo lứt", "Ức gà", "Cá hồi", "Trứng gà",
        "Yến mạch", "Khoai lang", "Chuối", "Bơ", "Sữa chua Hy Lạp",
        "Phở bò", "Bún bò", "Bánh mì", "Whey protein", "Rau muống luộc",
        "Hạnh nhân", "Smoothie protein", "Salad ức gà", "Cơm tấm", "Bò bít tết",
        "Quinoa", "Sữa hạt", "Nước dừa", "Hạt chia", "Cháo yến mạch",
    ];

    // ─── User nutrition targets §1.2 (Nn, TargetCal, P, C, F, LogDays, WaterBase) ─
    private static readonly (int Nn, int Cal, int P, int C, int F, int LogDays, int WaterBase)[] UserTargets =
    [
        (2,  2850, 165, 320, 75,  10, 2200),
        (3,  1650, 110, 150, 50,   6, 1700),
        (4,  3100, 190, 300, 80,  14, 2800),
        (5,  1500,  90, 170, 50,   5, 1600),
        (6,  2900, 130, 380, 70,  11, 2800),
        (7,  1800, 120, 160, 55,  10, 2200),
        (8,  3300, 210, 330, 85,  14, 3000),
        (9,  2300, 140, 230, 65,   7, 2000),
        (10, 1900, 130, 180, 58,  10, 2100),
        (11, 2100, 150, 180, 60,   5, 1800),
        (12, 1950, 125, 210, 55,  11, 2200),
        (13, 2000, 120, 220, 60,   6, 1800),
        (14, 1850, 105, 240, 52,   9, 2000),
        (15, 3200, 200, 320, 82,  14, 3200),
        (16, 1600, 100, 150, 48,   6, 1700),
        (17, 2600, 165, 250, 70,  11, 2300),
        (18, 1550,  85, 180, 48,   5, 1600),
        (19, 3000, 125, 400, 68,  14, 3500),
        (20, 1900, 120, 190, 55,  13, 2200),
        (21, 2700, 170, 260, 72,  13, 2400),
    ];

    // ─── Meal templates ──────────────────────────────────────────────────────
    // Each template entry: (MealType, HourOfDay, Source, (foodN, grams)[])
    private static readonly (MealType Mt, int H, MealLogSource Src, (int F, decimal G)[] Items)[][] MuscleMeals =
    [
        [
            (MealType.Breakfast,    7, MealLogSource.Manual,        [(6, 80m), (5, 120m), (8, 120m)]),
            (MealType.Lunch,       12, MealLogSource.Manual,        [(2, 200m), (3, 200m), (15, 100m)]),
            (MealType.Snack,       15, MealLogSource.AiSuggested,   [(14, 30m), (8, 100m)]),
            (MealType.Dinner,      19, MealLogSource.Manual,        [(2, 200m), (20, 150m), (15, 80m)]),
            (MealType.PostWorkout, 21, MealLogSource.Manual,        [(14, 30m), (7, 100m)]),
        ],
        [
            (MealType.Breakfast,    7, MealLogSource.Manual,        [(6, 100m), (5, 120m), (9, 50m)]),
            (MealType.Lunch,       12, MealLogSource.Manual,        [(1, 200m), (3, 200m), (15, 100m)]),
            (MealType.PreWorkout,  16, MealLogSource.AiSuggested,   [(8, 120m), (14, 25m)]),
            (MealType.Dinner,      20, MealLogSource.Manual,        [(2, 180m), (20, 150m), (15, 80m)]),
        ],
        [
            (MealType.Breakfast,    7, MealLogSource.Manual,        [(6, 80m), (5, 100m)]),
            (MealType.Lunch,       12, MealLogSource.Manual,        [(2, 200m), (3, 180m), (15, 100m)]),
            (MealType.Dinner,      19, MealLogSource.Manual,        [(1, 200m), (3, 200m), (7, 100m)]),
        ],
    ];

    private static readonly (MealType Mt, int H, MealLogSource Src, (int F, decimal G)[] Items)[][] EnduranceMeals =
    [
        [
            (MealType.Breakfast,    6, MealLogSource.Manual,        [(6, 100m), (8, 120m), (7, 100m)]),
            (MealType.PreWorkout,   9, MealLogSource.AiSuggested,   [(8, 120m), (23, 330m)]),
            (MealType.Lunch,       13, MealLogSource.Manual,        [(1, 250m), (4, 120m), (15, 100m)]),
            (MealType.Snack,       16, MealLogSource.Manual,        [(8, 120m), (7, 100m)]),
            (MealType.Dinner,      20, MealLogSource.Manual,        [(2, 200m), (4, 150m), (15, 80m)]),
        ],
        [
            (MealType.Breakfast,    6, MealLogSource.Manual,        [(6, 100m), (5, 120m), (8, 100m)]),
            (MealType.Lunch,       12, MealLogSource.Manual,        [(1, 250m), (3, 180m), (15, 100m)]),
            (MealType.Snack,       15, MealLogSource.AiSuggested,   [(17, 200m), (8, 120m)]),
            (MealType.Dinner,      19, MealLogSource.Manual,        [(2, 220m), (4, 150m), (15, 80m)]),
        ],
    ];

    private static readonly (MealType Mt, int H, MealLogSource Src, (int F, decimal G)[] Items)[][] RecompMeals =
    [
        [
            (MealType.Breakfast,    7, MealLogSource.Manual,        [(6, 80m), (5, 100m), (10, 150m)]),
            (MealType.Lunch,       12, MealLogSource.Manual,        [(21, 100m), (4, 120m), (18, 100m)]),
            (MealType.Snack,       15, MealLogSource.AiSuggested,   [(10, 150m), (8, 100m)]),
            (MealType.Dinner,      19, MealLogSource.Manual,        [(2, 150m), (4, 120m), (9, 50m)]),
        ],
        [
            (MealType.Breakfast,    7, MealLogSource.Manual,        [(6, 80m), (5, 100m), (8, 100m)]),
            (MealType.Lunch,       12, MealLogSource.FromMarketplaceOrder, [(18, 250m), (21, 80m)]),
            (MealType.Dinner,      19, MealLogSource.Manual,        [(2, 150m), (3, 150m), (15, 100m)]),
        ],
    ];

    private static readonly (MealType Mt, int H, MealLogSource Src, (int F, decimal G)[] Items)[][] IntermediateMeals =
    [
        [
            (MealType.Breakfast,    7, MealLogSource.Manual,        [(6, 80m), (5, 100m), (8, 100m)]),
            (MealType.Lunch,       12, MealLogSource.Manual,        [(2, 150m), (3, 150m), (15, 100m)]),
            (MealType.Dinner,      19, MealLogSource.Manual,        [(1, 150m), (3, 150m), (7, 100m)]),
        ],
        [
            (MealType.Breakfast,    7, MealLogSource.Manual,        [(6, 80m), (10, 150m), (8, 120m)]),
            (MealType.Lunch,       12, MealLogSource.FromMarketplaceOrder, [(18, 250m)]),
            (MealType.Snack,       15, MealLogSource.AiSuggested,   [(17, 200m), (8, 100m)]),
            (MealType.Dinner,      19, MealLogSource.Manual,        [(2, 150m), (4, 120m)]),
        ],
        [
            (MealType.Breakfast,    8, MealLogSource.Manual,        [(6, 80m), (5, 80m)]),
            (MealType.Lunch,       12, MealLogSource.Manual,        [(11, 400m), (15, 100m)]),
            (MealType.Dinner,      19, MealLogSource.Manual,        [(1, 150m), (3, 130m), (9, 50m)]),
        ],
    ];

    private static readonly (MealType Mt, int H, MealLogSource Src, (int F, decimal G)[] Items)[][] RunnerMeals =
    [
        [
            (MealType.Breakfast,    7, MealLogSource.Manual,        [(1, 150m), (3, 120m)]),
            (MealType.Lunch,       12, MealLogSource.Manual,        [(1, 180m), (3, 150m), (15, 100m)]),
            (MealType.Dinner,      20, MealLogSource.Manual,        [(12, 400m), (15, 80m)]),
        ],
        [
            (MealType.Breakfast,    7, MealLogSource.Manual,        [(6, 80m), (5, 100m)]),
            (MealType.Lunch,       12, MealLogSource.Manual,        [(1, 180m), (3, 150m)]),
            (MealType.Dinner,      20, MealLogSource.Manual,        [(1, 180m), (3, 130m)]),
        ],
    ];

    private static readonly (MealType Mt, int H, MealLogSource Src, (int F, decimal G)[] Items)[][] LossFatFemaleMeals =
    [
        [
            (MealType.Breakfast,    8, MealLogSource.Manual,        [(18, 200m), (10, 150m)]),
            (MealType.Lunch,       12, MealLogSource.Manual,        [(4, 100m), (25, 200m), (15, 100m)]),
        ],
        [
            (MealType.Breakfast,    9, MealLogSource.Manual,        [(25, 200m), (5, 100m)]),
            (MealType.Lunch,       13, MealLogSource.AiSuggested,   [(18, 200m), (7, 100m)]),
            (MealType.Dinner,      19, MealLogSource.Manual,        [(4, 100m), (15, 80m), (9, 30m)]),
        ],
    ];

    private static readonly (MealType Mt, int H, MealLogSource Src, (int F, decimal G)[] Items)[][] BeginnerMeals =
    [
        [
            (MealType.Breakfast,    8, MealLogSource.Manual,        [(25, 300m), (5, 100m)]),
            (MealType.Lunch,       12, MealLogSource.Manual,        [(1, 200m), (3, 120m), (15, 80m)]),
        ],
        [
            (MealType.Breakfast,    9, MealLogSource.Manual,        [(13, 200m), (5, 60m)]),
            (MealType.Lunch,       13, MealLogSource.Manual,        [(19, 400m)]),
            (MealType.Dinner,      20, MealLogSource.Manual,        [(1, 200m), (3, 100m)]),
        ],
        [
            (MealType.Lunch,       12, MealLogSource.Manual,        [(11, 500m)]),
            (MealType.Dinner,      19, MealLogSource.Manual,        [(1, 150m), (15, 80m)]),
        ],
    ];

    // ─── Entry point ─────────────────────────────────────────────────────────
    public static async Task SeedAsync(IMongoDatabase database, CancellationToken cancellationToken = default)
    {
        await SeedFoodItemsAsync(database, cancellationToken);
        await SeedUserNutritionAsync(database, cancellationToken);
    }

    // ─── FoodItems ────────────────────────────────────────────────────────────
    private static async Task SeedFoodItemsAsync(IMongoDatabase database, CancellationToken ct)
    {
        var collection = database.GetCollection<FoodItem>("FoodItems");
        if (await collection.Find(_ => true).AnyAsync(ct))
            return;

        await collection.InsertManyAsync(GetSystemFoodItems(), cancellationToken: ct);
    }

    public static IReadOnlyList<FoodItem> GetSystemFoodItems() =>
    [
        FI(1,  "Cơm trắng",        "White rice",           "com-trang",        FoodCategory.Grains,      100m, []),
        FI(2,  "Cơm gạo lứt",      "Brown rice",           "com-gao-lut",      FoodCategory.Grains,      100m, []),
        FI(3,  "Ức gà",            "Chicken breast",        "uc-ga",            FoodCategory.Protein,     100m, [DietaryTag.HighProtein, DietaryTag.LowCarb]),
        FI(4,  "Cá hồi",           "Salmon",                "ca-hoi",           FoodCategory.Protein,     100m, [DietaryTag.HighProtein]),
        FI(5,  "Trứng gà",         "Egg",                   "trung-ga",         FoodCategory.Protein,     100m, [DietaryTag.HighProtein]),
        FI(6,  "Yến mạch",         "Oatmeal",               "yen-mach",         FoodCategory.Grains,      100m, [DietaryTag.Vegan]),
        FI(7,  "Khoai lang",       "Sweet potato",          "khoai-lang",       FoodCategory.Grains,      100m, [DietaryTag.Vegan, DietaryTag.GlutenFree]),
        FI(8,  "Chuối",            "Banana",                "chuoi",            FoodCategory.Fruit,       120m, [DietaryTag.Vegan]),
        FI(9,  "Bơ",               "Avocado",               "bo",               FoodCategory.Fat,         100m, [DietaryTag.Vegan, DietaryTag.LowCarb]),
        FI(10, "Sữa chua Hy Lạp",  "Greek yogurt",          "sua-chua-hy-lac",  FoodCategory.Dairy,       150m, [DietaryTag.HighProtein]),
        FI(11, "Phở bò",           "Beef pho",              "pho-bo",           FoodCategory.PreparedMeal, 500m, []),
        FI(12, "Bún bò",           "Beef rice noodles",     "bun-bo",           FoodCategory.PreparedMeal, 500m, []),
        FI(13, "Bánh mì",          "Vietnamese banh mi",    "banh-mi",          FoodCategory.Grains,      200m, []),
        FI(14, "Whey protein",     "Whey protein powder",   "whey-protein",     FoodCategory.Supplement,   30m, [DietaryTag.HighProtein]),
        FI(15, "Rau muống luộc",   "Boiled water spinach",  "rau-muong-luoc",   FoodCategory.Vegetable,   100m, [DietaryTag.Vegan, DietaryTag.LowCarb]),
        FI(16, "Hạnh nhân",        "Almonds",               "hanh-nhan",        FoodCategory.Fat,          30m, [DietaryTag.Vegan]),
        FI(17, "Smoothie protein", "Protein smoothie",      "smoothie-protein", FoodCategory.Supplement,  300m, [DietaryTag.HighProtein]),
        FI(18, "Salad ức gà",      "Chicken breast salad",  "salad-uc-ga",      FoodCategory.PreparedMeal, 300m, [DietaryTag.HighProtein, DietaryTag.LowCarb]),
        FI(19, "Cơm tấm",          "Broken rice dish",      "com-tam",          FoodCategory.PreparedMeal, 400m, []),
        FI(20, "Bò bít tết",       "Beef steak",            "bo-bit-tet",       FoodCategory.Protein,     150m, [DietaryTag.HighProtein, DietaryTag.LowCarb]),
        FI(21, "Quinoa",           "Quinoa",                "quinoa",           FoodCategory.Grains,      100m, [DietaryTag.Vegan, DietaryTag.GlutenFree]),
        FI(22, "Sữa hạt",         "Nut milk",              "sua-hat",          FoodCategory.Dairy,       250m, [DietaryTag.Vegan, DietaryTag.DairyFree]),
        FI(23, "Nước dừa",        "Coconut water",         "nuoc-dua",         FoodCategory.Beverage,    330m, [DietaryTag.Vegan]),
        FI(24, "Hạt chia",        "Chia seeds",            "hat-chia",         FoodCategory.Fat,          20m, [DietaryTag.Vegan]),
        FI(25, "Cháo yến mạch",   "Oatmeal porridge",      "chao-yen-mach",    FoodCategory.Grains,      300m, [DietaryTag.Vegan]),
    ];

    private static FoodItem FI(int n, string nameVi, string nameEn, string slug, FoodCategory cat,
        decimal servingSizeGram, DietaryTag[] tags) =>
        new()
        {
            Id = FoodId(n),
            NameVi = nameVi,
            NameEn = nameEn,
            Slug = slug,
            Category = cat,
            ServingSizeGram = servingSizeGram,
            CaloriesPer100g = FoodMacros[n].Cal,
            ProteinPer100g = FoodMacros[n].P,
            CarbPer100g = FoodMacros[n].C,
            FatPer100g = FoodMacros[n].F,
            DietaryTags = [.. tags],
            Source = FoodDataSource.System,
            IsVerified = true,
            IsActive = true,
        };

    // ─── Per-user nutrition ───────────────────────────────────────────────────
    private static async Task SeedUserNutritionAsync(IMongoDatabase database, CancellationToken ct)
    {
        var mealColl = database.GetCollection<MealLog>("MealLogs");
        var summaryColl = database.GetCollection<DailyNutritionSummary>("DailyNutritionSummaries");
        var utcNow = DateTimeOffset.UtcNow;

        foreach (var (nn, calT, pT, cT, fT, logDays, waterBase) in UserTargets)
        {
            var userId = SyncSeedUsers.Id(nn);
            var templates = TemplatesForUser(nn);
            var dayOffsets = LoggedDayOffsets(nn, logDays).ToList();

            var mealLogs = new List<MealLog>();
            var summaries = new List<DailyNutritionSummary>();

            for (var slot = 0; slot < dayOffsets.Count; slot++)
            {
                var dayOff = dayOffsets[slot];
                var template = templates[slot % templates.Length];
                var date = DateOnly.FromDateTime(utcNow.Date.AddDays(-dayOff));
                var dayMeals = new List<MealLog>();
                var mealN = 1;
                var compliance = ComplianceFactor(nn, slot);

                foreach (var (mt, hour, src, itemDefs) in template)
                {
                    var loggedAt = new DateTimeOffset(
                        utcNow.Date.AddDays(-dayOff).AddHours(hour), TimeSpan.Zero);

                    var items = itemDefs
                        .Select(x => CalcItem(x.F, x.G * compliance))
                        .ToList();

                    dayMeals.Add(new MealLog
                    {
                        Id = MealLogId(nn, slot, mealN++),
                        UserId = userId,
                        MealType = mt,
                        LoggedAt = loggedAt,
                        Source = src,
                        Items = items,
                        TotalCalories = items.Sum(i => i.Calories),
                        TotalProteinGram = items.Sum(i => i.ProteinGram),
                        TotalCarbGram = items.Sum(i => i.CarbGram),
                        TotalFatGram = items.Sum(i => i.FatGram),
                    });
                }

                mealLogs.AddRange(dayMeals);
                summaries.Add(new DailyNutritionSummary
                {
                    Id = SummaryId(nn, slot),
                    UserId = userId,
                    Date = date,
                    TargetCalories = calT,
                    TargetProteinGram = pT,
                    TargetCarbGram = cT,
                    TargetFatGram = fT,
                    ConsumedCalories = dayMeals.Sum(m => m.TotalCalories),
                    ConsumedProteinGram = dayMeals.Sum(m => m.TotalProteinGram),
                    ConsumedCarbGram = dayMeals.Sum(m => m.TotalCarbGram),
                    ConsumedFatGram = dayMeals.Sum(m => m.TotalFatGram),
                    WaterIntakeMl = waterBase + (slot % 3 == 0 ? 200 : slot % 3 == 1 ? -100 : 0),
                    MealsLoggedCount = dayMeals.Count,
                });
            }

            await SeedCollectionAsync(mealColl, mealLogs, ct);
            await SeedCollectionAsync(summaryColl, summaries, ct);
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private static (MealType Mt, int H, MealLogSource Src, (int F, decimal G)[] Items)[][] TemplatesForUser(int nn) =>
        nn switch
        {
            8 or 15 or 2 or 21 => MuscleMeals,
            4 or 6 or 19       => EnduranceMeals,
            10 or 17 or 20     => RecompMeals,
            7 or 12 or 14      => IntermediateMeals,
            9                  => RunnerMeals,
            3                  => LossFatFemaleMeals,
            _                  => BeginnerMeals,
        };

    /// <summary>
    /// Returns day offsets (0 = today, N = N days ago) for which this user has logged data.
    /// Advanced: near-consecutive; beginner: sparse.
    /// </summary>
    private static IEnumerable<int> LoggedDayOffsets(int nn, int logDays)
    {
        // Advanced users: fill from today backwards, possibly skipping one
        if (logDays >= 13)
        {
            var skip = logDays == 14 ? -1 : nn % 14;
            for (var d = 0; d <= 13; d++)
                if (d != skip)
                    yield return d;
            yield break;
        }

        // Others: deterministic spread across 14 days
        var seen = new SortedSet<int>();
        for (var i = 0; i < logDays; i++)
        {
            var idx = (int)Math.Round(i * 14.0 / logDays) % 14;
            while (seen.Contains(idx)) idx = (idx + 1) % 14;
            seen.Add(idx);
        }

        foreach (var d in seen)
            yield return d;
    }

    private static decimal ComplianceFactor(int nn, int slot)
    {
        // Advanced: 0.94–1.04; Intermediate: 0.85–1.10; Beginner: 0.65–1.20
        if (nn is 4 or 8 or 15 or 19 or 20 or 21)
            return 0.94m + (slot % 5) * 0.025m;
        if (nn is 2 or 6 or 7 or 10 or 12 or 14 or 17)
            return 0.85m + (slot % 6) * 0.05m;
        return 0.65m + (slot % 8) * 0.07m;
    }

    private static MealLog.MealLogItem CalcItem(int foodN, decimal grams)
    {
        var m = FoodMacros[foodN];
        return new MealLog.MealLogItem
        {
            FoodItemId = FoodId(foodN),
            FoodNameSnapshot = FoodNames[foodN],
            QuantityGram = Math.Round(grams, 0),
            Calories = (int)Math.Round(m.Cal * grams / 100m),
            ProteinGram = Math.Round(m.P * grams / 100m, 1),
            CarbGram = Math.Round(m.C * grams / 100m, 1),
            FatGram = Math.Round(m.F * grams / 100m, 1),
        };
    }

    private static async Task SeedCollectionAsync<T>(
        IMongoCollection<T> collection,
        IReadOnlyList<T> seeds,
        CancellationToken ct) where T : BaseMongoEntity
    {
        if (seeds.Count == 0) return;

        var ids = seeds.Select(s => s.Id).ToList();
        var existing = await collection
            .Find(Builders<T>.Filter.In(x => x.Id, ids))
            .Project(x => x.Id)
            .ToListAsync(ct);

        var toInsert = seeds.Where(s => !existing.Contains(s.Id)).ToList();
        if (toInsert.Count == 0) return;

        var now = DateTimeOffset.UtcNow;
        foreach (var e in toInsert) { e.CreatedAt = now; e.UpdatedAt = now; }
        await collection.InsertManyAsync(toInsert, cancellationToken: ct);
    }
}
