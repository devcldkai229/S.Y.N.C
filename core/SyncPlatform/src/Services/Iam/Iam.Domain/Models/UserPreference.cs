using Libs.Shared.Common;
using Iam.Domain.Enums;

namespace Iam.Domain.Models;

public class UserPreference : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public virtual User User { get; set; } = null!;

    public List<AllergyItem>? Allergies { get; set; }

    public List<string>? FavoriteFoods { get; set; }

    public List<string>? DislikedFoods { get; set; }

    public AgentPersona AgentPersona { get; set; }

    public MotivationStyle MotivationStyle { get; set; }

    public bool AutoOrderEnabled { get; set; }

    public decimal? MaxAutoOrderLimitDaily { get; set; }

    public decimal? MaxAutoOrderLimitPerOrder { get; set; }

    public bool DataSharingConsent { get; set; }

    public bool MarketingConsent { get; set; }
}
