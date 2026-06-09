using Libs.Shared.Common;
using Payment.Domain.Enums;

namespace Payment.Domain.Models;

public class Transaction : BaseAuditableEntity
{
    public Guid? WalletId { get; set; }

    public Guid UserId { get; set; }

    public TransactionType TransactionType { get; set; }

    public TransactionStatus Status { get; set; }

    public PaymentMethod PaymentMethod { get; set; }

    public decimal Amount { get; set; }

    public string Currency { get; set; } = "VND";

    public string? ExternalReferenceId { get; set; }

    public long OrderCode { get; set; }

    public PaymentProvider Provider { get; set; }

    public string? RawProviderPayload { get; set; }

    public string? RelatedEntityType { get; set; }

    public Guid? RelatedEntityId { get; set; }

    public string? Description { get; set; }

    public bool IsAiInitiated { get; set; }

    public string? AIReasoningSnapshotJson { get; set; }

    public SpendingAuthorizationType SpendingAuthorizationType { get; set; }

    public DateTimeOffset? ProcessedAt { get; set; }

    public string? FailedReason { get; set; }
}
