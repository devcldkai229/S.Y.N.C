using Social.Domain.Models;

namespace Social.Domain.Models;

/// <summary>Precomputed trending snapshot for discovery feed (time-decay score).</summary>
public class TrendingPost : BaseMongoEntity
{
    public Guid PostId { get; set; }
    public double Score { get; set; }
    public DateTimeOffset ComputedAt { get; set; } = DateTimeOffset.UtcNow;

    /// <summary>Denormalized snapshot so discovery GET avoids join.</summary>
    public Post Snapshot { get; set; } = new();
}
