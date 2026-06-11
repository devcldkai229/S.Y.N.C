using Marketplace.Application.DTOs;
using Marketplace.Domain.Helpers;
using Marketplace.Domain.Models;

namespace Marketplace.Application.Mappers;

public static class MarketplaceMapper
{
    public static PartnerDto ToDto(this Partner entity, double? distanceKm = null) => new()
    {
        Id = entity.Id,
        OwnerUserId = entity.OwnerUserId,
        Name = entity.Name,
        Slug = entity.Slug,
        Type = entity.Type,
        Description = entity.Description,
        LogoUrl = entity.LogoUrl,
        CoverImageUrl = entity.CoverImageUrl,
        Email = entity.Email,
        PhoneNumber = entity.PhoneNumber,
        Address = entity.Address,
        Location = ToLocationDto(entity),
        ServiceRadiusKm = entity.ServiceRadiusKm,
        OperatingHours = entity.OperatingHours.Select(ToDto).ToList(),
        CommissionRate = entity.CommissionRate,
        Status = entity.Status,
        RatingAverage = entity.RatingAverage,
        RatingCount = entity.RatingCount,
        IsAiRecommendable = entity.IsAiRecommendable,
        DistanceKm = distanceKm,
    };

    public static FoodMenuItemDto ToDto(this FoodMenuItem entity) => new()
    {
        Id = entity.Id,
        PartnerId = entity.PartnerId,
        NameVi = entity.NameVi,
        NameEn = entity.NameEn,
        Slug = entity.Slug,
        Description = entity.Description,
        ImageUrls = entity.ImageUrls,
        Category = entity.Category,
        Price = entity.Price,
        Currency = entity.Currency,
        PrepTimeMinutes = entity.PrepTimeMinutes,
        Nutrition = NutritionSnapshotDto.FromValueObject(entity.Nutrition),
        DietaryTags = entity.DietaryTags,
        SpiceLevel = entity.SpiceLevel,
        Availability = entity.Availability,
        IsAiRecommended = entity.IsAiRecommended,
        RatingAverage = entity.RatingAverage,
        RatingCount = entity.RatingCount,
    };

    public static AffiliateProductDto ToDto(this AffiliateProduct entity) => new()
    {
        Id = entity.Id,
        PartnerId = entity.PartnerId,
        BrandName = entity.BrandName,
        NameVi = entity.NameVi,
        NameEn = entity.NameEn,
        Slug = entity.Slug,
        Description = entity.Description,
        ImageUrls = entity.ImageUrls,
        Category = entity.Category,
        Price = entity.Price,
        Currency = entity.Currency,
        AffiliateUrl = entity.AffiliateUrl,
        ExternalProductId = entity.ExternalProductId,
        CommissionRate = entity.CommissionRate,
        Nutrition = entity.Nutrition == null ? null : NutritionSnapshotDto.FromValueObject(entity.Nutrition),
        DietaryTags = entity.DietaryTags,
        Availability = entity.Availability,
        RatingAverage = entity.RatingAverage,
        RatingCount = entity.RatingCount,
    };

    public static ReviewDto ToDto(this Review entity) => new()
    {
        Id = entity.Id,
        UserId = entity.UserId,
        AuthorSnapshot = new AuthorSnapshotDto
        {
            FullName = entity.AuthorSnapshot.FullName,
            AvatarUrl = entity.AuthorSnapshot.AvatarUrl,
        },
        TargetType = entity.TargetType,
        TargetId = entity.TargetId,
        Rating = entity.Rating,
        Comment = entity.Comment,
        ImageUrls = entity.ImageUrls,
        OrderId = entity.OrderId,
        IsVerifiedPurchase = entity.IsVerifiedPurchase,
        PartnerReply = entity.PartnerReply,
        CreatedAt = entity.CreatedAt,
    };

    private static LocationDto? ToLocationDto(Partner entity)
    {
        var coords = GeoLocationMapping.FromGeoJsonPoint(entity.Location);
        return coords == null
            ? null
            : new LocationDto { Latitude = coords.Value.Latitude, Longitude = coords.Value.Longitude };
    }

    private static OperatingHourDto ToDto(Partner.OperatingHour hour) => new()
    {
        DayOfWeek = hour.DayOfWeek,
        OpenTime = hour.OpenTime,
        CloseTime = hour.CloseTime,
        IsClosed = hour.IsClosed,
    };
}
