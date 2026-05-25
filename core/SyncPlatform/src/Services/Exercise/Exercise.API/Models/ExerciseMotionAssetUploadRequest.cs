using System;
using Microsoft.AspNetCore.Http;
using Libs.Shared.Enums;

namespace Exercise.API.Models;

public class ExerciseMotionAssetUploadRequest
{
    public AssetType AssetType { get; set; }
    public IFormFile File { get; set; } = null!;
    public IFormFile? ThumbnailFile { get; set; }
    public string? UnityPrefabId { get; set; }
    public string? UnityAnimationClip { get; set; }
    public int AnimationDurationSeconds { get; set; }
}
