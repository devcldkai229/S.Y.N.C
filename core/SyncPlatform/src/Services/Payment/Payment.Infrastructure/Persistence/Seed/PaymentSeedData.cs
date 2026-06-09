using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Payment.Domain.Models;
using Payment.Infrastructure.Persistence;

namespace Payment.Infrastructure.Persistence.Seed;

public static class PaymentSeedData
{
    public static readonly Guid PremiumPlanId = Guid.Parse("eeeeeeee-0000-0000-0000-000000000001");

    public static async Task SeedAsync(PaymentDbContext db, ILogger logger)
    {
        var exists = await db.SubscriptionPlans.AnyAsync(p => p.Id == PremiumPlanId);
        if (exists) return;

        db.SubscriptionPlans.Add(new SubscriptionPlan
        {
            Id                       = PremiumPlanId,
            Name                     = "Premium",
            Description              = "Mở khóa toàn bộ tính năng cao cấp của SYNC.",
            MonthlyPrice             = 99_000,
            YearlyPrice              = 0,
            Currency                 = "VND",
            AiUsageLimitPerMonth     = 0,
            PremiumWorkoutAccess     = true,
            PremiumMarketplaceAccess = true,
            PriorityAiResponses      = true,
            MaxAiAutoOrdersPerMonth  = 0,
            IsActive                 = true,
            FeaturesJson             = """["Thông báo AI cá nhân hóa","Bài tập nâng cao","Ưu tiên AI phản hồi"]"""
        });

        await db.SaveChangesAsync();
        logger.LogInformation("Payment seed: Premium plan created (Id={PlanId}).", PremiumPlanId);
    }
}
