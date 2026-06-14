using Marketplace.Domain.Enums;

namespace Marketplace.Application.DTOs;

public class PartnerDto
{
    public Guid Id { get; set; }

    public Guid OwnerUserId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string Slug { get; set; } = string.Empty;

    public PartnerType Type { get; set; }

    public string? Description { get; set; }

    public string? LogoUrl { get; set; }

    public string? CoverImageUrl { get; set; }

    public string Email { get; set; } = string.Empty;

    public string? PhoneNumber { get; set; }

    public string? Address { get; set; }

    public LocationDto? Location { get; set; }

    public decimal? ServiceRadiusKm { get; set; }

    public IReadOnlyList<OperatingHourDto> OperatingHours { get; set; } = [];

    public decimal CommissionRate { get; set; }

    public PartnerStatus Status { get; set; }

    public decimal RatingAverage { get; set; }

    public int RatingCount { get; set; }

    public bool IsAiRecommendable { get; set; }

    public double? DistanceKm { get; set; }
}

public class PartnerDetailDto : PartnerDto
{
    public IReadOnlyList<FoodMenuItemDto> Menu { get; set; } = [];
}

public class PartnerSearchRequest
{
    public string? Query { get; set; }

    public string? Type { get; set; }

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    public double? RadiusKm { get; set; }

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}

public class RegisterPartnerDto
{
    public string Name { get; set; } = string.Empty;

    public PartnerType Type { get; set; }

    public string? Description { get; set; }

    public string Email { get; set; } = string.Empty;

    public string? PhoneNumber { get; set; }

    public string? Address { get; set; }

    public LocationDto? Location { get; set; }

    public decimal? ServiceRadiusKm { get; set; }

    public IReadOnlyList<OperatingHourDto>? OperatingHours { get; set; }

    public decimal CommissionRate { get; set; }
}

public class UpdatePartnerDto
{
    public string? Name { get; set; }

    public string? Description { get; set; }

    public string? LogoUrl { get; set; }

    public string? CoverImageUrl { get; set; }

    public string? PhoneNumber { get; set; }

    public string? Address { get; set; }

    public LocationDto? Location { get; set; }

    public decimal? ServiceRadiusKm { get; set; }

    public IReadOnlyList<OperatingHourDto>? OperatingHours { get; set; }

    public bool? IsAiRecommendable { get; set; }
}

public class UpdatePartnerStatusDto
{
    public PartnerStatus Status { get; set; }
}
