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
}
