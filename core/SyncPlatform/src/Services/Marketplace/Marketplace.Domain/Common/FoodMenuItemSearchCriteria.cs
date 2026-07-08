using Libs.Shared.Enums;
using Marketplace.Domain.Enums;

namespace Marketplace.Domain.Common;

public class FoodMenuItemSearchCriteria
{
    public string? Query { get; set; }

    public FoodCategory? Category { get; set; }

    public List<DietaryTag>? DietaryTags { get; set; }

    public decimal? MinPrice { get; set; }

    public decimal? MaxPrice { get; set; }

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    public double? RadiusKm { get; set; }

    public IReadOnlyList<Guid>? PartnerIds { get; set; }

    public AvailabilityStatus? Availability { get; set; } = AvailabilityStatus.Available;

    /// <summary>When true, only items flagged for AI recommendations.</summary>
    public bool? IsAiRecommended { get; set; }

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}
