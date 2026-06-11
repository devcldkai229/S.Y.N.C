using Marketplace.Domain.Enums;

namespace Marketplace.Domain.Common;

public class PartnerSearchCriteria
{
    public PartnerType? Type { get; set; }

    public PartnerStatus Status { get; set; } = PartnerStatus.Active;

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    public double? RadiusKm { get; set; }

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}
