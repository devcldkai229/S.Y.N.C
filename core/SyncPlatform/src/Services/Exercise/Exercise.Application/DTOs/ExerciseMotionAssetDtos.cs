using Libs.Shared.Enums;

namespace Exercise.Application.DTOs;

public class ExerciseMotionAssetDto
{
    public Guid Id { get; set; }
    public Guid ExerciseId { get; set; }
    public AssetType AssetType { get; set; }
    public string ResourceUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public string? UnityPrefabId { get; set; }
    public string? UnityAnimationClip { get; set; }
    public int AnimationDurationSeconds { get; set; }
}

public class CreateExerciseMotionAssetDto
{
    public Guid ExerciseId { get; set; }
    public AssetType AssetType { get; set; }
    public string ResourceUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public string? UnityPrefabId { get; set; }
    public string? UnityAnimationClip { get; set; }
    public int AnimationDurationSeconds { get; set; }
}

public class UpdateExerciseMotionAssetDto : CreateExerciseMotionAssetDto
{
}
