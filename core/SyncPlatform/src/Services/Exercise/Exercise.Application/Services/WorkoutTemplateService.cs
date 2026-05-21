using Exercise.Application.Common;
using Exercise.Application.DTOs;
using Exercise.Application.Exceptions;
using Exercise.Application.Mappers;
using Exercise.Domain.Models;
using Exercise.Domain.Repositories;

namespace Exercise.Application.Services;

public class WorkoutTemplateService : IWorkoutTemplateService
{
    private readonly IWorkoutTemplateRepository _templateRepository;
    private readonly IExerciseCatalogRepository _catalogRepository;

    public WorkoutTemplateService(
        IWorkoutTemplateRepository templateRepository,
        IExerciseCatalogRepository catalogRepository)
    {
        _templateRepository = templateRepository;
        _catalogRepository = catalogRepository;
    }

    public async Task<(IReadOnlyList<WorkoutTemplateDto> Items, PaginationMetadata Pagination)> GetAllAsync(
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var pageNum = Math.Max(1, pageNumber);
        var pageSz = Math.Clamp(pageSize, 1, 100);

        var (entities, totalRecords) = await _templateRepository.GetPagedAsync(pageNum, pageSz, cancellationToken);
        var dtos = entities.Select(e => e.ToDto()).ToList();
        var pagination = new PaginationMetadata(pageNum, pageSz, totalRecords);

        return (dtos, pagination);
    }

    public async Task<(IReadOnlyList<WorkoutTemplateDto> Items, PaginationMetadata Pagination)> GetSystemTemplatesAsync(
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var pageNum = Math.Max(1, pageNumber);
        var pageSz = Math.Clamp(pageSize, 1, 100);

        var (entities, totalRecords) = await _templateRepository.GetSystemTemplatesPagedAsync(pageNum, pageSz, cancellationToken);
        var dtos = entities.Select(e => e.ToDto()).ToList();
        var pagination = new PaginationMetadata(pageNum, pageSz, totalRecords);

        return (dtos, pagination);
    }

    public async Task<WorkoutTemplateDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _templateRepository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(WorkoutTemplate), id);
        return entity.ToDto();
    }

    public async Task<WorkoutTemplateDto> CreateAsync(CreateWorkoutTemplateDto dto, CancellationToken cancellationToken = default)
    {
        var entity = new WorkoutTemplate();
        entity.UpdateEntity(dto);

        await AggregateAndValidateAsync(entity, cancellationToken);

        await _templateRepository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task UpdateAsync(Guid id, UpdateWorkoutTemplateDto dto, CancellationToken cancellationToken = default)
    {
        var entity = await _templateRepository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
            throw new NotFoundException(nameof(WorkoutTemplate), id);

        entity.UpdateEntity(dto);

        await AggregateAndValidateAsync(entity, cancellationToken);
        
        await _templateRepository.UpdateAsync(id, entity, cancellationToken);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var exists = await _templateRepository.ExistsAsync(id, cancellationToken);
        if (!exists)
            throw new NotFoundException(nameof(WorkoutTemplate), id);

        await _templateRepository.DeleteAsync(id, cancellationToken);
    }

    private async Task AggregateAndValidateAsync(WorkoutTemplate entity, CancellationToken cancellationToken)
    {
        var targetMuscleGroups = new HashSet<string>();
        var requiredEquipment = new HashSet<string>();

        foreach (var session in entity.Sessions)
        {
            var exercise = await _catalogRepository.GetByIdAsync(session.ExerciseId, cancellationToken);
            if (exercise == null)
            {
                throw new NotFoundException(nameof(ExerciseCatalog), session.ExerciseId);
            }

            foreach (var muscle in exercise.PrimaryMuscles)
                targetMuscleGroups.Add(muscle);
            foreach (var muscle in exercise.SecondaryMuscles)
                targetMuscleGroups.Add(muscle);
            foreach (var eq in exercise.EquipmentRequired)
                requiredEquipment.Add(eq);
        }

        entity.TargetMuscleGroups = targetMuscleGroups.ToList();
        entity.RequiredEquipment = requiredEquipment.ToList();
    }
}
