using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Payment.Domain.Models;

namespace Payment.Infrastructure.Persistence.Seed;

/// <summary>Stable subscription plan IDs and dev seed data for Payment service.</summary>
public static class PaymentSeedData
{
    public static readonly Guid FreePlanId = Guid.Parse("f1000001-0000-0000-0000-000000000001");
    public static readonly Guid PremiumPlanId = Guid.Parse("f1000002-0000-0000-0000-000000000002");

    private const int FreeAiLimitPerMonth = 30;
    private const int PremiumAiLimitPerMonth = 0; // 0 = unlimited; described in Features for UI
    private const int FreeMaxAiAutoOrders = 0;
    private const int PremiumMaxAiAutoOrders = 10;

    private const decimal PremiumMonthlyPrice = 199_000m;
    private const decimal PremiumYearlyPrice = 1_910_400m; // 199K × 12 tháng, giảm 20%

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = false,
    };

    public static IReadOnlyList<SubscriptionPlan> GetSubscriptionPlans() =>
    [
        new SubscriptionPlan
        {
            Id = FreePlanId,
            Name = "Free",
            Description = "Bắt đầu hành trình fitness với các tính năng cốt lõi của SYNC — hoàn toàn miễn phí.",
            MonthlyPrice = 0,
            YearlyPrice = 0,
            Currency = "VND",
            FeaturesJson = SerializeFeatures(
            [
                "Truy cập bài tập cơ bản & lộ trình Foundation",
                "30 lượt hỏi SYNC AI mỗi tháng",
                "Theo dõi streak, thành tích & cộng đồng SYNC",
                "Chưa mở khóa giáo án Premium & video HD",
                "Chưa truy cập Marketplace ưu đãi độc quyền",
            ]),
            AiUsageLimitPerMonth = FreeAiLimitPerMonth,
            PremiumWorkoutAccess = false,
            PremiumMarketplaceAccess = false,
            PriorityAiResponses = false,
            MaxAiAutoOrdersPerMonth = FreeMaxAiAutoOrders,
            IsActive = true,
            GooglePlayProductId = null,
        },
        new SubscriptionPlan
        {
            Id = PremiumPlanId,
            Name = "Premium",
            Description = "Nâng cấp trải nghiệm SYNC với AI không giới hạn, giáo án cao cấp và ưu đãi Marketplace — 199.000đ/tháng.",
            MonthlyPrice = PremiumMonthlyPrice,
            YearlyPrice = PremiumYearlyPrice,
            Currency = "VND",
            FeaturesJson = SerializeFeatures(
            [
                "Tất cả tính năng gói Free",
                "AI SYNC không giới hạn — sử dụng 100% giới hạn mỗi tháng",
                "Mở khóa toàn bộ giáo án & video HD Premium",
                "Truy cập Marketplace ưu đãi độc quyền",
                "SYNC AI phản hồi ưu tiên, nhanh hơn",
                "Tự động đặt đơn AI lên đến 10 lần/tháng",
            ]),
            AiUsageLimitPerMonth = PremiumAiLimitPerMonth,
            PremiumWorkoutAccess = true,
            PremiumMarketplaceAccess = true,
            PriorityAiResponses = true,
            MaxAiAutoOrdersPerMonth = PremiumMaxAiAutoOrders,
            IsActive = true,
            GooglePlayProductId = "sync_premium_monthly",
        },
    ];

    private static string SerializeFeatures(IReadOnlyList<string> features) =>
        JsonSerializer.Serialize(features, JsonOptions);

    /// <summary>Applies EF migrations and idempotent subscription plan seed (run once at Payment.API startup).</summary>
    public static class PaymentDbSeeder
    {
        public static async Task SeedAsync(
            PaymentDbContext db,
            CancellationToken cancellationToken = default)
        {
            await db.Database.MigrateAsync(cancellationToken);
            await SeedSubscriptionPlansAsync(db, cancellationToken);
        }

        private static async Task SeedSubscriptionPlansAsync(
            PaymentDbContext db,
            CancellationToken cancellationToken)
        {
            var seeds = GetSubscriptionPlans();
            var ids = seeds.Select(p => p.Id).ToList();

            var existing = await db.SubscriptionPlans
                .IgnoreQueryFilters()
                .Where(p => ids.Contains(p.Id))
                .ToListAsync(cancellationToken);

            var existingById = existing.ToDictionary(p => p.Id);
            var now = DateTimeOffset.UtcNow;
            var toAdd = new List<SubscriptionPlan>();

            foreach (var seed in seeds)
            {
                if (existingById.TryGetValue(seed.Id, out var plan))
                {
                    ApplySeedValues(seed, plan);
                    plan.UpdatedAt = now;
                    if (plan.DeletedAt is not null)
                    {
                        plan.DeletedAt = null;
                        plan.IsActive = true;
                    }
                    continue;
                }

                seed.CreatedAt = now;
                seed.UpdatedAt = now;
                toAdd.Add(seed);
            }

            if (toAdd.Count > 0)
                await db.SubscriptionPlans.AddRangeAsync(toAdd, cancellationToken);

            if (toAdd.Count > 0 || existing.Count > 0)
                await db.SaveChangesAsync(cancellationToken);
        }

        private static void ApplySeedValues(SubscriptionPlan seed, SubscriptionPlan target)
        {
            target.Name = seed.Name;
            target.Description = seed.Description;
            target.MonthlyPrice = seed.MonthlyPrice;
            target.YearlyPrice = seed.YearlyPrice;
            target.Currency = seed.Currency;
            target.FeaturesJson = seed.FeaturesJson;
            target.AiUsageLimitPerMonth = seed.AiUsageLimitPerMonth;
            target.PremiumWorkoutAccess = seed.PremiumWorkoutAccess;
            target.PremiumMarketplaceAccess = seed.PremiumMarketplaceAccess;
            target.PriorityAiResponses = seed.PriorityAiResponses;
            target.MaxAiAutoOrdersPerMonth = seed.MaxAiAutoOrdersPerMonth;
            target.IsActive = seed.IsActive;
            target.GooglePlayProductId = seed.GooglePlayProductId;
        }
    }
}
