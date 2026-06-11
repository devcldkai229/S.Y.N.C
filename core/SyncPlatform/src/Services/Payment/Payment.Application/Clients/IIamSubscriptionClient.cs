namespace Payment.Application.Clients;

public interface IIamSubscriptionClient
{
    /// <summary>
    /// Notify IAM to update a user's subscription tier.
    /// Called after subscription activation (Premium) or expiry/cancellation (Free).
    /// Fire-and-forget safe: caller should catch and log exceptions rather than failing the webhook.
    /// </summary>
    Task SetTierAsync(Guid userId, string tier, CancellationToken cancellationToken = default);
}
