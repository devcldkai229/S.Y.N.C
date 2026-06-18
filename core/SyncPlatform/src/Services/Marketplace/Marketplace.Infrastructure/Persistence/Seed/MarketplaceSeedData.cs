using Libs.Shared.Common;
using Libs.Shared.Enums;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Models;
using MongoDB.Driver;
using MongoDB.Driver.GeoJsonObjectModel;

namespace Marketplace.Infrastructure.Persistence.Seed;

public static class MarketplaceSeedData
{
    public static readonly Guid PartnerUserId = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc");

    public static readonly Guid KitchenPartnerId = Guid.Parse("a1000001-0000-0000-0000-000000000001");

    public static readonly Guid BrandPartnerId = Guid.Parse("a1000002-0000-0000-0000-000000000002");

    public static readonly Guid BrandOwnerUserId = Guid.Parse("c55ef9c8-251c-4cf2-8cb2-e3e8f85cb159");

    public static async Task SeedAsync(IMongoDatabase database, CancellationToken cancellationToken = default)
    {
        var partners = database.GetCollection<Partner>("Partners");
        if (await partners.Find(_ => true).AnyAsync(cancellationToken))
            return;

        var kitchen = CreateKitchenPartner();
        var brand = CreateBrandPartner();
        await partners.InsertManyAsync([kitchen, brand], cancellationToken: cancellationToken);

        var menu = database.GetCollection<FoodMenuItem>("FoodMenuItems");
        await menu.InsertManyAsync(GetMenuItems(kitchen.Id), cancellationToken: cancellationToken);

        var affiliate = database.GetCollection<AffiliateProduct>("AffiliateProducts");
        await affiliate.InsertManyAsync(GetAffiliateProducts(brand.Id), cancellationToken: cancellationToken);
    }

    private static Partner CreateKitchenPartner() => new()
    {
        Id = KitchenPartnerId,
        OwnerUserId = PartnerUserId,
        Name = "SYNC Kitchen Quận 1",
        Slug = "sync-kitchen-q1",
        Type = PartnerType.CloudKitchen,
        Description = "Bếp cloud kitchen healthy meal tại Quận 1.",
        Email = "kitchen@sync.local",
        PhoneNumber = "0901000001",
        Address = "123 Nguyễn Huệ, Quận 1, TP.HCM",
        Location = new GeoJsonPoint<GeoJson2DGeographicCoordinates>(
            new GeoJson2DGeographicCoordinates(106.7009, 10.7769)),
        ServiceRadiusKm = 5,
        OperatingHours =
        [
            new Partner.OperatingHour { DayOfWeek = 1, OpenTime = "08:00", CloseTime = "21:00" },
            new Partner.OperatingHour { DayOfWeek = 2, OpenTime = "08:00", CloseTime = "21:00" },
        ],
        CommissionRate = 15,
        Status = PartnerStatus.Active,
        RatingAverage = 4.6m,
        RatingCount = 12,
        IsAiRecommendable = true,
    };

    private static Partner CreateBrandPartner() => new()
    {
        Id = BrandPartnerId,
        OwnerUserId = BrandOwnerUserId,
        Name = "SYNC Fit Brand",
        Slug = "sync-fit-brand",
        Type = PartnerType.AffiliateBrand,
        Description = "Thương hiệu supplement & phụ kiện tập luyện.",
        Email = "brand@sync.local",
        CommissionRate = 10,
        Status = PartnerStatus.Active,
        RatingAverage = 4.3m,
        RatingCount = 8,
        IsAiRecommendable = true,
    };

    private static IEnumerable<FoodMenuItem> GetMenuItems(Guid partnerId) =>
    [
        new FoodMenuItem
        {
            Id = Guid.Parse("b1000001-0000-0000-0000-000000000001"),
            PartnerId = partnerId,
            NameVi = "Cơm gà ức",
            NameEn = "Chicken breast rice bowl",
            Slug = "com-ga-uc",
            Description = "Ức gà nướng + cơm gạo lứt + rau.",
            Category = FoodCategory.PreparedMeal,
            Price = 65000,
            Currency = "VND",
            PrepTimeMinutes = 20,
            Nutrition = new NutritionSnapshot
            {
                Calories = 520,
                ProteinGram = 42,
                CarbGram = 48,
                FatGram = 12,
                ServingDescription = "1 phần",
            },
            DietaryTags = [DietaryTag.HighProtein],
            SpiceLevel = SpiceLevel.Mild,
            Availability = AvailabilityStatus.Available,
            IsAiRecommended = true,
        },
        new FoodMenuItem
        {
            Id = Guid.Parse("b1000002-0000-0000-0000-000000000002"),
            PartnerId = partnerId,
            NameVi = "Salad bơ trứng",
            NameEn = "Avocado egg salad",
            Slug = "salad-bo-trung",
            Description = "Salad bơ, trứng luộc, rau xanh.",
            Category = FoodCategory.PreparedMeal,
            Price = 55000,
            Currency = "VND",
            PrepTimeMinutes = 15,
            Nutrition = new NutritionSnapshot
            {
                Calories = 380,
                ProteinGram = 18,
                CarbGram = 12,
                FatGram = 28,
                ServingDescription = "1 phần",
            },
            DietaryTags = [DietaryTag.LowCarb, DietaryTag.GlutenFree],
            SpiceLevel = SpiceLevel.None,
            Availability = AvailabilityStatus.Available,
        },
    ];

    private static IEnumerable<AffiliateProduct> GetAffiliateProducts(Guid partnerId) =>
    [
        new AffiliateProduct
        {
            Id = Guid.Parse("c1000001-0000-0000-0000-000000000001"),
            PartnerId = partnerId,
            BrandName = "SYNC Fit",
            NameVi = "Whey Protein 1kg",
            NameEn = "Whey Protein 1kg",
            Slug = "whey-protein-1kg",
            Description = "Whey isolate hương vani.",
            Category = AffiliateCategory.Supplement,
            Price = 890000,
            Currency = "VND",
            AffiliateUrl = "https://example.com/whey",
            CommissionRate = 12,
            Nutrition = new NutritionSnapshot { Calories = 120, ProteinGram = 24, CarbGram = 3, FatGram = 1 },
            DietaryTags = [DietaryTag.HighProtein],
            Availability = AvailabilityStatus.Available,
            RatingAverage = 4.5m,
            RatingCount = 5,
        },
    ];
}
