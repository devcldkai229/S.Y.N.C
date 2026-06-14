using System.Security.Cryptography;
using System.Text;
using Libs.Shared.Common;
using Libs.Shared.Enums;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Helpers;
using Marketplace.Domain.Models;
using Marketplace.Infrastructure.Persistence.Seed;
using Marketplace.SeedTool.Models;

namespace Marketplace.SeedTool.Services;

public sealed class MarketplaceMapper
{
    public Partner MapPartner(KitchenSeedDto kitchen, Guid? existingOwnerUserId = null)
    {
        return new Partner
        {
            OwnerUserId = ResolveOwnerUserId(kitchen.Slug, existingOwnerUserId),
            Name = kitchen.Name,
            Slug = kitchen.Slug,
            Type = ParseEnum<PartnerType>(kitchen.Type),
            Description = kitchen.Description,
            Email = kitchen.Email,
            PhoneNumber = kitchen.PhoneNumber,
            Address = kitchen.Address,
            Location = GeoLocationMapping.ToGeoJsonPoint(kitchen.Location.Lat, kitchen.Location.Lng),
            ServiceRadiusKm = kitchen.ServiceRadiusKm,
            OperatingHours = BuildOperatingHours(kitchen.OperatingHours),
            CommissionRate = NormalizeCommissionRate(kitchen.CommissionRate),
            Status = PartnerStatus.Active,
            RatingAverage = kitchen.RatingAverage,
            RatingCount = kitchen.RatingCount,
            IsAiRecommendable = kitchen.IsAiRecommendable,
        };
    }

    public FoodMenuItem MapFoodMenuItem(DishSeedDto dish, Guid partnerId)
    {
        return new FoodMenuItem
        {
            PartnerId = partnerId,
            NameVi = dish.NameVi,
            NameEn = dish.NameEn,
            Slug = dish.Slug,
            Description = dish.Description,
            Category = ParseEnum<FoodCategory>(dish.Category),
            Price = dish.Price,
            Currency = "VND",
            PrepTimeMinutes = dish.PrepTimeMinutes,
            Nutrition = new NutritionSnapshot
            {
                Calories = dish.Nutrition.Calories,
                ProteinGram = dish.Nutrition.ProteinGram,
                CarbGram = dish.Nutrition.CarbGram,
                FatGram = dish.Nutrition.FatGram,
                ServingDescription = dish.Nutrition.ServingDescription,
            },
            DietaryTags = dish.DietaryTags
                .Select(tag => ParseEnum<DietaryTag>(tag))
                .ToList(),
            SpiceLevel = ParseEnum<SpiceLevel>(dish.SpiceLevel),
            Availability = ParseEnum<AvailabilityStatus>(dish.Availability),
            IsAiRecommended = dish.IsAiRecommended,
        };
    }

    public static string PartnerLogoKey(string kitchenSlug, string keyPrefix)
        => $"{keyPrefix.TrimEnd('/')}/{kitchenSlug}/logo.webp";

    public static string PartnerCoverKey(string kitchenSlug, string keyPrefix)
        => $"{keyPrefix.TrimEnd('/')}/{kitchenSlug}/cover.webp";

    public static string NormalizeS3Key(string? s3Key, string keyPrefix, string kitchenSlug, string fileName)
    {
        if (!string.IsNullOrWhiteSpace(s3Key))
            return s3Key.TrimStart('/');

        return $"{keyPrefix.TrimEnd('/')}/{kitchenSlug}/{fileName}";
    }

    private static List<Partner.OperatingHour> BuildOperatingHours(OperatingHoursSeedDto hours)
    {
        var closed = new HashSet<int>(hours.ClosedDays);
        var result = new List<Partner.OperatingHour>(7);

        for (var day = 1; day <= 7; day++)
        {
            var closedDayValue = day == 7 ? 0 : day;
            result.Add(new Partner.OperatingHour
            {
                DayOfWeek = day,
                OpenTime = hours.OpenTime,
                CloseTime = hours.CloseTime,
                IsClosed = closed.Contains(closedDayValue),
            });
        }

        return result;
    }

    private static decimal NormalizeCommissionRate(decimal rate)
        => rate is > 0 and < 1 ? Math.Round(rate * 100m, 2) : rate;

    public static Guid ResolveOwnerUserId(string slug, Guid? existingOwnerUserId = null)
    {
        if (existingOwnerUserId is { } existing && existing != Guid.Empty)
            return existing;

        return new Guid(MD5.HashData(
            Encoding.UTF8.GetBytes($"marketplace-kitchen:{MarketplaceSeedData.PartnerUserId}:{slug}")));
    }

    private static TEnum ParseEnum<TEnum>(string value) where TEnum : struct, Enum
    {
        if (Enum.TryParse<TEnum>(value, ignoreCase: true, out var parsed))
            return parsed;

        throw new ArgumentException($"Unknown {typeof(TEnum).Name} value: '{value}'");
    }
}
