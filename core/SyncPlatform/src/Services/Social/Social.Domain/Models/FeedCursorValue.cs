namespace Social.Domain.Models;

/// <summary>Compound keyset cursor payload (CreatedAt + Id).</summary>
public readonly record struct FeedCursorValue(DateTimeOffset CreatedAt, Guid Id);
