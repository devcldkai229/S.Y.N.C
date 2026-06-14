using Iam.Domain.Enums;

namespace Iam.Application.Abstractions;

public interface ISubscriptionTierService
{
    /// <summary>Set the subscription tier for a user. Called by Payment after activation or expiry.</summary>
    Task SetTierAsync(Guid userId, SubscriptionTier tier, CancellationToken cancellationToken = default);
}
