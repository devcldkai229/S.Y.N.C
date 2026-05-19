using MongoDB.Bson.Serialization.Attributes;
using Libs.Shared.Enums;

namespace Exercise.Domain.Models;

public class ExerciseMotionAsset : BaseMongoEntity
{
    public Guid ExerciseId { get; set; }

    public AssetType AssetType { get; set; }

    [BsonIgnoreIfNull]
    public string? UnityPrefabId { get; set; }

    [BsonIgnoreIfNull]
    public string? UnityAnimationClip { get; set; }

    [BsonIgnoreIfNull]
    public string? VideoUrl { get; set; }

    [BsonIgnoreIfNull]
    public string? ThumbnailUrl { get; set; }

    [BsonIgnoreIfNull]
    public string? S3Key { get; set; }

    [BsonIgnoreIfNull]
    public string? CdnUrl { get; set; }

    public int AnimationDurationSeconds { get; set; }

    public List<string> CameraAngles { get; set; } = [];

    public bool SupportsRealtimePoseOverlay { get; set; }

    [BsonIgnoreIfNull]
    public string? PoseDetectionModel { get; set; }

    public bool SupportsARMode { get; set; }

    public List<string> SupportedPlatforms { get; set; } = [];

    public List<string> QualityVariants { get; set; } = [];
}
