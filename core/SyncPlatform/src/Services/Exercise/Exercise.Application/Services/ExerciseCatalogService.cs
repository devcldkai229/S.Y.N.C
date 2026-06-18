using Exercise.Application.Common;
using Exercise.Application.DTOs;
using Exercise.Application.Exceptions;
using Exercise.Application.Mappers;
using Exercise.Domain.Common;
using Exercise.Domain.Models;
using Exercise.Domain.Repositories;
using Libs.Shared.Enums;

namespace Exercise.Application.Services;

public class ExerciseCatalogService : IExerciseCatalogService
{
    private readonly IExerciseCatalogRepository _repository;
    private readonly IExerciseMotionAssetRepository _assetRepository;
    private readonly IStorageService _storageService;

    public ExerciseCatalogService(
        IExerciseCatalogRepository repository,
        IExerciseMotionAssetRepository assetRepository,
        IStorageService storageService)
    {
        _repository = repository;
        _assetRepository = assetRepository;
        _storageService = storageService;
    }

    public async Task<(IReadOnlyList<ExerciseCatalogDto> Items, PaginationMetadata Pagination)> SearchActiveAsync(
        ExerciseSearchRequest request,
        CancellationToken cancellationToken = default)
    {
        var pageNumber = Math.Max(1, request.PageNumber);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var criteria = new ExerciseCatalogSearchCriteria
        {
            Query = request.Query,
            PrimaryMuscle = request.PrimaryMuscle,
            Equipment = request.Equipment,
            PageNumber = pageNumber,
            PageSize = pageSize
        };

        if (!string.IsNullOrWhiteSpace(request.Category) && Enum.TryParse<ExerciseCategory>(request.Category, true, out var category))
        {
            criteria.Category = category;
        }

        if (!string.IsNullOrWhiteSpace(request.Difficulty) && Enum.TryParse<Difficulty>(request.Difficulty, true, out var difficulty))
        {
            criteria.Difficulty = difficulty;
        }

        if (!string.IsNullOrWhiteSpace(request.BodyRegion) && Enum.TryParse<BodyRegion>(request.BodyRegion, true, out var bodyRegion))
        {
            criteria.BodyRegion = bodyRegion;
        }

        if (!string.IsNullOrWhiteSpace(request.MovementPattern) && Enum.TryParse<MovementPattern>(request.MovementPattern, true, out var movementPattern))
        {
            criteria.MovementPattern = movementPattern;
        }

        var (entities, totalRecords) = await _repository.SearchActivePagedAsync(criteria, cancellationToken);
        var dtos = await MapWithThumbnailsAsync(entities, cancellationToken);
        var pagination = new PaginationMetadata(pageNumber, pageSize, totalRecords);

        return (dtos, pagination);
    }

    public async Task<ExerciseCatalogDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(ExerciseCatalog), id);
        return await MapWithThumbnailAsync(entity, cancellationToken);
    }

    public async Task<ExerciseCatalogDto> GetByCodeAsync(string code, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByCodeAsync(code, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(ExerciseCatalog), code);
        return await MapWithThumbnailAsync(entity, cancellationToken);
    }

    public async Task<ExerciseCatalogDto> GetBySlugAsync(string slug, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetBySlugAsync(slug, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(ExerciseCatalog), slug);
        return await MapWithThumbnailAsync(entity, cancellationToken);
    }

    public async Task<ExerciseCatalogDto> CreateAsync(CreateExerciseCatalogDto dto, CancellationToken cancellationToken = default)
    {
        var existing = await _repository.GetByCodeAsync(dto.ExerciseCode, cancellationToken);
        if (existing != null)
            throw new ConflictException($"Exercise code '{dto.ExerciseCode}' already exists.");

        var entity = new ExerciseCatalog();
        entity.UpdateEntity(dto);
        entity.IsActive = true; 

        await _repository.CreateAsync(entity, cancellationToken);

        return entity.ToDto();
    }

    public async Task UpdateAsync(Guid id, UpdateExerciseCatalogDto dto, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(ExerciseCatalog), id);

        entity.UpdateEntity(dto);

        await _repository.UpdateAsync(id, entity, cancellationToken);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(ExerciseCatalog), id);

        entity.IsActive = false;
        await _repository.UpdateAsync(id, entity, cancellationToken);
    }

    public async Task<ExerciseCatalogDetailDto> GetDetailAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(ExerciseCatalog), id);

        var assets = await _assetRepository.GetByExerciseIdAsync(id, cancellationToken);
        var assetDtos = assets.Select(a => a.ToDto(_storageService)).ToList();

        return entity.ToDetailDto(assetDtos);
    }

    private async Task<ExerciseCatalogDto> MapWithThumbnailAsync(
        ExerciseCatalog entity,
        CancellationToken cancellationToken)
    {
        var thumbnails = await _assetRepository.GetPrimaryImagesByExerciseIdsAsync([entity.Id], cancellationToken);
        thumbnails.TryGetValue(entity.Id, out var asset);
        var thumbnailUrl = asset?.ResolveDisplayImageUrl(_storageService);
        return entity.ToDto(thumbnailUrl);
    }

    public async Task<IReadOnlyDictionary<Guid, string?>> GetThumbnailUrlsAsync(
        IReadOnlyList<Guid> exerciseIds,
        CancellationToken cancellationToken = default)
    {
        if (exerciseIds.Count == 0)
            return new Dictionary<Guid, string?>();

        var ids = exerciseIds.Distinct().ToList();
        var thumbnails = await _assetRepository.GetPrimaryImagesByExerciseIdsAsync(ids, cancellationToken);

        return ids.ToDictionary(
            id => id,
            id => thumbnails.TryGetValue(id, out var asset)
                ? asset.ResolveDisplayImageUrl(_storageService)
                : null);
    }

    private async Task<IReadOnlyList<ExerciseCatalogDto>> MapWithThumbnailsAsync(
        IReadOnlyList<ExerciseCatalog> entities,
        CancellationToken cancellationToken)
    {
        if (entities.Count == 0) return [];

        var ids = entities.Select(e => e.Id).ToList();
        var thumbnails = await _assetRepository.GetPrimaryImagesByExerciseIdsAsync(ids, cancellationToken);

        return entities
            .Select(entity =>
            {
                thumbnails.TryGetValue(entity.Id, out var asset);
                var thumbnailUrl = asset?.ResolveDisplayImageUrl(_storageService);
                return entity.ToDto(thumbnailUrl);
            })
            .ToList();
    }
}
