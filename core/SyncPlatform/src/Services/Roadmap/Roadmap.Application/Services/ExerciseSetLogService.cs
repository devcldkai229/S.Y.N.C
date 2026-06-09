using Roadmap.Application.Common;
using Roadmap.Application.DTOs;
using Roadmap.Application.Exceptions;
using Roadmap.Application.Mappers;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Application.Services;

public class ExerciseSetLogService : IExerciseSetLogService
{
    private readonly IExerciseSetLogRepository _repository;

    public ExerciseSetLogService(IExerciseSetLogRepository repository)
    {
        _repository = repository;
    }

    public async Task<ExerciseSetLogDto> CreateAsync(CreateExerciseSetLogDto dto, CancellationToken cancellationToken = default)
    {
        if (dto.ExecutionId == Guid.Empty)
            throw new BadRequestException("ExecutionId is required.");

        if (dto.ExerciseId == Guid.Empty)
            throw new BadRequestException("ExerciseId is required.");

        var entity = dto.ToEntity();
        await _repository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<ExerciseSetLogDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(ExerciseSetLog), id);

        return entity.ToDto();
    }

    public async Task<(IReadOnlyList<ExerciseSetLogDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Guid? executionId = null,
        CancellationToken cancellationToken = default)
    {
        var (entities, totalCount) = await _repository.GetPagedAsync(
            pageNumber,
            pageSize,
            executionId.HasValue ? x => x.ExecutionId == executionId.Value : null,
            cancellationToken);

        var dtos = entities.Select(e => e.ToDto()).ToList();
        var metadata = new PaginationMetadata(pageNumber, pageSize, totalCount);
        return (dtos, metadata);
    }
}
