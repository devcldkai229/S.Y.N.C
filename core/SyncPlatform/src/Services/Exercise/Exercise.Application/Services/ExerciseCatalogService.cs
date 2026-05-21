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

    public ExerciseCatalogService(
        IExerciseCatalogRepository repository,
        IExerciseMotionAssetRepository assetRepository)
    {
        _repository = repository;
        _assetRepository = assetRepository;
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
        var dtos = entities.Select(e => e.ToDto()).ToList();
        var pagination = new PaginationMetadata(pageNumber, pageSize, totalRecords);

        return (dtos, pagination);
    }

    public async Task<ExerciseCatalogDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(ExerciseCatalog), id);
        return entity.ToDto();
    }

    public async Task<ExerciseCatalogDto> GetByCodeAsync(string code, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByCodeAsync(code, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(ExerciseCatalog), code);
        return entity.ToDto();
    }

    public async Task<ExerciseCatalogDto> GetBySlugAsync(string slug, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetBySlugAsync(slug, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(ExerciseCatalog), slug);
        return entity.ToDto();
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
        var assetDtos = assets.Select(a => a.ToDto()).ToList();

        return entity.ToDetailDto(assetDtos);
    }
}
