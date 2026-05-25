using Roadmap.Application.Common;
using Roadmap.Application.DTOs;
using Roadmap.Application.Exceptions;
using Roadmap.Application.Mappers;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Application.Services;

public class ScheduledWorkoutService : IScheduledWorkoutService
{
    private readonly IScheduledWorkoutRepository _repository;

    public ScheduledWorkoutService(IScheduledWorkoutRepository repository)
    {
        _repository = repository;
    }

    public async Task<ScheduledWorkoutDto> CreateAsync(CreateScheduledWorkoutDto dto, CancellationToken cancellationToken = default)
    {
        if (dto.UserId == Guid.Empty)
            throw new BadRequestException("UserId is required.");

        if (dto.SessionId == Guid.Empty)
            throw new BadRequestException("SessionId is required.");

        var entity = dto.ToEntity();
        await _repository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<ScheduledWorkoutDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(ScheduledWorkout), id);

        return entity.ToDto();
    }

    public async Task<(IReadOnlyList<ScheduledWorkoutDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Guid? userId = null,
        CancellationToken cancellationToken = default)
    {
        var (entities, totalCount) = await _repository.GetPagedAsync(
            pageNumber,
            pageSize,
            userId.HasValue ? x => x.UserId == userId.Value : null,
            cancellationToken);

        var dtos = entities.Select(e => e.ToDto()).ToList();
        var metadata = new PaginationMetadata(pageNumber, pageSize, totalCount);
        return (dtos, metadata);
    }

    public async Task<ScheduledWorkoutDto> UpdateAsync(Guid id, UpdateScheduledWorkoutDto dto, CancellationToken cancellationToken = default)
    {
        if (dto.UserId == Guid.Empty)
            throw new BadRequestException("UserId is required.");

        if (dto.SessionId == Guid.Empty)
            throw new BadRequestException("SessionId is required.");

        var entity = await _repository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(ScheduledWorkout), id);

        entity.UpdateEntity(dto);
        await _repository.UpdateAsync(id, entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        if (!await _repository.ExistsAsync(id, cancellationToken))
            throw new NotFoundException(nameof(ScheduledWorkout), id);

        await _repository.DeleteAsync(id, cancellationToken);
    }
}
