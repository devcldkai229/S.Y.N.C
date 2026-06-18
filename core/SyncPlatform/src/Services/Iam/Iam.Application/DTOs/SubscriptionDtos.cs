using Iam.Domain.Enums;

namespace Iam.Application.DTOs;

public sealed record SetSubscriptionTierRequest(
    Guid UserId,
    SubscriptionTier Tier);
