using System.IO;
using Exercise.Application.Configuration;
using Exercise.Application.DTOs;
using Exercise.Application.Exceptions;
using Exercise.Application.Mappers;
using Exercise.Domain.Models;
using Exercise.Domain.Repositories;
using Libs.Shared.Enums;
using Microsoft.Extensions.Options;

namespace Exercise.Application.Services;

public class ExerciseMotionAssetService : IExerciseMotionAssetService
{
    private readonly IExerciseMotionAssetRepository _assetRepository;
    private readonly IExerciseCatalogRepository _catalogRepository;
    private readonly IStorageService _storageService;
    private readonly StorageOptions _storageOptions;

    public ExerciseMotionAssetService(
        IExerciseMotionAssetRepository assetRepository,
        IExerciseCatalogRepository catalogRepository,
        IStorageService storageService,
        IOptions<StorageOptions> storageOptions)
    {
        _assetRepository = assetRepository;
        _catalogRepository = catalogRepository;
        _storageService = storageService;
        _storageOptions = storageOptions.Value;
    }

    public async Task<IReadOnlyList<ExerciseMotionAssetDto>> GetByExerciseIdAsync(Guid exerciseId, CancellationToken cancellationToken = default)
    {
        var entities = await _assetRepository.GetByExerciseIdAsync(exerciseId, cancellationToken);
        return entities.Select(e => e.ToDto(_storageService)).ToList();
    }

    public async Task<ExerciseMotionAssetDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _assetRepository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(ExerciseMotionAsset), id);
        return entity.ToDto(_storageService);
    }

    public async Task<ExerciseMotionAssetDto> CreateAsync(CreateExerciseMotionAssetDto dto, CancellationToken cancellationToken = default)
    {
        await ValidateConstraintsAsync(dto, cancellationToken);

        var entity = new ExerciseMotionAsset();
        entity.UpdateEntity(dto);

        await _assetRepository.CreateAsync(entity, cancellationToken);
        return entity.ToDto(_storageService);
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
        var exists = await _catalogRepository.ExistsAsync(dto.ExerciseId, cancellationToken);
        if (!exists)
            throw new NotFoundException(nameof(ExerciseCatalog), dto.ExerciseId);

        var existingAssets = await _assetRepository.GetByExerciseIdAsync(dto.ExerciseId, cancellationToken);
        var existingAsset = existingAssets.FirstOrDefault(a => a.AssetType == dto.AssetType)
            ?? throw new NotFoundException($"Motion asset of type '{dto.AssetType}' for exercise ID {dto.ExerciseId} was not found.");

        if (dto.FileStream == null || dto.FileStream.Length == 0 || dto.FileSize == 0)
            throw new BadRequestException("Main file is empty.");

        ValidateUpload(dto);

        var fileExtension = Path.GetExtension(dto.FileName);
        var mainKey = $"{_storageOptions.KeyPrefix.TrimEnd('/')}/uploads/{Guid.NewGuid()}{fileExtension}";
        string? thumbKey = null;

        if (dto.ThumbnailStream != null && !string.IsNullOrWhiteSpace(dto.ThumbnailFileName))
        {
            var thumbExtension = Path.GetExtension(dto.ThumbnailFileName);
            thumbKey = $"{_storageOptions.KeyPrefix.TrimEnd('/')}/uploads/{Guid.NewGuid()}_thumb{thumbExtension}";
        }

        var oldMainKey = existingAsset.S3Key;
        var oldThumbKey = existingAsset.ThumbnailS3Key;

        try
        {
            await _storageService.UploadFileAsync(dto.FileStream, mainKey, dto.ContentType, cancellationToken);

            if (dto.ThumbnailStream != null && thumbKey != null && dto.ThumbnailContentType != null)
            {
                await _storageService.UploadFileAsync(dto.ThumbnailStream, thumbKey, dto.ThumbnailContentType, cancellationToken);
            }

            existingAsset.S3Key = mainKey;
            existingAsset.ThumbnailS3Key = thumbKey;
            existingAsset.ResourceUrl = _storageService.ResolveObjectUrl(mainKey);
            existingAsset.ThumbnailUrl = thumbKey != null
                ? _storageService.ResolveObjectUrl(thumbKey)
                : null;
            existingAsset.UnityPrefabId = dto.AssetType == AssetType.Unity3D ? dto.UnityPrefabId : null;
            existingAsset.UnityAnimationClip = dto.AssetType == AssetType.Unity3D ? dto.UnityAnimationClip : null;
            existingAsset.AnimationDurationSeconds = dto.AssetType == AssetType.Unity3D ? dto.AnimationDurationSeconds : 0;

            await _assetRepository.UpdateAsync(existingAsset.Id, existingAsset, cancellationToken);

            if (!string.IsNullOrWhiteSpace(oldMainKey))
            {
                try { await _storageService.DeleteFileByKeyAsync(oldMainKey, cancellationToken); } catch { /* ignore */ }
            }
            if (!string.IsNullOrWhiteSpace(oldThumbKey))
            {
                try { await _storageService.DeleteFileByKeyAsync(oldThumbKey, cancellationToken); } catch { /* ignore */ }
            }

            return existingAsset.ToDto(_storageService);
        }
        catch
        {
            try { await _storageService.DeleteFileByKeyAsync(mainKey, cancellationToken); } catch { /* ignore */ }
            if (thumbKey != null)
            {
                try { await _storageService.DeleteFileByKeyAsync(thumbKey, cancellationToken); } catch { /* ignore */ }
            }
            throw;
        }
    }

    private void ValidateUpload(CreateExerciseMotionAssetUploadDto dto)
    {
        var maxFileSizeBytes = _storageOptions.MaxFileSizeMb * 1024 * 1024;
        if (dto.FileSize > maxFileSizeBytes)
            throw new BadRequestException($"Main file exceeds {_storageOptions.MaxFileSizeMb} MB.");

        if (dto.AssetType == AssetType.Image &&
            !_storageOptions.AllowedImageContentTypes.Contains(dto.ContentType.ToLowerInvariant()))
        {
            throw new BadRequestException($"Content type '{dto.ContentType}' is not allowed for images.");
        }

        if (dto.AssetType == AssetType.Video &&
            !_storageOptions.AllowedVideoContentTypes.Contains(dto.ContentType.ToLowerInvariant()))
        {
            throw new BadRequestException($"Content type '{dto.ContentType}' is not allowed for videos.");
        }

        if (dto.ThumbnailStream != null)
        {
            if (dto.ThumbnailSize.HasValue)
            {
                var maxThumbBytes = _storageOptions.MaxThumbnailSizeMb * 1024 * 1024;
                if (dto.ThumbnailSize.Value > maxThumbBytes)
                    throw new BadRequestException($"Thumbnail exceeds {_storageOptions.MaxThumbnailSizeMb} MB.");
            }

            if (string.IsNullOrWhiteSpace(dto.ThumbnailContentType) ||
                !_storageOptions.AllowedImageContentTypes.Contains(dto.ThumbnailContentType.ToLowerInvariant()))
            {
                throw new BadRequestException("Thumbnail must be an allowed image type.");
            }
        }
    }

    private async Task ValidateConstraintsAsync(CreateExerciseMotionAssetDto dto, CancellationToken cancellationToken)
    {
        var exists = await _catalogRepository.ExistsAsync(dto.ExerciseId, cancellationToken);
        if (!exists)
            throw new NotFoundException(nameof(ExerciseCatalog), dto.ExerciseId);

        if (dto.AssetType == AssetType.Unity3D &&
            (string.IsNullOrWhiteSpace(dto.UnityPrefabId) || string.IsNullOrWhiteSpace(dto.UnityAnimationClip)))
        {
            throw new BadRequestException("UnityPrefabId and UnityAnimationClip are required for Unity3D assets.");
        }
    }
}
