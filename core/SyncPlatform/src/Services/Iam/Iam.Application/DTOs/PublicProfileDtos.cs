namespace Iam.Application.DTOs;

/// <summary>
/// Safe public-facing profile — no health, preferences, or financial data.
/// </summary>
public sealed record PublicProfileResponse(
    Guid UserId,
    string FullName,
    string? AvatarUrl,
    int CurrentLevel,
    long CurrentXP,
    int CurrentStreak);
