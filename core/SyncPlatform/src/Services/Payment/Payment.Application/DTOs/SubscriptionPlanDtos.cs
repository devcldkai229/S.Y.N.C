using System.ComponentModel.DataAnnotations;

namespace Payment.Application.DTOs;

public class SubscriptionPlanDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal MonthlyPrice { get; set; }
    public decimal YearlyPrice { get; set; }
    public string Currency { get; set; } = "VND";
    public List<string>? Features { get; set; }
    public int AiUsageLimitPerMonth { get; set; }
    public bool PremiumWorkoutAccess { get; set; }
    public bool PremiumMarketplaceAccess { get; set; }
    public bool PriorityAiResponses { get; set; }
    public int MaxAiAutoOrdersPerMonth { get; set; }
    public bool IsActive { get; set; }
    public string? GooglePlayProductId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
}

public class CreateSubscriptionPlanDto
{
    [Required]
    [MaxLength(128)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(512)]
    public string? Description { get; set; }

    [Range(0, double.MaxValue)]
    public decimal MonthlyPrice { get; set; }

    [Range(0, double.MaxValue)]
    public decimal YearlyPrice { get; set; }

    [Required]
    [MaxLength(8)]
    public string Currency { get; set; } = "VND";

    public List<string>? Features { get; set; }

    [Range(0, int.MaxValue)]
    public int AiUsageLimitPerMonth { get; set; }

    public bool PremiumWorkoutAccess { get; set; }
    public bool PremiumMarketplaceAccess { get; set; }
    public bool PriorityAiResponses { get; set; }

    [Range(0, int.MaxValue)]
    public int MaxAiAutoOrdersPerMonth { get; set; }

    public bool IsActive { get; set; } = true;

    [MaxLength(128)]
    public string? GooglePlayProductId { get; set; }
}

public class UpdateSubscriptionPlanDto
{
    [Required]
    [MaxLength(128)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(512)]
    public string? Description { get; set; }

    [Range(0, double.MaxValue)]
    public decimal MonthlyPrice { get; set; }

    [Range(0, double.MaxValue)]
    public decimal YearlyPrice { get; set; }

    [Required]
    [MaxLength(8)]
    public string Currency { get; set; } = "VND";

    public List<string>? Features { get; set; }

    [Range(0, int.MaxValue)]
    public int AiUsageLimitPerMonth { get; set; }

    public bool PremiumWorkoutAccess { get; set; }
    public bool PremiumMarketplaceAccess { get; set; }
    public bool PriorityAiResponses { get; set; }

    [Range(0, int.MaxValue)]
    public int MaxAiAutoOrdersPerMonth { get; set; }

    public bool IsActive { get; set; }

    [MaxLength(128)]
    public string? GooglePlayProductId { get; set; }
}
