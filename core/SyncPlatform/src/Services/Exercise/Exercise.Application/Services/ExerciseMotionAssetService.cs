using Exercise.Application.DTOs;
using Exercise.Application.Exceptions;
using Exercise.Application.Mappers;
using Exercise.Domain.Models;
using Exercise.Domain.Repositories;
using Libs.Shared.Enums;

namespace Exercise.Application.Services;

public class ExerciseMotionAssetService : IExerciseMotionAssetService
{
    private readonly IExerciseMotionAssetRepository _assetRepository;
    private readonly IExerciseCatalogRepository _catalogRepository;

    public ExerciseMotionAssetService(
        IExerciseMotionAssetRepository assetRepository,
        IExerciseCatalogRepository catalogRepository)
    {
        _assetRepository = assetRepository;
        _catalogRepository = catalogRepository;
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
