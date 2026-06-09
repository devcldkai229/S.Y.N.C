using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Exercise.Application.DTOs;
using Exercise.Application.Exceptions;
using Exercise.Application.Mappers;
using Exercise.Domain.Models;
using Exercise.Domain.Repositories;
using Exercise.Application.Configuration;
using Microsoft.Extensions.Options;
using Libs.Shared.Enums;

namespace Exercise.Application.Services;

public class ExerciseMotionAssetService : IExerciseMotionAssetService
{
    private readonly IExerciseMotionAssetRepository _assetRepository;
    private readonly IExerciseCatalogRepository _catalogRepository;
    private readonly IStorageService _storageService;
    private readonly MinioOptions _minioOptions;

    public ExerciseMotionAssetService(
        IExerciseMotionAssetRepository assetRepository,
        IExerciseCatalogRepository catalogRepository,
        IStorageService storageService,
        IOptions<MinioOptions> minioOptions)
    {
        _assetRepository = assetRepository;
        _catalogRepository = catalogRepository;
        _storageService = storageService;
        _minioOptions = minioOptions.Value;
    }

    public async Task<IReadOnlyList<ExerciseMotionAssetDto>> GetByExerciseIdAsync(Guid exerciseId, CancellationToken cancellationToken = default)
    {
        var entities = await _assetRepository.GetByExerciseIdAsync(exerciseId, cancellationToken);
        return entities.Select(e => e.ToDto()).ToList();
    }

    public async Task<ExerciseMotionAssetDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _assetRepository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(ExerciseMotionAsset), id);
        return entity.ToDto();
    }

    public async Task<ExerciseMotionAssetDto> CreateAsync(CreateExerciseMotionAssetDto dto, CancellationToken cancellationToken = default)
    {
        await ValidateConstraintsAsync(dto, cancellationToken);

        var entity = new ExerciseMotionAsset();
        entity.UpdateEntity(dto);

        await _assetRepository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task UpdateAsync(Guid id, UpdateExerciseMotionAssetDto dto, CancellationToken cancellationToken = default)
    {
        var entity = await _assetRepository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(ExerciseMotionAsset), id);

        await ValidateConstraintsAsync(dto, cancellationToken);

        entity.UpdateEntity(dto);
        await _assetRepository.UpdateAsync(id, entity, cancellationToken);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var exists = await _assetRepository.ExistsAsync(id, cancellationToken);
        if (!exists)
            throw new NotFoundException(nameof(ExerciseMotionAsset), id);

        await _assetRepository.DeleteAsync(id, cancellationToken);
    }

    public async Task<ExerciseMotionAssetDto> UpdateWithUploadAsync(
        CreateExerciseMotionAssetUploadDto dto,
        CancellationToken cancellationToken = default)
    {
        // 1. Validate that the target exercise exists
        var exists = await _catalogRepository.ExistsAsync(dto.ExerciseId, cancellationToken);
        if (!exists)
            throw new NotFoundException(nameof(ExerciseCatalog), dto.ExerciseId);

        // 2. Find the existing motion asset for this exercise and asset type
        var existingAssets = await _assetRepository.GetByExerciseIdAsync(dto.ExerciseId, cancellationToken);
        var existingAsset = existingAssets.FirstOrDefault(a => a.AssetType == dto.AssetType);
        if (existingAsset == null)
        {
            throw new NotFoundException($"Motion asset of type '{dto.AssetType}' for exercise ID {dto.ExerciseId} was not found.");
        }

        // 3. Validate main file is not empty
        if (dto.FileStream == null || dto.FileStream.Length == 0 || dto.FileSize == 0)
        {
            throw new BadRequestException("Main file is empty.");
        }

        // 4. Validate file size of main file
        long maxFileSizeBytes = _minioOptions.MaxFileSizeMb * 1024 * 1024;
        if (dto.FileSize > maxFileSizeBytes)
        {
            throw new BadRequestException($"Main file size ({dto.FileSize / 1024.0 / 1024.0:F2} MB) exceeds maximum allowed size ({_minioOptions.MaxFileSizeMb} MB).");
        }

        // 5. Validate content type based on AssetType
        if (dto.AssetType == AssetType.Image)
        {
            if (!_minioOptions.AllowedImageContentTypes.Contains(dto.ContentType.ToLowerInvariant()))
            {
                throw new BadRequestException($"Content type '{dto.ContentType}' is not allowed for Image assets. Allowed: {string.Join(", ", _minioOptions.AllowedImageContentTypes)}");
            }
        }
        else if (dto.AssetType == AssetType.Video)
        {
            if (!_minioOptions.AllowedVideoContentTypes.Contains(dto.ContentType.ToLowerInvariant()))
            {
                throw new BadRequestException($"Content type '{dto.ContentType}' is not allowed for Video assets. Allowed: {string.Join(", ", _minioOptions.AllowedVideoContentTypes)}");
            }
        }
        else if (dto.AssetType == AssetType.Unity3D)
        {
            if (string.IsNullOrWhiteSpace(dto.UnityPrefabId) || string.IsNullOrWhiteSpace(dto.UnityAnimationClip))
            {
                throw new BadRequestException("UnityPrefabId and UnityAnimationClip are required when AssetType is Unity3D.");
            }
        }

        // 6. Validate optional thumbnail file (must be image type and satisfy size limit)
        if (dto.ThumbnailStream != null)
        {
            if (dto.ThumbnailSize.HasValue)
            {
                long maxThumbBytes = _minioOptions.MaxThumbnailSizeMb * 1024 * 1024;
                if (dto.ThumbnailSize.Value > maxThumbBytes)
                {
                    throw new BadRequestException($"Thumbnail file size ({dto.ThumbnailSize.Value / 1024.0 / 1024.0:F2} MB) exceeds maximum allowed size ({_minioOptions.MaxThumbnailSizeMb} MB).");
                }
            }
            if (string.IsNullOrWhiteSpace(dto.ThumbnailContentType) || !_minioOptions.AllowedImageContentTypes.Contains(dto.ThumbnailContentType.ToLowerInvariant()))
            {
                throw new BadRequestException($"Thumbnail content type '{dto.ThumbnailContentType}' is not allowed. Only image files are allowed as thumbnails.");
            }
        }

        // 7. Generate safe object keys using Guid-based names
        string fileExtension = Path.GetExtension(dto.FileName);
        string safeMainKey = $"{Guid.NewGuid()}{fileExtension}";

        string? safeThumbKey = null;
        if (dto.ThumbnailStream != null && !string.IsNullOrWhiteSpace(dto.ThumbnailFileName))
        {
            string thumbExtension = Path.GetExtension(dto.ThumbnailFileName);
            safeThumbKey = $"{Guid.NewGuid()}_thumb{thumbExtension}";
        }

        string? uploadedMainUrl = null;
        string? uploadedThumbUrl = null;

        // Save old URLs to delete them after successful upload and update
        string? oldResourceUrl = existingAsset.ResourceUrl;
        string? oldThumbnailUrl = existingAsset.ThumbnailUrl;

        try
        {
            // 8. Upload new main file to MinIO
            uploadedMainUrl = await _storageService.UploadFileAsync(dto.FileStream, safeMainKey, dto.ContentType, cancellationToken);

            // 9. Upload optional new thumbnail to MinIO
            if (dto.ThumbnailStream != null && safeThumbKey != null && dto.ThumbnailContentType != null)
            {
                uploadedThumbUrl = await _storageService.UploadFileAsync(dto.ThumbnailStream, safeThumbKey, dto.ThumbnailContentType, cancellationToken);
            }

            // 10. Update database entry
            existingAsset.ResourceUrl = uploadedMainUrl;
            existingAsset.ThumbnailUrl = uploadedThumbUrl;
            existingAsset.UnityPrefabId = dto.AssetType == AssetType.Unity3D ? dto.UnityPrefabId : null;
            existingAsset.UnityAnimationClip = dto.AssetType == AssetType.Unity3D ? dto.UnityAnimationClip : null;
            existingAsset.AnimationDurationSeconds = dto.AssetType == AssetType.Unity3D ? dto.AnimationDurationSeconds : 0;

            await _assetRepository.UpdateAsync(existingAsset.Id, existingAsset, cancellationToken);

            // 11. Delete old files from storage (cleanup)
            if (!string.IsNullOrWhiteSpace(oldResourceUrl))
            {
                try { await _storageService.DeleteFileAsync(oldResourceUrl, cancellationToken); } catch { /* ignore */ }
            }
            if (!string.IsNullOrWhiteSpace(oldThumbnailUrl))
            {
                try { await _storageService.DeleteFileAsync(oldThumbnailUrl, cancellationToken); } catch { /* ignore */ }
            }

            return existingAsset.ToDto();
        }
        catch (Exception)
        {
            // Rollback uploaded files if DB save or subsequent step fails
            if (uploadedMainUrl != null)
            {
                try { await _storageService.DeleteFileAsync(uploadedMainUrl, cancellationToken); } catch { /* ignore */ }
            }
            if (uploadedThumbUrl != null)
            {
                try { await _storageService.DeleteFileAsync(uploadedThumbUrl, cancellationToken); } catch { /* ignore */ }
            }
            throw;
        }
    }

    private async Task ValidateConstraintsAsync(CreateExerciseMotionAssetDto dto, CancellationToken cancellationToken)
    {
        var exists = await _catalogRepository.ExistsAsync(dto.ExerciseId, cancellationToken);
        if (!exists)
            throw new NotFoundException(nameof(ExerciseCatalog), dto.ExerciseId);

        if (dto.AssetType == AssetType.Unity3D)
        {
            if (string.IsNullOrWhiteSpace(dto.UnityPrefabId) || string.IsNullOrWhiteSpace(dto.UnityAnimationClip))
            {
                throw new BadRequestException("UnityPrefabId and UnityAnimationClip are required when AssetType is Unity3D.");
            }
        }
    }
}
