using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Driver.GeoJsonObjectModel;
using Social.Domain.Enums;

namespace Social.Domain.Models;

public class CommunityChallenge : BaseMongoEntity
{
    public Guid CreatorId { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Last moment users can register. After this until <see cref="StartDate"/> status is Upcoming.
    /// </summary>
    public DateTimeOffset RegistrationDeadline { get; set; }

    public DateTimeOffset StartDate { get; set; }

    public DateTimeOffset EndDate { get; set; }

    [BsonIgnoreIfNull]
    public ChallengeGoalType? GoalType { get; set; }

    [BsonIgnoreIfNull]
    public decimal? PointRewards { get; set; }

    [BsonIgnoreIfNull]
    public string[]? Gifts { get; set; }

    /// <summary>
    /// S3 URL for challenge background (image or video).
    /// </summary>
    [BsonIgnoreIfNull]
    public string? BackgroundUrl { get; set; }

    [BsonIgnoreIfNull]
    public decimal? TargetValue { get; set; }

    public int ParticipantCount { get; set; }

    [BsonIgnoreIfNull]
    public string? Address { get; set; }

    /// <summary>
    /// GeoJSON Point (longitude, latitude) for MongoDB 2dsphere queries.
    /// </summary>
    [BsonIgnoreIfNull]
    public GeoJsonPoint<GeoJson2DGeographicCoordinates>? Location { get; set; }

    public ChallengeStatus Status { get; set; }
}
