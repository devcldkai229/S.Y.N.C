using System;
using System.IO;
using Libs.Shared.Enums;

namespace Exercise.Application.DTOs;

public class ExerciseMotionAssetDto
{
    public Guid Id { get; set; }
    public Guid ExerciseId { get; set; }
    public AssetType AssetType { get; set; }
    public string ResourceUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public string? S3Key { get; set; }
    public string? ThumbnailS3Key { get; set; }
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
    public string? S3Key { get; set; }
    public string? ThumbnailS3Key { get; set; }
    public string? UnityPrefabId { get; set; }
    public string? UnityAnimationClip { get; set; }
    public int AnimationDurationSeconds { get; set; }
}

public class UpdateExerciseMotionAssetDto : CreateExerciseMotionAssetDto
{
}

public class CreateExerciseMotionAssetUploadDto
{
    public Guid ExerciseId { get; set; }
    public AssetType AssetType { get; set; }
    
    // Main file data
    public string FileName { get; set; } = string.Empty;
    public Stream FileStream { get; set; } = Stream.Null;
    public string ContentType { get; set; } = string.Empty;
    public long FileSize { get; set; }

    // Optional thumbnail data
    public string? ThumbnailFileName { get; set; }
    public Stream? ThumbnailStream { get; set; }
    public string? ThumbnailContentType { get; set; }
    public long? ThumbnailSize { get; set; }

    // Unity metadata
    public string? UnityPrefabId { get; set; }
    public string? UnityAnimationClip { get; set; }
    public int AnimationDurationSeconds { get; set; }
}
