using MongoDB.Bson.Serialization.Attributes;
using Libs.Shared.Enums;

namespace Exercise.Domain.Models;

public class ExerciseMotionAsset : BaseMongoEntity
{
    public Guid ExerciseId { get; set; }

    public AssetType AssetType { get; set; }

    // Dùng chung cho cả link Video (.mp4) hoặc link Unity Bundle
    public string ResourceUrl { get; set; } = string.Empty;

    // Ảnh bìa để hiển thị nhanh ngoài danh sách mà không cần load 3D/Video
    [BsonIgnoreIfNull]
    public string? ThumbnailUrl { get; set; }

    // --- CÁC TRƯỜNG DÀNH RIÊNG CHO UNITY (Sẽ null nếu là Video) ---
    
    [BsonIgnoreIfNull]
    public string? UnityPrefabId { get; set; }

    [BsonIgnoreIfNull]
    public string? UnityAnimationClip { get; set; }

    public int AnimationDurationSeconds { get; set; }

}
