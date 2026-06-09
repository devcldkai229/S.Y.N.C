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

public sealed record InventoryResponse(
    GamificationSummaryDto? Gamification,
    IReadOnlyList<VoucherInventoryItemDto> Vouchers,
    IReadOnlyList<AchievementInventoryItemDto> Achievements,
    int TotalVouchers,
    int TotalAchievementsUnlocked);
