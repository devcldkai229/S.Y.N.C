using System.Text.Json;
using Payment.Application.DTOs;
using Payment.Domain.Models;

namespace Payment.Application.Mappers;

public static class SubscriptionPlanMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public static SubscriptionPlanDto ToDto(this SubscriptionPlan entity)
    {
        List<string>? features = null;
        if (!string.IsNullOrWhiteSpace(entity.FeaturesJson))
        {
            try
            {
                features = JsonSerializer.Deserialize<List<string>>(entity.FeaturesJson, JsonOptions);
            }
            catch
            {
                features = new List<string>();
            }
        }

        return new SubscriptionPlanDto
        {
            Id = entity.Id,
            Name = entity.Name,
            Description = entity.Description,
            MonthlyPrice = entity.MonthlyPrice,
            YearlyPrice = entity.YearlyPrice,
            Currency = entity.Currency,
            Features = features,
            AiUsageLimitPerMonth = entity.AiUsageLimitPerMonth,
            PremiumWorkoutAccess = entity.PremiumWorkoutAccess,
            PremiumMarketplaceAccess = entity.PremiumMarketplaceAccess,
            PriorityAiResponses = entity.PriorityAiResponses,
            MaxAiAutoOrdersPerMonth = entity.MaxAiAutoOrdersPerMonth,
            IsActive = entity.IsActive,
            GooglePlayProductId = entity.GooglePlayProductId,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }

    public static void UpdateEntity(this UpdateSubscriptionPlanDto dto, SubscriptionPlan entity)
    {
        entity.Name = dto.Name;
        entity.Description = dto.Description;
        entity.MonthlyPrice = dto.MonthlyPrice;
        entity.YearlyPrice = dto.YearlyPrice;
        entity.Currency = dto.Currency;
        entity.FeaturesJson = dto.Features != null ? JsonSerializer.Serialize(dto.Features, JsonOptions) : null;
        entity.AiUsageLimitPerMonth = dto.AiUsageLimitPerMonth;
        entity.PremiumWorkoutAccess = dto.PremiumWorkoutAccess;
        entity.PremiumMarketplaceAccess = dto.PremiumMarketplaceAccess;
        entity.PriorityAiResponses = dto.PriorityAiResponses;
        entity.MaxAiAutoOrdersPerMonth = dto.MaxAiAutoOrdersPerMonth;
        entity.IsActive = dto.IsActive;
        entity.GooglePlayProductId = dto.GooglePlayProductId;
        entity.UpdatedAt = DateTimeOffset.UtcNow;
    }

    public static SubscriptionPlan ToEntity(this CreateSubscriptionPlanDto dto)
    {
        return new SubscriptionPlan
        {
            Name = dto.Name,
            Description = dto.Description,
            MonthlyPrice = dto.MonthlyPrice,
            YearlyPrice = dto.YearlyPrice,
            Currency = dto.Currency,
            FeaturesJson = dto.Features != null ? JsonSerializer.Serialize(dto.Features, JsonOptions) : null,
            AiUsageLimitPerMonth = dto.AiUsageLimitPerMonth,
            PremiumWorkoutAccess = dto.PremiumWorkoutAccess,
            PremiumMarketplaceAccess = dto.PremiumMarketplaceAccess,
            PriorityAiResponses = dto.PriorityAiResponses,
            MaxAiAutoOrdersPerMonth = dto.MaxAiAutoOrdersPerMonth,
            IsActive = dto.IsActive,
            GooglePlayProductId = dto.GooglePlayProductId
        };
    }
}
