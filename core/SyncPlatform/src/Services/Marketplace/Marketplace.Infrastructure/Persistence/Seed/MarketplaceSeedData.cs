using Libs.Shared.Common;
using Libs.Shared.Enums;
using Libs.Shared.Seed;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Models;
using MongoDB.Driver;
using MongoDB.Driver.GeoJsonObjectModel;

namespace Marketplace.Infrastructure.Persistence.Seed;

/// <summary>
/// Marketplace seed: 6 real HCMC partners + menus + reviews + recomputed ratings.
/// IDs are deterministic for idempotent re-seeding.
/// </summary>
public static class MarketplaceSeedData
{
    // ─── Partner IDs ──────────────────────────────────────────────────────────
    // All GUID first-segments use only hex chars (0-9, a-f).
    // Pattern: a500{n:D4}-0000-4000-a000-000000000000  (a,5,0,0 + 4 decimal digits = 8 hex)
    private static Guid PartnerId(int n) =>
        Guid.Parse($"a500{n:D4}-0000-4000-a000-000000000000");

    // MenuItem: b5{pp:D2}{item:D2}00-0000-4000-a000-000000000000  (8 hex chars)
    private static Guid MenuItemId(int pp, int item) =>
        Guid.Parse($"b5{pp:D2}{item:D2}00-0000-4000-a000-000000000000");

    // Review: c5{pp:D2}{seq:D4}-0000-4000-a000-000000000000  (8 hex)
    private static Guid ReviewId(int pp, int seq) =>
        Guid.Parse($"c5{pp:D2}{seq:D4}-0000-4000-a000-000000000000");

    // ─── Seed marker (idempotency check) ─────────────────────────────────────
    private static readonly Guid SeedMarkerId = PartnerId(1);

    // ─── Unsplash image URLs ──────────────────────────────────────────────────
    private const string ImgRestaurant1 = "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1080&q=80&auto=format";
    private const string ImgRestaurant2 = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=1080&q=80&auto=format";
    private const string ImgSalad1      = "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=1080&q=80&auto=format";
    private const string ImgSalad2      = "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=1080&q=80&auto=format";
    private const string ImgMealPrep1   = "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=1080&q=80&auto=format";
    private const string ImgMealPrep2   = "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=1080&q=80&auto=format";
    private const string ImgChicken     = "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=1080&q=80&auto=format";
    private const string ImgBowl        = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=1080&q=80&auto=format";

    // ─── Operating hours helper ───────────────────────────────────────────────
    private static List<Partner.OperatingHour> WeekdayHours(string open = "07:00", string close = "21:00") =>
        Enumerable.Range(1, 7).Select(d => new Partner.OperatingHour
        {
            DayOfWeek = d,
            OpenTime = open,
            CloseTime = close,
            IsClosed = d == 7, // Sunday closed
        }).ToList();

    // ─── Entry point ──────────────────────────────────────────────────────────
    public static async Task SeedAsync(IMongoDatabase database, CancellationToken cancellationToken = default)
    {
        var partners = database.GetCollection<Partner>("Partners");
        if (await partners.Find(x => x.Id == SeedMarkerId).AnyAsync(cancellationToken))
            return;

        var partnerList = BuildPartners();
        await partners.InsertManyAsync(partnerList, cancellationToken: cancellationToken);

        var menuItems = BuildMenuItems(partnerList);
        var menuColl = database.GetCollection<FoodMenuItem>("FoodMenuItems");
        await menuColl.InsertManyAsync(menuItems, cancellationToken: cancellationToken);

        var reviews = BuildReviews(partnerList, menuItems);
        var reviewColl = database.GetCollection<Review>("Reviews");
        await reviewColl.InsertManyAsync(reviews, cancellationToken: cancellationToken);

        // Recompute ratings from actual reviews
        await RecomputeRatingsAsync(partners, menuColl, reviews, cancellationToken);
    }

    // ─── Partners ─────────────────────────────────────────────────────────────
    private static List<Partner> BuildPartners() =>
    [
        new Partner
        {
            Id = PartnerId(1),
            OwnerUserId = SyncSeedUsers.User20,
            Name = "KNMEAL – Healthy & Eat Clean",
            Slug = "knmeal-healthy-eat-clean",
            Type = PartnerType.Restaurant,
            Description = "Nhà hàng eat clean chuyên các món ức gà, cá hồi, cơm gạo lứt — calo chuẩn cho người tập gym.",
            LogoUrl = ImgSalad1,
            CoverImageUrl = ImgRestaurant1,
            Email = "hello@knmeal.vn",
            PhoneNumber = "0901364681",
            Address = "49 Trần Hữu Trang, P.11, Phú Nhuận, TP.HCM",
            Location = GeoPoint(106.6800, 10.7930),
            ServiceRadiusKm = 6,
            OperatingHours = WeekdayHours(),
            CommissionRate = 0.12m,
            Status = PartnerStatus.Active,
            RatingAverage = 0,
            RatingCount = 0,
            IsAiRecommendable = true,
        },
        new Partner
        {
            Id = PartnerId(2),
            OwnerUserId = SyncSeedUsers.User20,
            Name = "Eat More Salad",
            Slug = "eat-more-salad",
            Type = PartnerType.CloudKitchen,
            Description = "Cloud kitchen chuyên salad, poke bowl, bữa ăn Vegan và Low-Carb giao tận nơi.",
            LogoUrl = ImgSalad2,
            CoverImageUrl = ImgMealPrep1,
            Email = "order@eatmoresalad.vn",
            PhoneNumber = "0901364681",
            Address = "14/25 Hoàng Duy Khương, P.12, Q.10, TP.HCM",
            Location = GeoPoint(106.6660, 10.7720),
            ServiceRadiusKm = 7,
            OperatingHours = WeekdayHours("08:00", "20:00"),
            CommissionRate = 0.10m,
            Status = PartnerStatus.Active,
            RatingAverage = 0,
            RatingCount = 0,
            IsAiRecommendable = true,
        },
        new Partner
        {
            Id = PartnerId(3),
            OwnerUserId = SyncSeedUsers.User21,
            Name = "Fitfood Việt Nam",
            Slug = "fitfood-viet-nam",
            Type = PartnerType.CloudKitchen,
            Description = "Combo meal-prep cân bằng dinh dưỡng, chia sẵn theo gram — giải pháp cho người tập nghiêm túc.",
            LogoUrl = ImgMealPrep2,
            CoverImageUrl = ImgMealPrep1,
            Email = "info@fitfood.vn",
            PhoneNumber = "0932788120",
            Address = "33 Đường 14, KDC Bình Hưng, Bình Chánh, TP.HCM",
            Location = GeoPoint(106.6600, 10.7280),
            ServiceRadiusKm = 8,
            OperatingHours = WeekdayHours("07:00", "20:00"),
            CommissionRate = 0.12m,
            Status = PartnerStatus.Active,
            RatingAverage = 0,
            RatingCount = 0,
            IsAiRecommendable = true,
        },
        new Partner
        {
            Id = PartnerId(4),
            OwnerUserId = SyncSeedUsers.User21,
            Name = "Insalata Vietnam",
            Slug = "insalata-vietnam",
            Type = PartnerType.Restaurant,
            Description = "Nhà hàng salad phong cách Ý — nguyên liệu tươi, dress light, phù hợp giảm mỡ.",
            LogoUrl = ImgSalad1,
            CoverImageUrl = ImgRestaurant2,
            Email = "hello@insalata.vn",
            PhoneNumber = "0903009066",
            Address = "71/17 Cô Bắc, P.Cô Giang, Q.1, TP.HCM",
            Location = GeoPoint(106.6940, 10.7640),
            ServiceRadiusKm = 5,
            OperatingHours = WeekdayHours("08:00", "21:00"),
            CommissionRate = 0.13m,
            Status = PartnerStatus.Active,
            RatingAverage = 0,
            RatingCount = 0,
            IsAiRecommendable = true,
        },
        new Partner
        {
            Id = PartnerId(5),
            OwnerUserId = SyncSeedUsers.User20,
            Name = "Healthy Eating",
            Slug = "healthy-eating-q8",
            Type = PartnerType.CloudKitchen,
            Description = "Bữa ăn lành mạnh giá bình dân, giao nhanh khu Q.8 — phù hợp văn phòng và gia đình.",
            LogoUrl = ImgBowl,
            CoverImageUrl = ImgMealPrep2,
            Email = "healthyeating.q8@gmail.com",
            PhoneNumber = "0908000058",
            Address = "219 Dương Bá Trạc, Q.8, TP.HCM",
            Location = GeoPoint(106.6870, 10.7490),
            ServiceRadiusKm = 6,
            OperatingHours = WeekdayHours(),
            CommissionRate = 0.10m,
            Status = PartnerStatus.Active,
            RatingAverage = 0,
            RatingCount = 0,
            IsAiRecommendable = true,
        },
        new Partner
        {
            Id = PartnerId(6),
            OwnerUserId = SyncSeedUsers.User21,
            Name = "Hẻm Healthy Food",
            Slug = "hem-healthy-food",
            Type = PartnerType.Restaurant,
            Description = "Quán hẻm healthy theo phong cách street food — ngon, tươi, giá cả phải chăng.",
            LogoUrl = ImgChicken,
            CoverImageUrl = ImgRestaurant1,
            Email = "hemhealthy.q10@gmail.com",
            PhoneNumber = "0903456789",
            Address = "357/11/10 Cách Mạng Tháng 8, P.12, Q.10, TP.HCM",
            Location = GeoPoint(106.6680, 10.7830),
            ServiceRadiusKm = 5,
            OperatingHours = WeekdayHours("07:00", "20:00"),
            CommissionRate = 0.11m,
            Status = PartnerStatus.Active,
            RatingAverage = 0,
            RatingCount = 0,
            IsAiRecommendable = true,
        },
    ];

    // ─── Menu items ───────────────────────────────────────────────────────────
    private static List<FoodMenuItem> BuildMenuItems(List<Partner> partnerList)
    {
        var items = new List<FoodMenuItem>();

        // Partner 1 – KNMEAL
        var p1 = partnerList[0].Id;
        items.AddRange(
        [
            MI(1, 1, p1, "Ức gà áp chảo khoai lang bông cải",   "Seared chicken breast + sweet potato + broccoli",  "uc-ga-ap-chao-knmeal",  79000, 480, 42, 45, 12, [DietaryTag.HighProtein], SpiceLevel.Mild,   ImgChicken),
            MI(1, 2, p1, "Cá hồi teriyaki cơm gạo lứt",         "Salmon teriyaki + brown rice",                      "ca-hoi-teriyaki-knmeal", 129000, 610, 40, 55, 22, [DietaryTag.HighProtein], SpiceLevel.None,   ImgMealPrep1),
            MI(1, 3, p1, "Bò xào rau củ quinoa",                 "Stir-fried beef with vegetables + quinoa",          "bo-xao-rau-cu-knmeal",   99000, 540, 38, 48, 18, [DietaryTag.HighProtein, DietaryTag.LowCarb], SpiceLevel.Medium, ImgMealPrep2),
            MI(1, 4, p1, "Salad ức gà Caesar ít béo",            "Chicken Caesar salad (light dressing)",             "salad-caesar-knmeal",    69000, 380, 30, 20, 16, [DietaryTag.HighProtein], SpiceLevel.None,   ImgSalad1),
            MI(1, 5, p1, "Cơm gà xé healthy",                   "Shredded chicken rice bowl",                        "com-ga-xe-knmeal",       59000, 450, 32, 55, 10, [DietaryTag.HighProtein], SpiceLevel.Mild,   ImgBowl),
            MI(1, 6, p1, "Sinh tố protein chuối bơ",             "Banana avocado protein smoothie",                   "sinh-to-protein-knmeal", 45000, 280, 24, 30,  8, [DietaryTag.HighProtein], SpiceLevel.None,   ImgSalad2),
        ]);

        // Partner 2 – Eat More Salad
        var p2 = partnerList[1].Id;
        items.AddRange(
        [
            MI(2, 1, p2, "Poke Bowl cá hồi tươi",     "Fresh salmon poke bowl",              "poke-bowl-ca-hoi",   95000, 490, 32, 50, 16, [DietaryTag.HighProtein, DietaryTag.GlutenFree], SpiceLevel.None,  ImgSalad1),
            MI(2, 2, p2, "Salad Vegan hạt quinoa",    "Vegan quinoa seeds salad",            "salad-vegan-quinoa", 65000, 310, 14, 42,  9, [DietaryTag.Vegan, DietaryTag.GlutenFree],       SpiceLevel.None,  ImgSalad2),
            MI(2, 3, p2, "Bowl ức gà Low-Carb",       "Chicken breast low-carb bowl",        "bowl-uc-ga-lowcarb", 75000, 380, 35, 18, 15, [DietaryTag.HighProtein, DietaryTag.LowCarb],     SpiceLevel.Mild,  ImgChicken),
            MI(2, 4, p2, "Detox Salad rau xanh",      "Green detox salad",                   "detox-salad-xanh",   55000, 180, 10, 22,  4, [DietaryTag.Vegan, DietaryTag.LowCarb],          SpiceLevel.None,  ImgSalad1),
            MI(2, 5, p2, "Bowl trứng bơ avocado",     "Egg avocado bowl",                    "bowl-trung-bo",      70000, 420, 22, 24, 26, [DietaryTag.LowCarb, DietaryTag.GlutenFree],      SpiceLevel.None,  ImgBowl),
            MI(2, 6, p2, "Sinh tố green detox",       "Green detox smoothie",                "sinh-to-green",      45000, 160,  5, 28,  3, [DietaryTag.Vegan],                               SpiceLevel.None,  ImgMealPrep2),
            MI(2, 7, p2, "Protein Wrap ức gà",        "Chicken breast protein wrap",         "protein-wrap-ga",    79000, 430, 36, 40, 12, [DietaryTag.HighProtein],                         SpiceLevel.Mild,  ImgChicken),
        ]);

        // Partner 3 – Fitfood
        var p3 = partnerList[2].Id;
        items.AddRange(
        [
            MI(3, 1, p3, "Combo Tăng cơ 600kcal",       "Muscle gain combo 600kcal",           "combo-tang-co-600",  89000, 600, 50, 60, 18, [DietaryTag.HighProtein],                         SpiceLevel.Mild,  ImgMealPrep1),
            MI(3, 2, p3, "Combo Giảm mỡ 450kcal",       "Fat loss combo 450kcal",              "combo-giam-mo-450",  79000, 450, 40, 40, 12, [DietaryTag.HighProtein, DietaryTag.LowCarb],     SpiceLevel.None,  ImgMealPrep2),
            MI(3, 3, p3, "Gói Meal-Prep 5 ngày tăng cơ", "5-day muscle gain meal prep pack",   "meal-prep-5day-tang", 389000, 600, 50, 60, 18, [DietaryTag.HighProtein],                        SpiceLevel.Mild,  ImgChicken),
            MI(3, 4, p3, "Gói Meal-Prep 5 ngày giảm mỡ", "5-day fat loss meal prep pack",     "meal-prep-5day-giam", 349000, 450, 40, 40, 12, [DietaryTag.HighProtein, DietaryTag.LowCarb],    SpiceLevel.None,  ImgSalad1),
            MI(3, 5, p3, "Snack protein thanh bơ đậu",  "Peanut butter protein bar",           "snack-protein-bar",  35000, 220, 18, 20,  8, [DietaryTag.HighProtein],                         SpiceLevel.None,  ImgBowl),
            MI(3, 6, p3, "Cháo gà dinh dưỡng",          "Nutritious chicken porridge",         "chao-ga-fitfood",   59000, 350, 24, 42,  7, [DietaryTag.HighProtein, DietaryTag.GlutenFree],  SpiceLevel.None,  ImgMealPrep1),
        ]);

        // Partner 4 – Insalata
        var p4 = partnerList[3].Id;
        items.AddRange(
        [
            MI(4, 1, p4, "Insalata Classica",            "Classic Italian salad",               "insalata-classica",  75000, 320, 12, 28, 18, [DietaryTag.Vegetarian, DietaryTag.GlutenFree], SpiceLevel.None,  ImgSalad1),
            MI(4, 2, p4, "Insalata Tonno e Rucola",      "Tuna arugula salad",                  "insalata-tonno",     85000, 380, 28, 20, 16, [DietaryTag.HighProtein, DietaryTag.LowCarb],    SpiceLevel.None,  ImgSalad2),
            MI(4, 3, p4, "Insalata Pollo Grigliato",     "Grilled chicken Italian salad",       "insalata-pollo",     89000, 410, 32, 25, 15, [DietaryTag.HighProtein],                        SpiceLevel.None,  ImgChicken),
            MI(4, 4, p4, "Caprese Healthy",              "Healthy caprese salad",               "caprese-healthy",    65000, 280, 14, 18, 16, [DietaryTag.Vegetarian, DietaryTag.GlutenFree], SpiceLevel.None,  ImgSalad1),
            MI(4, 5, p4, "Pasta Integrale Pollo",        "Whole wheat pasta with chicken",      "pasta-integrale",    95000, 520, 32, 58, 12, [DietaryTag.HighProtein],                        SpiceLevel.None,  ImgMealPrep1),
            MI(4, 6, p4, "Minestrone Soup Vegan",        "Vegan minestrone soup",               "minestrone-vegan",   55000, 180,  8, 32,  3, [DietaryTag.Vegan],                              SpiceLevel.None,  ImgBowl),
        ]);

        // Partner 5 – Healthy Eating
        var p5 = partnerList[4].Id;
        items.AddRange(
        [
            MI(5, 1, p5, "Cơm ức gà rau củ",     "Chicken breast rice with veggies",    "com-uc-ga-rau-cu-he",  55000, 460, 36, 50, 10, [DietaryTag.HighProtein],    SpiceLevel.Mild, ImgChicken),
            MI(5, 2, p5, "Cháo cá hồi rau",      "Salmon rice porridge",                "chao-ca-hoi-rau",       65000, 380, 28, 42,  8, [DietaryTag.HighProtein],    SpiceLevel.None, ImgMealPrep2),
            MI(5, 3, p5, "Salad gà trứng",        "Chicken egg salad",                   "salad-ga-trung-he",     60000, 340, 28, 18, 16, [DietaryTag.HighProtein, DietaryTag.LowCarb], SpiceLevel.None, ImgSalad1),
            MI(5, 4, p5, "Cơm gạo lứt bò",        "Brown rice with beef",                "com-gao-lut-bo-he",    70000, 520, 34, 52, 14, [DietaryTag.HighProtein],    SpiceLevel.Mild, ImgMealPrep1),
            MI(5, 5, p5, "Soup rau củ thuần chay", "Vegan vegetable soup",               "soup-rau-cu-vegan-he",  40000, 150,  6, 22,  2, [DietaryTag.Vegan],         SpiceLevel.None, ImgBowl),
            MI(5, 6, p5, "Trứng hấp đậu phụ",    "Steamed egg tofu",                    "trung-hap-dau-phu-he",  45000, 250, 18, 10, 14, [DietaryTag.Vegetarian],    SpiceLevel.None, ImgMealPrep2),
        ]);

        // Partner 6 – Hẻm Healthy Food
        var p6 = partnerList[5].Id;
        items.AddRange(
        [
            MI(6, 1, p6, "Gà nướng sả ớt healthy",   "Lemongrass chili grilled chicken",   "ga-nuong-sa-ot-hem",  65000, 420, 36, 28, 14, [DietaryTag.HighProtein],             SpiceLevel.Medium, ImgChicken),
            MI(6, 2, p6, "Bún gà lá chanh",           "Chicken rice noodle with kaffir",    "bun-ga-la-chanh-hem", 55000, 390, 28, 50,  8, [DietaryTag.HighProtein],             SpiceLevel.Mild,   ImgMealPrep1),
            MI(6, 3, p6, "Salad ức gà kiểu Việt",    "Vietnamese-style chicken salad",     "salad-uc-ga-viet-hem",70000, 380, 30, 22, 15, [DietaryTag.HighProtein, DietaryTag.LowCarb], SpiceLevel.Medium, ImgSalad2),
            MI(6, 4, p6, "Cơm tấm sườn healthy",     "Healthy com tam suon",               "com-tam-suon-hem",    65000, 480, 30, 55, 12, [],                                   SpiceLevel.Mild,   ImgBowl),
            MI(6, 5, p6, "Canh rau cải thịt nạc",    "Pork vegetable soup",                "canh-rau-thit-nac-hem",40000, 180, 16, 12,  6, [],                                   SpiceLevel.None,   ImgMealPrep2),
            MI(6, 6, p6, "Nước ép rau củ tươi",      "Fresh vegetable juice",              "nuoc-ep-rau-cu-hem",  35000,  80,  2, 18,  0, [DietaryTag.Vegan],                   SpiceLevel.None,   ImgSalad1),
            MI(6, 7, p6, "Trứng chiên rau sạch",     "Egg stir-fry with clean veggies",   "trung-chien-rau-hem", 45000, 240, 16,  8, 16, [DietaryTag.Vegetarian],               SpiceLevel.None,   ImgChicken),
        ]);

        return items;
    }

    private static FoodMenuItem MI(int pp, int item, Guid partnerId, string nameVi, string nameEn, string slug,
        decimal price, int cal, int p, int c, int f, DietaryTag[] tags, SpiceLevel spice, string imgUrl) =>
        new()
        {
            Id = MenuItemId(pp, item),
            PartnerId = partnerId,
            NameVi = nameVi,
            NameEn = nameEn,
            Slug = slug,
            Description = nameVi,
            ImageUrls = [imgUrl],
            Category = FoodCategory.PreparedMeal,
            Price = price,
            Currency = "VND",
            PrepTimeMinutes = 15 + (item % 3) * 5,
            Nutrition = new NutritionSnapshot
            {
                Calories = cal,
                ProteinGram = p,
                CarbGram = c,
                FatGram = f,
                ServingDescription = "1 phần",
            },
            DietaryTags = [.. tags],
            SpiceLevel = spice,
            Availability = item == 3 && pp % 3 == 0 ? AvailabilityStatus.SoldOut : AvailabilityStatus.Available,
            IsAiRecommended = tags.Contains(DietaryTag.HighProtein),
            RatingAverage = 0,
            RatingCount = 0,
        };

    // ─── Reviews ──────────────────────────────────────────────────────────────
    private static List<Review> BuildReviews(List<Partner> partnerList, List<FoodMenuItem> menuItems)
    {
        var reviews = new List<Review>();

        // Reviews per partner: 8-12 Partner-level reviews + a few MenuItem reviews
        // Ratings designed to produce realistic averages (not too round)
        var partnerReviewData = new (int[] Raters, int[] Ratings, string[] Comments, bool[] HasReply)[]
        {
            // Partner 1 – KNMEAL (avg ~4.4)
            ([2,4,6,7,8,9,10,12,15,17], [5,4,5,5,4,3,5,4,5,4],
             ["Gà mềm, khoai ngọt, đóng hộp chắc chắn. Sẽ đặt lại!", "Cá hồi tươi ngon, cơm gạo lứt chín dẻo.", "Phần ăn to, macro chuẩn như quảng cáo.", "Salad tươi ngon, giao nhanh.", "Đồ ăn tươi, calo khớp app.", "Hơi nhạt nhưng healthy thật sự.", "Ức gà không bị khô, sốt vừa miệng.", "Giao nhanh, đóng gói sạch sẽ.", "Meal prep tốt nhất tôi từng dùng!", "Macro chính xác, rất tiện log vào app."],
             [true, false, true, false, false, true, false, true, false, false]),

            // Partner 2 – Eat More Salad (avg ~4.0)
            ([3,5,7,10,14,17,19,20], [5,4,4,3,5,4,2,5],
             ["Poke bowl cá hồi tươi thật, cuốn lắm!", "Vegan salad nhiều rau xanh tươi.", "Bowl ức gà ngon, không bị ngán.", "Giao hơi trễ nhưng đồ ăn tươi.", "Wrap gà thơm, ăn no lâu.", "Quinoa salad ổn, nhạt một chút.", "Phần nhỏ so với giá, hơi thất vọng.", "Đồ ăn sạch, healthy rõ rệt."],
             [true, false, false, true, false, false, true, false]),

            // Partner 3 – Fitfood (avg ~4.5)
            ([2,4,8,12,15,17,19,21], [5,5,4,5,4,5,4,4],
             ["Combo tăng cơ đủ macro, giá hợp lý.", "Meal-prep 5 ngày tiện lợi, không lo ăn gì mỗi sáng.", "Đồ ăn ngon hơn mình nghĩ.", "Phần ăn to, cân bằng dinh dưỡng tốt.", "Gà không bị khô dù để 2 ngày.", "Cháo gà thơm, ăn sáng nhẹ nhàng.", "Giá cao hơn chút nhưng chất lượng xứng đáng.", "Combo giảm mỡ phù hợp mình đang cut."],
             [false, true, false, true, false, false, true, false]),

            // Partner 4 – Insalata (avg ~4.2)
            ([4,6,9,10,14,17,20,21], [5,4,4,3,5,4,5,4],
             ["Salad Ý tươi, dress light rất vừa ý.", "Pasta nguyên cám ăn no lâu, không ngán.", "Caprese đơn giản mà ngon.", "Phần hơi nhỏ, nhưng thành phần sạch.", "Pollo grilled rất mềm và thơm.", "Minestrone ấm lòng, ít calo.", "Nhà hàng đẹp, staff thân thiện.", "Insalata Tonno tươi, không bị tanh."],
             [true, false, true, false, true, false, false, true]),

            // Partner 5 – Healthy Eating (avg ~4.3)
            ([3,6,7,9,11,13,16,18,19], [5,4,5,4,4,3,5,4,4],
             ["Giá bình dân, đồ ăn healthy thật sự.", "Cơm ức gà đủ chất, giao nhanh khu Q8.", "Salad gà trứng giòn tươi.", "Cháo cá hồi nấu vừa mặn, thơm.", "Cơm gạo lứt bò ngon, no lâu.", "Soup rau củ hơi ít, nhưng tươi.", "Giá tốt nhất khu vực!", "Trứng hấp đậu phụ thanh mát.", "Đồ ăn sạch, phù hợp cả nhà."],
             [false, true, false, false, true, true, false, false, false]),

            // Partner 6 – Hẻm Healthy Food (avg ~4.1)
            ([2,5,8,9,12,14,16,17,20,21], [5,3,5,4,4,4,3,5,4,5],
             ["Gà nướng sả ớt thơm, healthy đúng nghĩa!", "Phần cơm tấm healthy hơi nhỏ.", "Bún gà lá chanh mát lành, ăn sáng tốt.", "Salad kiểu Việt lạ miệng, ngon.", "Canh rau thịt nạc thanh đạm.", "Trứng chiên rau sạch đơn giản mà ổn.", "Nước ép rau củ ổn, không quá ngọt.", "Quán nhỏ xinh, thức ăn tươi mỗi ngày.", "Giá dễ chịu, chủ quán nhiệt tình.", "Menu đa dạng, healthy từng món."],
             [true, false, false, true, false, false, true, false, true, false]),
        };

        for (var pp = 0; pp < partnerList.Count; pp++)
        {
            var partner = partnerList[pp];
            var (raters, ratings, comments, hasReply) = partnerReviewData[pp];

            for (var i = 0; i < raters.Length; i++)
            {
                var user = SyncSeedUsers.All.First(u => u.Nn == raters[i]);
                reviews.Add(new Review
                {
                    Id = ReviewId(pp + 1, i + 1),
                    UserId = user.Id,
                    AuthorSnapshot = new AuthorSnapshot
                    {
                        FullName = user.FullName,
                        AvatarUrl = SyncSeedUsers.AvatarUrl(user.Email),
                    },
                    TargetType = ReviewTargetType.Partner,
                    TargetId = partner.Id,
                    Rating = ratings[i],
                    Comment = comments[i],
                    IsVerifiedPurchase = i % 3 != 2,
                    PartnerReply = hasReply[i]
                        ? $"Cảm ơn bạn {user.FullName.Split(' ').Last()} đã ủng hộ! Hẹn gặp lại 🌿"
                        : null,
                    ImageUrls = i % 4 == 0 ? [ImgMealPrep1] : null,
                });
            }

            // MenuItem-level reviews for the first menu item of each partner
            var menuItem = menuItems.First(m => m.PartnerId == partner.Id);
            var menuReviewUser = SyncSeedUsers.All.First(u => u.Nn == raters[0]);
            reviews.Add(new Review
            {
                Id = ReviewId(pp + 1, 90 + pp),
                UserId = menuReviewUser.Id,
                AuthorSnapshot = new AuthorSnapshot
                {
                    FullName = menuReviewUser.FullName,
                    AvatarUrl = SyncSeedUsers.AvatarUrl(menuReviewUser.Email),
                },
                TargetType = ReviewTargetType.FoodMenuItem,
                TargetId = menuItem.Id,
                Rating = ratings[0],
                Comment = $"Món {menuItem.NameVi} rất ngon, sẽ đặt lại!",
                IsVerifiedPurchase = true,
            });
        }

        return reviews;
    }

    // ─── Rating recomputation ─────────────────────────────────────────────────
    private static async Task RecomputeRatingsAsync(
        IMongoCollection<Partner> partnerColl,
        IMongoCollection<FoodMenuItem> menuColl,
        List<Review> reviews,
        CancellationToken ct)
    {
        var partnerGroups = reviews
            .Where(r => r.TargetType == ReviewTargetType.Partner)
            .GroupBy(r => r.TargetId);

        foreach (var group in partnerGroups)
        {
            var avg = (decimal)Math.Round(group.Average(r => r.Rating), 1);
            var count = group.Count();
            await partnerColl.UpdateOneAsync(
                Builders<Partner>.Filter.Eq(x => x.Id, group.Key),
                Builders<Partner>.Update
                    .Set(x => x.RatingAverage, avg)
                    .Set(x => x.RatingCount, count),
                cancellationToken: ct);
        }

        var menuGroups = reviews
            .Where(r => r.TargetType == ReviewTargetType.FoodMenuItem)
            .GroupBy(r => r.TargetId);

        foreach (var group in menuGroups)
        {
            var avg = (decimal)Math.Round(group.Average(r => r.Rating), 1);
            var count = group.Count();
            await menuColl.UpdateOneAsync(
                Builders<FoodMenuItem>.Filter.Eq(x => x.Id, group.Key),
                Builders<FoodMenuItem>.Update
                    .Set(x => x.RatingAverage, avg)
                    .Set(x => x.RatingCount, count),
                cancellationToken: ct);
        }
    }

    // ─── Geo helper ───────────────────────────────────────────────────────────
    private static GeoJsonPoint<GeoJson2DGeographicCoordinates> GeoPoint(double lng, double lat) =>
        new(new GeoJson2DGeographicCoordinates(lng, lat));
}
