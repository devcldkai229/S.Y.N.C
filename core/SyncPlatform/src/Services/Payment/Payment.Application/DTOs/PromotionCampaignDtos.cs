using System.ComponentModel.DataAnnotations;
using Payment.Domain.Enums;

namespace Payment.Application.DTOs;

public class PromotionCampaignDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public PromotionType PromotionType { get; set; }
    public decimal Value { get; set; }
    public string? CouponCode { get; set; }
    public List<string>? ApplicableProductTypes { get; set; }
    public decimal MinimumSpend { get; set; }
    public int UsageLimit { get; set; }
    public DateTimeOffset StartsAt { get; set; }
    public DateTimeOffset EndsAt { get; set; }
    public bool IsActive { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
}

public class CreatePromotionCampaignDto
{
    [Required]
    [MaxLength(256)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public PromotionType PromotionType { get; set; }

    [Range(0, double.MaxValue)]
    public decimal Value { get; set; }

    [MaxLength(64)]
    public string? CouponCode { get; set; }

    public List<string>? ApplicableProductTypes { get; set; }

    [Range(0, double.MaxValue)]
    public decimal MinimumSpend { get; set; }

    [Range(0, int.MaxValue)]
    public int UsageLimit { get; set; }

    [Required]
    public DateTimeOffset StartsAt { get; set; }

    [Required]
    public DateTimeOffset EndsAt { get; set; }

    public bool IsActive { get; set; } = true;
}

public class UpdatePromotionCampaignDto
{
    [Required]
    [MaxLength(256)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public PromotionType PromotionType { get; set; }

    [Range(0, double.MaxValue)]
    public decimal Value { get; set; }

    [MaxLength(64)]
    public string? CouponCode { get; set; }

    public List<string>? ApplicableProductTypes { get; set; }

    [Range(0, double.MaxValue)]
    public decimal MinimumSpend { get; set; }

    [Range(0, int.MaxValue)]
    public int UsageLimit { get; set; }

    [Required]
    public DateTimeOffset StartsAt { get; set; }

    [Required]
    public DateTimeOffset EndsAt { get; set; }

    public bool IsActive { get; set; }
}
