namespace Marketplace.Domain.Models;

public class AffiliateClickEvent : BaseMongoEntity
{
    public Guid UserId { get; set; }

    public Guid AffiliateProductId { get; set; }

    public Guid? PartnerId { get; set; }

    public string ClickToken { get; set; } = string.Empty;

    public string Source { get; set; } = string.Empty;

    public DateTimeOffset ClickedAt { get; set; }
}
