using Payment.Application.DTOs;
using Payment.Domain.Models;

namespace Payment.Application.Mappers;

public static class UserSubscriptionMapper
{
    public static UserSubscriptionDto ToDto(this UserSubscription entity, string planName = "")
    {
        return new UserSubscriptionDto
        {
            Id = entity.Id,
            UserId = entity.UserId,
            SubscriptionPlanId = entity.SubscriptionPlanId,
            SubscriptionPlanName = planName,
            Status = entity.Status,
            StartedAt = entity.StartedAt,
            ExpiredAt = entity.ExpiredAt,
            AutoRenew = entity.AutoRenew,
            LastBillingAt = entity.LastBillingAt,
            NextBillingAt = entity.NextBillingAt,
            CancellationReason = entity.CancellationReason,
            ManagedBy = entity.ManagedBy,
            ExternalSubscriptionId = entity.ExternalSubscriptionId,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }

    public static UserSubscription ToEntity(this CreateUserSubscriptionDto dto)
    {
        return new UserSubscription
        {
            UserId = dto.UserId,
            SubscriptionPlanId = dto.SubscriptionPlanId,
            Status = dto.Status,
            StartedAt = dto.StartedAt,
            ExpiredAt = dto.ExpiredAt,
            AutoRenew = dto.AutoRenew,
            LastBillingAt = dto.LastBillingAt,
            NextBillingAt = dto.NextBillingAt,
            ManagedBy = dto.ManagedBy,
            ExternalSubscriptionId = dto.ExternalSubscriptionId
        };
    }

    public static void UpdateEntity(this UpdateUserSubscriptionDto dto, UserSubscription entity)
    {
        entity.Status = dto.Status;
        entity.ExpiredAt = dto.ExpiredAt;
        entity.AutoRenew = dto.AutoRenew;
        entity.LastBillingAt = dto.LastBillingAt;
        entity.NextBillingAt = dto.NextBillingAt;
        entity.CancellationReason = dto.CancellationReason;
        entity.ManagedBy = dto.ManagedBy;
        entity.ExternalSubscriptionId = dto.ExternalSubscriptionId;
        entity.UpdatedAt = DateTimeOffset.UtcNow;
    }
}
