using Marketplace.Domain.Enums;
using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Driver.GeoJsonObjectModel;

namespace Marketplace.Domain.Models;

public class Partner : BaseMongoEntity
{
    public Guid OwnerUserId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string Slug { get; set; } = string.Empty;

    public PartnerType Type { get; set; }

    [BsonIgnoreIfNull]
    public string? Description { get; set; }

    [BsonIgnoreIfNull]
    public string? LogoUrl { get; set; }

    [BsonIgnoreIfNull]
    public string? CoverImageUrl { get; set; }

    public string Email { get; set; } = string.Empty;

    [BsonIgnoreIfNull]
    public string? PhoneNumber { get; set; }

    [BsonIgnoreIfNull]
    public string? Address { get; set; }

    [BsonIgnoreIfNull]
    public GeoJsonPoint<GeoJson2DGeographicCoordinates>? Location { get; set; }

    [BsonIgnoreIfNull]
    public decimal? ServiceRadiusKm { get; set; }

    public List<OperatingHour> OperatingHours { get; set; } = [];

    public decimal CommissionRate { get; set; }

    public PartnerStatus Status { get; set; }

    public decimal RatingAverage { get; set; }

    public int RatingCount { get; set; }

    public bool IsAiRecommendable { get; set; }

    public class OperatingHour
    {
        public int DayOfWeek { get; set; }

        public string OpenTime { get; set; } = string.Empty;

        public string CloseTime { get; set; } = string.Empty;

        public bool IsClosed { get; set; }
    }
}
