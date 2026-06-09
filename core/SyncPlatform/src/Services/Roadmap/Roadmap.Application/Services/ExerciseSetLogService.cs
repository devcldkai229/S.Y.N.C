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
    private readonly IWorkoutExecutionLogRepository _executionLogRepository;

    public ExerciseSetLogService(
        IExerciseSetLogRepository repository,
        IWorkoutExecutionLogRepository executionLogRepository)
    {
        _repository = repository;
        _executionLogRepository = executionLogRepository;
    }

    public async Task<ExerciseSetLogDto> CreateAsync(Guid userId, CreateExerciseSetLogDto dto, CancellationToken cancellationToken = default)
    {
        if (dto.ExecutionId == Guid.Empty)
            throw new BadRequestException("ExecutionId is required.");

        if (dto.ExerciseId == Guid.Empty)
            throw new BadRequestException("ExerciseId is required.");

        // Validate Ownership of the Workout Execution
        var execution = await _executionLogRepository.GetByIdAsync(dto.ExecutionId, cancellationToken)
            ?? throw new NotFoundException(nameof(WorkoutExecutionLog), dto.ExecutionId);

        if (execution.UserId != userId)
            throw new ForbiddenException("You do not own this workout execution.");

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

    public async Task<ExerciseSetLogDto> UpdateAsync(
        Guid userId,
        Guid setLogId,
        UpdateExerciseSetLogDto request,
        CancellationToken cancellationToken = default)
    {
        // 1. Fetch Set Log
        var setLog = await _repository.GetByIdAsync(setLogId, cancellationToken)
            ?? throw new NotFoundException(nameof(ExerciseSetLog), setLogId);

        // 2. Validate Ownership of the Workout Execution
        var execution = await _executionLogRepository.GetByIdAsync(setLog.ExecutionId, cancellationToken)
            ?? throw new NotFoundException(nameof(WorkoutExecutionLog), setLog.ExecutionId);

        if (execution.UserId != userId)
            throw new ForbiddenException("You do not own this workout execution.");

        // 3. Update Set Log properties
        setLog.ActualReps = request.ActualReps;
        setLog.WeightKg = (decimal)request.WeightKg;
        setLog.Rir = request.Rir;
        setLog.RestTakenSeconds = request.RestTakenSeconds;
        setLog.FormScore = request.FormScore;
        setLog.Completed = request.Completed;

        await _repository.UpdateAsync(setLogId, setLog, cancellationToken);

        return setLog.ToDto();
    }
}
