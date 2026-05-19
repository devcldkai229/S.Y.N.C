using Libs.Shared.Common;

namespace Payment.Domain.Models;

public class SubscriptionPlan : BaseAuditableEntity
{
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public decimal MonthlyPrice { get; set; }

    public decimal YearlyPrice { get; set; }

    public string Currency { get; set; } = "VND";

    public string? FeaturesJson { get; set; }

    public int AiUsageLimitPerMonth { get; set; }

    public bool PremiumWorkoutAccess { get; set; }

    public bool PremiumMarketplaceAccess { get; set; }

    public bool PriorityAiResponses { get; set; }

    public int MaxAiAutoOrdersPerMonth { get; set; }

    public bool IsActive { get; set; }
}
