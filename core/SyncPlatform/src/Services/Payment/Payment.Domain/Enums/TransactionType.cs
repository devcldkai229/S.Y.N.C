namespace Payment.Domain.Enums;

public enum TransactionType
{
    MealPurchase = 0,
    SupplementPurchase = 1,
    DigitalAssetPurchase = 2,
    Subscription = 3,
    WalletTopup = 4,
    Refund = 5,
    Reward = 6
}
