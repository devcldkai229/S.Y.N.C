using Libs.Shared.Common;

namespace Iam.Domain.Models;

public class UserAsset : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public virtual User User { get; set; } = null!;

    public string UnityAssetId { get; set; } = string.Empty;

    public string AssetCategory { get; set; } = string.Empty;

    public string Rarity { get; set; } = string.Empty;

    public string SourceType { get; set; } = string.Empty;

    public bool IsEquipped { get; set; }

    public DateTimeOffset? EquippedAt { get; set; }

    public DateTimeOffset UnlockedAt { get; set; }

    public DateTimeOffset? ExpiredAt { get; set; }

    public string? Metadata { get; set; }
}
