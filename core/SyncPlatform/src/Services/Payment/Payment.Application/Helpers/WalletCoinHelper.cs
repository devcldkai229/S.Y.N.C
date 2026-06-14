namespace Payment.Application.Helpers;

public static class WalletCoinHelper
{
    public const decimal VndPerCoin = 100m;

    public static decimal VndToCoins(decimal amountVnd) =>
        Math.Round(amountVnd / VndPerCoin, 4, MidpointRounding.AwayFromZero);

    public static decimal CoinsToVnd(decimal coins) =>
        Math.Round(coins * VndPerCoin, 2, MidpointRounding.AwayFromZero);
}
