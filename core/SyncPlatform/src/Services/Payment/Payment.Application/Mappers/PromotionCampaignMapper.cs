using System.Text.Json;
using Payment.Application.DTOs;
using Payment.Domain.Models;

namespace Payment.Application.Mappers;

public static class PromotionCampaignMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public static PromotionCampaignDto ToDto(this PromotionCampaign entity)
    {
        List<string>? productTypes = null;
        if (!string.IsNullOrWhiteSpace(entity.ApplicableProductTypesJson))
        {
            try
            {
                productTypes = JsonSerializer.Deserialize<List<string>>(entity.ApplicableProductTypesJson, JsonOptions);
            }
            catch
            {
                productTypes = new List<string>();
            }
        }

        return new PromotionCampaignDto
        {
            Id = entity.Id,
            Name = entity.Name,
            PromotionType = entity.PromotionType,
            Value = entity.Value,
            CouponCode = entity.CouponCode,
            ApplicableProductTypes = productTypes,
            MinimumSpend = entity.MinimumSpend,
            UsageLimit = entity.UsageLimit,
            StartsAt = entity.StartsAt,
            EndsAt = entity.EndsAt,
            IsActive = entity.IsActive,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }

    public static void UpdateEntity(this UpdatePromotionCampaignDto dto, PromotionCampaign entity)
    {
        entity.Name = dto.Name;
        entity.PromotionType = dto.PromotionType;
        entity.Value = dto.Value;
        entity.CouponCode = string.IsNullOrWhiteSpace(dto.CouponCode) ? null : dto.CouponCode.Trim().ToUpper();
        entity.ApplicableProductTypesJson = dto.ApplicableProductTypes != null ? JsonSerializer.Serialize(dto.ApplicableProductTypes, JsonOptions) : null;
        entity.MinimumSpend = dto.MinimumSpend;
        entity.UsageLimit = dto.UsageLimit;
        entity.StartsAt = dto.StartsAt;
        entity.EndsAt = dto.EndsAt;
        entity.IsActive = dto.IsActive;
        entity.UpdatedAt = DateTimeOffset.UtcNow;
    }

    public static PromotionCampaign ToEntity(this CreatePromotionCampaignDto dto)
    {
        return new PromotionCampaign
        {
            Name = dto.Name,
            PromotionType = dto.PromotionType,
            Value = dto.Value,
            CouponCode = string.IsNullOrWhiteSpace(dto.CouponCode) ? null : dto.CouponCode.Trim().ToUpper(),
            ApplicableProductTypesJson = dto.ApplicableProductTypes != null ? JsonSerializer.Serialize(dto.ApplicableProductTypes, JsonOptions) : null,
            MinimumSpend = dto.MinimumSpend,
            UsageLimit = dto.UsageLimit,
            StartsAt = dto.StartsAt,
            EndsAt = dto.EndsAt,
            IsActive = dto.IsActive
        };
    }
}
