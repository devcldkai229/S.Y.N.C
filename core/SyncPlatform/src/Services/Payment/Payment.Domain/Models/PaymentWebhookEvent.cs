using Libs.Shared.Common;

namespace Payment.Domain.Models;

public class PaymentWebhookEvent : BaseAuditableEntity
{
    public string Provider { get; set; } = string.Empty;

    public string EventType { get; set; } = string.Empty;

    public string ExternalEventId { get; set; } = string.Empty;

    public string? PayloadJson { get; set; }

    public bool Processed { get; set; }

    public DateTimeOffset? ProcessedAt { get; set; }

    public int RetryCount { get; set; }

    public string? ErrorMessage { get; set; }
}
