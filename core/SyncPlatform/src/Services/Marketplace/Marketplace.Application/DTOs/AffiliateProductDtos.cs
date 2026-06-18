using Libs.Shared.Enums;
using Marketplace.Domain.Enums;

namespace Marketplace.Application.DTOs;

public class AffiliateProductDto
{
    public Guid Id { get; set; }

    public Guid? PartnerId { get; set; }

    public string BrandName { get; set; } = string.Empty;

    public string NameVi { get; set; } = string.Empty;

    public string NameEn { get; set; } = string.Empty;

    public string Slug { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public IReadOnlyList<string> ImageUrls { get; set; } = [];

    public AffiliateCategory Category { get; set; }

    public decimal Price { get; set; }

    public string Currency { get; set; } = string.Empty;

    public string AffiliateUrl { get; set; } = string.Empty;

    public string? ExternalProductId { get; set; }

    public decimal CommissionRate { get; set; }

    public NutritionSnapshotDto? Nutrition { get; set; }

    public IReadOnlyList<DietaryTag>? DietaryTags { get; set; }

    public AvailabilityStatus Availability { get; set; }

    public decimal RatingAverage { get; set; }

    public int RatingCount { get; set; }
}

public class AffiliateProductSearchRequest
{
    public string? Category { get; set; }

    public List<string>? DietaryTags { get; set; }

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}

public class CreateAffiliateProductDto
{
    public string BrandName { get; set; } = string.Empty;

    public string NameVi { get; set; } = string.Empty;

    public string NameEn { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public List<string>? ImageUrls { get; set; }

    public AffiliateCategory Category { get; set; }

    public decimal Price { get; set; }

    public string Currency { get; set; } = "VND";

    public string AffiliateUrl { get; set; } = string.Empty;

    public string? ExternalProductId { get; set; }

    public decimal CommissionRate { get; set; }

    public NutritionSnapshotDto? Nutrition { get; set; }

    public List<DietaryTag>? DietaryTags { get; set; }

    public AvailabilityStatus Availability { get; set; } = AvailabilityStatus.Available;
}

public class UpdateAffiliateProductDto
{
    public string? BrandName { get; set; }

    public string? NameVi { get; set; }

    public string? NameEn { get; set; }

    public string? Description { get; set; }

    public List<string>? ImageUrls { get; set; }

    public AffiliateCategory? Category { get; set; }

    public decimal? Price { get; set; }

    public string? Currency { get; set; }

    public string? AffiliateUrl { get; set; }

    public string? ExternalProductId { get; set; }

    public decimal? CommissionRate { get; set; }

    public NutritionSnapshotDto? Nutrition { get; set; }

    public List<DietaryTag>? DietaryTags { get; set; }

    public AvailabilityStatus? Availability { get; set; }
}

public class AffiliateClickRequest
{
    public string? Source { get; set; }
}

public class AffiliateClickResponseDto
{
    public string RedirectUrl { get; set; } = string.Empty;

    public string ClickToken { get; set; } = string.Empty;
}
