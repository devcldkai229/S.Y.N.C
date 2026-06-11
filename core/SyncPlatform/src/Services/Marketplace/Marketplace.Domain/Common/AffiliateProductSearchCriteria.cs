using Libs.Shared.Enums;
using Marketplace.Domain.Enums;

namespace Marketplace.Domain.Common;

public class AffiliateProductSearchCriteria
{
    public AffiliateCategory? Category { get; set; }

    public List<DietaryTag>? DietaryTags { get; set; }

    public AvailabilityStatus? Availability { get; set; } = AvailabilityStatus.Available;

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}
