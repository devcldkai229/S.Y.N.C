using System.Text.Json;
using Libs.Shared.Seed;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Payment.Domain.Enums;
using Payment.Domain.Models;

namespace Payment.Infrastructure.Persistence.Seed;

/// <summary>Stable subscription plan IDs and dev seed data for Payment service.</summary>
public static class PaymentSeedData
{
    /// <summary>Primary demo wallet owner — SyncSeedUsers.User02 (Trần Quốc Bảo).</summary>
    public static readonly Guid DemoUserId = SyncSeedUsers.User02;

    public static readonly Guid FreePlanId = Guid.Parse("f1000001-0000-0000-0000-000000000001");
    public static readonly Guid PremiumPlanId = Guid.Parse("f1000002-0000-0000-0000-000000000002");

    public static readonly Guid DemoWalletId = Guid.Parse("b2000001-0000-4000-8000-000000000001");
    public static readonly Guid DemoCampaign10kId = Guid.Parse("b2000002-0000-4000-8000-000000000002");
    public static readonly Guid DemoCampaign15PctId = Guid.Parse("b2000003-0000-4000-8000-000000000003");
    public static readonly Guid DemoVoucher10kId = Guid.Parse("b2000004-0000-4000-8000-000000000004");
    public static readonly Guid DemoVoucher15PctId = Guid.Parse("b2000005-0000-4000-8000-000000000005");

    private const int FreeAiLimitPerMonth = 30;
    private const int PremiumAiLimitPerMonth = 0; // 0 = unlimited; described in Features for UI
    private const int FreeMaxAiAutoOrders = 0;
    private const int PremiumMaxAiAutoOrders = 10;

    private const decimal PremiumMonthlyPrice = 99_000m;

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
            Description = "Khởi đầu với SYNC — lộ trình, nhật ký tập/ăn và CYN AI đủ để tạo thói quen. Nâng Premium khi cần coach sâu hơn.",
            MonthlyPrice = 0,
            YearlyPrice = 0,
            Currency = "VND",
            FeaturesJson = SerializeFeatures(
            [
                "Lộ trình Foundation & thư viện bài tập cơ bản",
                "CYN AI — 30 lượt hỏi mỗi tháng (coach / dinh dưỡng / lộ trình)",
                "Nhật ký tập luyện, dinh dưỡng & theo dõi cân nặng",
                "Streak, thành tích và cộng đồng SYNC",
                "Thông báo nhắc tập theo mẫu chuẩn",
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
            Description =
                "CYN không giới hạn, Adaptive Coaching theo cân thật, insight nâng cao và SmartPush cá nhân hóa — 99.000đ/tháng, hủy giữ quyền tới hết hạn.",
            MonthlyPrice = PremiumMonthlyPrice,
            YearlyPrice = 0,
            Currency = "VND",
            FeaturesJson = SerializeFeatures(
            [
                "Tất cả tính năng gói Free",
                "CYN AI không giới hạn — coach, dinh dưỡng, lộ trình & đặt lịch tập",
                "Adaptive Coaching — tự điều chỉnh calo/macro theo cân nặng thực tế",
                "Insight Premium — thống kê đa kỳ, biểu đồ & dự đoán tiến độ",
                "SmartPush cá nhân hóa bằng AI (nhắc tập / cân / phục hồi đúng lúc)",
                "Giáo án & video HD Premium + phản hồi AI ưu tiên",
                "Marketplace ưu đãi độc quyền · đặt đơn hỗ trợ AI tối đa 10 lần/tháng",
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

    /// <summary>Idempotent subscription plan seed (called from Payment.API startup).</summary>
    public static async Task SeedAsync(
        PaymentDbContext db,
        ILogger logger,
        CancellationToken cancellationToken = default)
    {
        logger.LogInformation("Seeding Payment subscription plans...");
        await PaymentDbSeeder.SeedAsync(db, cancellationToken);
        logger.LogInformation("Payment subscription plan seed completed.");
    }

    /// <summary>Applies EF migrations and idempotent subscription plan seed.</summary>
    public static class PaymentDbSeeder
    {
        public static async Task SeedAsync(
            PaymentDbContext db,
            CancellationToken cancellationToken = default)
        {
            await db.Database.MigrateAsync(cancellationToken);
            await SeedSubscriptionPlansAsync(db, cancellationToken);
            await SeedDemoWalletAndVouchersAsync(db, cancellationToken);
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

        private static async Task SeedDemoWalletAndVouchersAsync(
            PaymentDbContext db,
            CancellationToken cancellationToken)
        {
            var now = DateTimeOffset.UtcNow;
            var campaigns = GetDemoPromotionCampaigns(now);
            foreach (var seed in campaigns)
            {
                var existing = await db.PromotionCampaigns
                    .IgnoreQueryFilters()
                    .FirstOrDefaultAsync(c => c.Id == seed.Id, cancellationToken);
                if (existing is null)
                {
                    seed.CreatedAt = now;
                    seed.UpdatedAt = now;
                    await db.PromotionCampaigns.AddAsync(seed, cancellationToken);
                }
                else
                {
                    existing.Name = seed.Name;
                    existing.Description = seed.Description;
                    existing.PromotionType = seed.PromotionType;
                    existing.Value = seed.Value;
                    existing.MaxDiscountAmount = seed.MaxDiscountAmount;
                    existing.CouponCode = seed.CouponCode;
                    existing.MinimumSpend = seed.MinimumSpend;
                    existing.StartsAt = seed.StartsAt;
                    existing.EndsAt = seed.EndsAt;
                    existing.IsActive = true;
                    existing.UpdatedAt = now;
                }
            }

            var walletSeed = GetDemoWallet(now);
            var wallet = await db.Wallets
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(w => w.UserId == DemoUserId, cancellationToken);
            if (wallet is null)
            {
                await db.Wallets.AddAsync(walletSeed, cancellationToken);
            }
            else
            {
                wallet.AvailableBalance = walletSeed.AvailableBalance;
                wallet.RewardCoinBalance = walletSeed.RewardCoinBalance;
                wallet.AutoPaymentEnabled = walletSeed.AutoPaymentEnabled;
                wallet.DailyAutoSpendingLimit = walletSeed.DailyAutoSpendingLimit;
                wallet.MonthlyAutoSpendingLimit = walletSeed.MonthlyAutoSpendingLimit;
                wallet.RemainingDailyAutoLimit = walletSeed.RemainingDailyAutoLimit;
                wallet.RemainingMonthlyAutoLimit = walletSeed.RemainingMonthlyAutoLimit;
                wallet.UpdatedAt = now;
            }

            foreach (var voucherSeed in GetDemoUserVouchers())
            {
                var exists = await db.UserVouchers
                    .IgnoreQueryFilters()
                    .AnyAsync(v => v.Id == voucherSeed.Id, cancellationToken);
                if (!exists)
                {
                    voucherSeed.CreatedAt = now;
                    voucherSeed.UpdatedAt = now;
                    await db.UserVouchers.AddAsync(voucherSeed, cancellationToken);
                }
            }

            await db.SaveChangesAsync(cancellationToken);
        }
    }

    public static IReadOnlyList<PromotionCampaign> GetDemoPromotionCampaigns(DateTimeOffset now) =>
    [
        new PromotionCampaign
        {
            Id = DemoCampaign10kId,
            Name = "DEMO Giảm 10K",
            Description = "Giảm 10.000đ cho đơn từ 80.000đ (dev seed)",
            PromotionType = PromotionType.FixedDiscount,
            Value = 10_000,
            CouponCode = "DEMO10K",
            MinimumSpend = 80_000,
            UsageLimit = 10_000,
            UsageCount = 0,
            PerUserUsageLimit = 3,
            StartsAt = now.AddDays(-30),
            EndsAt = now.AddYears(1),
            IsActive = true,
        },
        new PromotionCampaign
        {
            Id = DemoCampaign15PctId,
            Name = "DEMO Giảm 15%",
            Description = "Giảm 15% tối đa 50.000đ (dev seed)",
            PromotionType = PromotionType.PercentageDiscount,
            Value = 15,
            MaxDiscountAmount = 50_000,
            CouponCode = "DEMO15PCT",
            MinimumSpend = 100_000,
            UsageLimit = 10_000,
            UsageCount = 0,
            PerUserUsageLimit = 2,
            StartsAt = now.AddDays(-30),
            EndsAt = now.AddYears(1),
            IsActive = true,
        },
    ];

    public static Wallet GetDemoWallet(DateTimeOffset now) => new()
    {
        Id = DemoWalletId,
        UserId = DemoUserId,
        AvailableBalance = 520_000,
        LockedBalance = 0,
        RewardCoinBalance = 340,
        Currency = "VND",
        AutoPaymentEnabled = true,
        DailyAutoSpendingLimit = 300_000,
        MonthlyAutoSpendingLimit = 3_000_000,
        RemainingDailyAutoLimit = 300_000,
        RemainingMonthlyAutoLimit = 3_000_000,
        LastResetDailyLimitAt = now,
        LastResetMonthlyLimitAt = now,
        RiskScore = 0.12m,
        CreatedAt = now,
        UpdatedAt = now,
    };

    public static IReadOnlyList<UserVoucher> GetDemoUserVouchers() =>
    [
        new UserVoucher
        {
            Id = DemoVoucher10kId,
            UserId = DemoUserId,
            PromotionCampaignId = DemoCampaign10kId,
            IsUsed = false,
        },
        new UserVoucher
        {
            Id = DemoVoucher15PctId,
            UserId = DemoUserId,
            PromotionCampaignId = DemoCampaign15PctId,
            IsUsed = false,
        },
    ];
}
