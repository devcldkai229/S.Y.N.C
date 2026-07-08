using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Roadmap.Application.Common;
using Roadmap.Application.DTOs;
using Roadmap.Application.Mappers;
using Roadmap.Application.Services;
using Roadmap.Domain.Repositories;

namespace Roadmap.API.Controllers;

[ApiController]
[Route("api/internal/roadmap")]
[AllowAnonymous]
public class InternalRoadmapWorkoutController : ControllerBase
{
    private readonly IWorkoutExecutionLogService _executionLogService;
    private readonly IExerciseSetLogService _setLogService;
    private readonly IRecoveryProfileService _recoveryService;
    private readonly IRoadmapSessionService _sessionService;
    private readonly IWorkoutExecutionLogRepository _executionLogRepository;

    public InternalRoadmapWorkoutController(
        IWorkoutExecutionLogService executionLogService,
        IExerciseSetLogService setLogService,
        IRecoveryProfileService recoveryService,
        IRoadmapSessionService sessionService,
        IWorkoutExecutionLogRepository executionLogRepository)
    {
        _executionLogService = executionLogService;
        _setLogService = setLogService;
        _recoveryService = recoveryService;
        _sessionService = sessionService;
        _executionLogRepository = executionLogRepository;
    }

    [HttpPost("workout-executions")]
    public async Task<ActionResult<ApiResponse<WorkoutExecutionLogDto>>> LogExecution(
        [FromBody] InternalWorkoutExecutionRequestDto request,
        CancellationToken cancellationToken)
    {
        var dto = new CreateWorkoutExecutionLogDto
        {
            UserId = request.UserId,
            SessionId = request.SessionId,
            StartedAt = DateTimeOffset.UtcNow.AddMinutes(-request.DurationMinutes),
            CompletedAt = DateTimeOffset.UtcNow,
            ActualDurationMinutes = request.DurationMinutes,
            PerceivedDifficulty = ParseDifficulty(request.PerceivedDifficulty),
            EnergyLevelBefore = request.EnergyLevelBefore,
            EnergyLevelAfter = request.EnergyLevelAfter,
            CompletionRate = 100,
        };
        var result = await _executionLogService.CreateAsync(dto, cancellationToken);
        return Ok(ApiResponse<WorkoutExecutionLogDto>.SuccessResponse(result, "Workout execution logged."));
    }

    [HttpGet("workout-executions/{userId:guid}")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<WorkoutExecutionLogDto>>>> GetExecutionsInRange(
        Guid userId,
        [FromQuery] DateTimeOffset? from,
        [FromQuery] DateTimeOffset? to,
        CancellationToken cancellationToken)
    {
        var end = to ?? DateTimeOffset.UtcNow;
        var start = from ?? end.AddDays(-7);
        var logs = await _executionLogRepository.GetByUserIdAndDateRangeAsync(userId, start, end, cancellationToken);
        var dtos = logs.Select(l => l.ToLogDto()).ToList();
        return Ok(ApiResponse<IReadOnlyList<WorkoutExecutionLogDto>>.SuccessResponse(
            dtos, "Workout executions retrieved."));
    }

    [HttpPost("exercise-set-logs")]
    public async Task<ActionResult<ApiResponse<ExerciseSetLogDto>>> LogSet(
        [FromBody] InternalExerciseSetLogRequestDto request,
        CancellationToken cancellationToken)
    {
        var dto = new CreateExerciseSetLogDto
        {
            ExecutionId = request.WorkoutExecutionId,
            ExerciseId = request.ExerciseId,
            SetNumber = request.SetNumber,
            ActualReps = request.ActualReps,
            WeightKg = request.WeightKg,
            Rir = request.Rir ?? 2,
            Completed = true,
        };
        var result = await _setLogService.CreateAsync(request.UserId, dto, cancellationToken);
        return Ok(ApiResponse<ExerciseSetLogDto>.SuccessResponse(result, "Set logged."));
    }

    [HttpGet("recovery/{userId:guid}")]
    public async Task<ActionResult<ApiResponse<RecoveryProfileDto?>>> GetRecovery(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var (items, _) = await _recoveryService.GetPagedAsync(1, 1, userId, cancellationToken);
        var latest = items.FirstOrDefault();
        return Ok(ApiResponse<RecoveryProfileDto?>.SuccessResponse(latest, "Recovery status retrieved."));
    }

    [HttpPost("sessions/{sessionId:guid}/substitute")]
    public async Task<ActionResult<ApiResponse<RoadmapSessionDto>>> SubstituteExercise(
        Guid sessionId,
        [FromBody] InternalSubstituteExerciseRequestDto request,
        CancellationToken cancellationToken)
    {
        var session = await _sessionService.SubstituteExerciseAsync(
            sessionId,
            request.UserId,
            request.ExerciseId,
            request.ReplaceExerciseId,
            request.ExerciseName,
            request.Reason,
            cancellationToken);

        return Ok(ApiResponse<RoadmapSessionDto>.SuccessResponse(session, "Substitute applied."));
    }

    private static int ParseDifficulty(string? value) => value?.ToLowerInvariant() switch
    {
        "easy" => 2,
        "hard" => 8,
        _ => 5,
    };
}

public class InternalWorkoutExecutionRequestDto
{
    public Guid UserId { get; set; }
    public Guid SessionId { get; set; }
    public int DurationMinutes { get; set; }
    public string? PerceivedDifficulty { get; set; }
    public int EnergyLevelBefore { get; set; }
    public int EnergyLevelAfter { get; set; }
}

public class InternalExerciseSetLogRequestDto
{
    public Guid UserId { get; set; }
    public Guid WorkoutExecutionId { get; set; }
    public Guid ExerciseId { get; set; }
    public int SetNumber { get; set; }
    public int ActualReps { get; set; }
    public decimal WeightKg { get; set; }
    public int? Rir { get; set; }
}
