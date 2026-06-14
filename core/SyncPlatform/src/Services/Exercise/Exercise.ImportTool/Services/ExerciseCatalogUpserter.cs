using Exercise.Application.Configuration;
using Exercise.Domain.Models;
using Exercise.Domain.Repositories;
using Exercise.ImportTool.Models;
using Libs.Shared.Enums;
using Microsoft.Extensions.Options;

namespace Exercise.ImportTool.Services;

public sealed class ExerciseCatalogUpserter
{
    private readonly IExerciseCatalogRepository _catalogRepository;
    private readonly IExerciseMotionAssetRepository _assetRepository;
    private readonly StorageOptions _storageOptions;

    public ExerciseCatalogUpserter(
        IExerciseCatalogRepository catalogRepository,
        IExerciseMotionAssetRepository assetRepository,
        IOptions<StorageOptions> storageOptions)
    {
        _catalogRepository = catalogRepository;
        _assetRepository = assetRepository;
        _storageOptions = storageOptions.Value;
    }

    public async Task<bool> UpsertAsync(
        ExerciseCatalog catalog,
        IReadOnlyList<ExerciseMediaPipeline.UploadedImage> images,
        CancellationToken cancellationToken = default)
    {
        var existing = await _catalogRepository.GetByCodeAsync(catalog.ExerciseCode, cancellationToken);
        var isCreate = existing == null;

        if (existing == null)
        {
            await _catalogRepository.CreateAsync(catalog, cancellationToken);
        }
        else
        {
            catalog.Id = existing.Id;
            catalog.CreatedAt = existing.CreatedAt;
            catalog.UpdatedAt = DateTimeOffset.UtcNow;
            await _catalogRepository.UpdateAsync(existing.Id, catalog, cancellationToken);
        }

        if (images.Count > 0)
        {
            await ReplaceImageAssetsAsync(catalog.Id, images, cancellationToken);
        }

        return isCreate;
    }

    private async Task ReplaceImageAssetsAsync(
        Guid exerciseId,
        IReadOnlyList<ExerciseMediaPipeline.UploadedImage> images,
        CancellationToken cancellationToken)
    {
        var existingAssets = await _assetRepository.GetByExerciseIdAsync(exerciseId, cancellationToken);
        foreach (var asset in existingAssets.Where(a => a.AssetType == AssetType.Image))
        {
            await _assetRepository.DeleteAsync(asset.Id, cancellationToken);
        }

        if (images.Count == 0) return;

        var primary = images.FirstOrDefault(i => i.IsPrimary) ?? images[0];

        foreach (var image in images)
        {
            var entity = new ExerciseMotionAsset
            {
                ExerciseId = exerciseId,
                AssetType = AssetType.Image,
                S3Key = image.S3Key,
                ThumbnailS3Key = image.S3Key == primary.S3Key ? primary.S3Key : null,
                ResourceUrl = _storageOptions.PublicRead ? string.Empty : string.Empty,
                ThumbnailUrl = null,
                AnimationDurationSeconds = 0,
            };

            await _assetRepository.CreateAsync(entity, cancellationToken);
        }
    }
}
