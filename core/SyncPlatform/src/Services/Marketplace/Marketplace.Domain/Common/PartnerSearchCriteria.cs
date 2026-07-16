using Marketplace.Domain.Enums;

namespace Marketplace.Domain.Common;

public class PartnerSearchCriteria
{
    public string? Query { get; set; }

    public PartnerType? Type { get; set; }

    public PartnerStatus Status { get; set; } = PartnerStatus.Active;

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    public double? RadiusKm { get; set; }

    /// <summary>Minimum partner RatingAverage (inclusive).</summary>
    public decimal? MinRating { get; set; }

    /// <summary>When set, only partners in this set (e.g. dish name join).</summary>
    public IReadOnlyList<Guid>? PartnerIds { get; set; }

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}
