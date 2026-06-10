using Iam.Application.Abstractions;
using Iam.Application.DTOs;
using Iam.Application.Exceptions;
using Iam.Domain.Enums;
using Iam.Domain.Models;
using Libs.Auth.Context;

namespace Iam.Application.Services;

public sealed class ShopService : IShopService
{
    private readonly IUserMeRepository _repo;
    private readonly ICurrentUserContext _currentUser;
    private readonly IAchievementService _achievements;

    public ShopService(IUserMeRepository repo, ICurrentUserContext currentUser, IAchievementService achievements)
    {
        _repo = repo;
        _currentUser = currentUser;
        _achievements = achievements;
    }

    // ── Static catalog ────────────────────────────────────────────────────────

    private static readonly IReadOnlyList<ShopItemDto> Catalog =
    [
        new ShopItemDto(
            Code: "XP_BOOST_100",
            Name: "Nạp 100 XP",
            Description: "Nhận ngay 100 điểm kinh nghiệm, đẩy nhanh quá trình lên cấp.",
            CoinPrice: 100,
            RewardType: "xp",
            RewardDetail: "100 XP",
            IconEmoji: "⭐"),
        new ShopItemDto(
            Code: "XP_BOOST_500",
            Name: "Nạp 500 XP",
            Description: "Gói XP lớn — tăng tốc lên cấp đáng kể.",
            CoinPrice: 450,
            RewardType: "xp",
            RewardDetail: "500 XP",
            IconEmoji: "🌟"),
        new ShopItemDto(
            Code: "VOUCHER_10PCT",
            Name: "Thẻ Giảm Giá 10%",
            Description: "Voucher giảm 10% cho bất kỳ đơn hàng nào trên SYNC. Có hiệu lực 30 ngày.",
            CoinPrice: 300,
            RewardType: "voucher",
            RewardDetail: "10% off",
            IconEmoji: "🎟️"),
        new ShopItemDto(
            Code: "VOUCHER_20PCT",
            Name: "Thẻ Giảm Giá 20%",
            Description: "Voucher giảm 20% — tiết kiệm nhiều hơn cho đơn hàng lớn. Có hiệu lực 30 ngày.",
            CoinPrice: 500,
            RewardType: "voucher",
            RewardDetail: "20% off",
            IconEmoji: "💎"),
        new ShopItemDto(
            Code: "STREAK_SHIELD",
            Name: "Streak Shield",
            Description: "Bảo vệ chuỗi streak của bạn khỏi bị reset khi bỏ lỡ 1 ngày.",
            CoinPrice: 200,
            RewardType: "voucher",
            RewardDetail: "Streak Shield x1",
            IconEmoji: "🛡️"),
    ];

    public Task<IReadOnlyList<ShopItemDto>> GetCatalogAsync(CancellationToken cancellationToken = default) =>
        Task.FromResult(Catalog);

    public async Task<PurchaseResultDto> PurchaseAsync(string itemCode, CancellationToken cancellationToken = default)
    {
        var userId = _currentUser.RequireUserId();

        var item = Catalog.FirstOrDefault(i => i.Code == itemCode)
            ?? throw new NotFoundException("ShopItem", itemCode);

        var profile = await _repo.GetGamificationForUpdateAsync(userId, cancellationToken)
            ?? throw new NotFoundException("GamificationProfile", userId);

        if (profile.SyncCoins < item.CoinPrice)
            throw new BadRequestException($"Không đủ SyncCoins. Cần {item.CoinPrice}, hiện có {profile.SyncCoins:F0}.");

        profile.SyncCoins -= item.CoinPrice;
        profile.UpdatedAt = DateTimeOffset.UtcNow;

        var rewardDetail = await ApplyRewardAsync(item, userId, profile, cancellationToken);

        await _repo.SaveChangesAsync(cancellationToken);

        // XP rewards may unlock achievements
        if (item.RewardType == "xp")
            await _achievements.CheckAndUnlockAsync(userId, cancellationToken);

        return new PurchaseResultDto(item.Name, item.CoinPrice, profile.SyncCoins, item.RewardType, rewardDetail);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private async Task<string> ApplyRewardAsync(
        ShopItemDto item,
        Guid userId,
        GamificationProfile profile,
        CancellationToken cancellationToken)
    {
        if (item.RewardType == "xp")
        {
            var xp = item.Code == "XP_BOOST_100" ? 100 : 500;
            profile.CurrentXP += xp;
            AchievementService.CheckLevelUpStatic(profile);
            return item.RewardDetail;
        }

        if (item.RewardType == "voucher")
        {
            var (promotionType, value, name, codePrefix) = item.Code switch
            {
                "VOUCHER_10PCT" => ("Percentage", 10m, "Giảm 10% đơn hàng SYNC", "SYNC-10"),
                "VOUCHER_20PCT" => ("Percentage", 20m, "Giảm 20% đơn hàng SYNC", "SYNC-20"),
                "STREAK_SHIELD" => ("StreakShield", 1m, "Streak Shield – bảo vệ chuỗi tập luyện", "SYNC-SHIELD"),
                _ => ("General", 0m, item.Name, "SYNC"),
            };

            var code = GenerateVoucherCode(codePrefix);

            var voucher = new UserVoucher
            {
                UserId = userId,
                VoucherCode = code,
                Name = name,
                PromotionType = promotionType,
                Value = value,
                Status = VoucherStatus.Available,
                AcquiredAt = DateTimeOffset.UtcNow,
                ValidUntil = DateTimeOffset.UtcNow.AddDays(30),
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow,
            };

            _repo.AddVoucher(voucher);
            await Task.CompletedTask;

            return code;
        }

        return item.RewardDetail;
    }

    private static string GenerateVoucherCode(string prefix)
    {
        const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        var rng = new Random();
        var part1 = new string(Enumerable.Range(0, 4).Select(_ => chars[rng.Next(chars.Length)]).ToArray());
        var part2 = new string(Enumerable.Range(0, 4).Select(_ => chars[rng.Next(chars.Length)]).ToArray());
        return $"{prefix}-{part1}-{part2}";
    }
}
