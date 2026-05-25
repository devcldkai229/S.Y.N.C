using Roadmap.Application.Common;
using Roadmap.Application.DTOs;
using Roadmap.Application.Exceptions;
using Roadmap.Application.Mappers;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;


namespace Roadmap.Application.Services;

public class UserCustomWorkoutService : IUserCustomWorkoutService
{
    private readonly IUserCustomWorkoutRepository _repository;

    public UserCustomWorkoutService(IUserCustomWorkoutRepository repository)
    {
        _repository = repository;
    }

    public async Task<UserCustomWorkoutDto> CreateAsync(
        CreateUserCustomWorkoutDto dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.UserId == Guid.Empty)
            throw new BadRequestException("UserId is required.");

        if (string.IsNullOrWhiteSpace(dto.WorkoutName))
            throw new BadRequestException("WorkoutName is required.");

        if (dto.CustomBlocks.Count == 0)
            throw new BadRequestException("At least one exercise block is required.");

        var entity = new UserCustomWorkout();
        entity.UpdateEntity(dto);

        await _repository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<IReadOnlyList<UserCustomWorkoutDto>> GetByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        if (userId == Guid.Empty)
            throw new BadRequestException("UserId is required.");

        var entities = await _repository.GetByUserIdAsync(userId, cancellationToken);
        return entities.Select(e => e.ToDto()).ToList();
    }

    public async Task<UserCustomWorkoutDto> GetByIdAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(UserCustomWorkout), id);

        return entity.ToDto();
    }

    public async Task<(IReadOnlyList<UserCustomWorkoutDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
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

    public async Task<UserCustomWorkoutDto> UpdateAsync(Guid id, UpdateUserCustomWorkoutDto dto, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.WorkoutName))
            throw new BadRequestException("WorkoutName is required.");

        if (dto.CustomBlocks.Count == 0)
            throw new BadRequestException("At least one exercise block is required.");

        var entity = await _repository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(UserCustomWorkout), id);

        entity.UpdateEntity(dto);
        await _repository.UpdateAsync(id, entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        if (!await _repository.ExistsAsync(id, cancellationToken))
            throw new NotFoundException(nameof(UserCustomWorkout), id);

        await _repository.DeleteAsync(id, cancellationToken);
    }
}

