namespace Iam.Application.DTOs;

public sealed record GamificationSummaryDto(
    int CurrentLevel,
    long CurrentXP,
    int CurrentStreak,
    int LongestStreak,
    decimal SyncCoins,
    long AchievementPoints,
    int ConsecutivePerfectDays);

public sealed record VoucherInventoryItemDto(
    Guid Id,
    string VoucherCode,
    string Name,
    string PromotionType,
    decimal Value,
    string Status,
    DateTimeOffset AcquiredAt,
    DateTimeOffset? UsedAt,
    DateTimeOffset? ValidUntil,
    bool IsExpired);

public sealed record AchievementInventoryItemDto(
    Guid Id,
    string Code,
    string Name,
    string Description,
    int XPReward,
    int CoinReward,
    string IconUrl,
    DateTimeOffset UnlockedAt);

/// <summary>An achievement not yet unlocked, with measurable progress toward it.</summary>
public sealed record AchievementProgressDto(
    Guid Id,
    string Code,
    string Name,
    string Description,
    int XPReward,
    int CoinReward,
    string IconUrl,
    int CurrentValue,
    int RequiredValue);

public sealed record InventoryResponse(
    GamificationSummaryDto? Gamification,
    IReadOnlyList<VoucherInventoryItemDto> Vouchers,
    IReadOnlyList<AchievementInventoryItemDto> Achievements,
    IReadOnlyList<AchievementProgressDto> InProgressAchievements,
    int TotalVouchers,
    int TotalAchievementsUnlocked);
