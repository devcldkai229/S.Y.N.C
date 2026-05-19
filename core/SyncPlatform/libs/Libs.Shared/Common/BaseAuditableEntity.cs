namespace Libs.Shared.Common;

/// <summary>
/// Base for all PostgreSQL/EF Core entities: primary key + soft-delete audit timestamps.
/// </summary>
public abstract class BaseAuditableEntity
{
    public Guid Id { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? UpdatedAt { get; set; }

    public DateTimeOffset? DeletedAt { get; set; }
}
