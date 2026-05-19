using Libs.Shared.Common;
using Payment.Domain.Enums;

namespace Payment.Domain.Models;

public class Wallet : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public decimal AvailableBalance { get; set; }

    public decimal LockedBalance { get; set; }

    public decimal RewardCoinBalance { get; set; }

    public string Currency { get; set; } = "VND";

    public bool AutoPaymentEnabled { get; set; }

    public decimal DailyAutoSpendingLimit { get; set; }

    public decimal MonthlyAutoSpendingLimit { get; set; }

    public decimal RemainingDailyAutoLimit { get; set; }

    public decimal RemainingMonthlyAutoLimit { get; set; }

    public DateTimeOffset LastResetDailyLimitAt { get; set; }

    public DateTimeOffset LastResetMonthlyLimitAt { get; set; }

    public decimal RiskScore { get; set; }
}
