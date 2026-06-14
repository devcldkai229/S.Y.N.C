namespace Iam.Application.DTOs;

public sealed record ShopItemDto(
    string Code,
    string Name,
    string Description,
    decimal CoinPrice,
    string RewardType,
    string RewardDetail,
    string IconEmoji);

public sealed record PurchaseRequest(string ItemCode);

public sealed record PurchaseResultDto(
    string ItemName,
    decimal CoinsSpent,
    decimal CoinsRemaining,
    string RewardType,
    string RewardDetail);
