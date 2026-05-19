using Libs.Shared.Common;
using Payment.Domain.Enums;

namespace Payment.Domain.Models;

public class WalletLedger : BaseAuditableEntity
{
    public Guid? WalletId { get; set; }

    public Guid TransactionId { get; set; }

    public WalletTransactionType EntryType { get; set; }

    public decimal Amount { get; set; }

    public decimal BalanceBefore { get; set; }

    public decimal BalanceAfter { get; set; }

    public string? MetadataJson { get; set; }
}
