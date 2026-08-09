using Libs.Shared.Time;
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
    private readonly IExerciseSetLogRepository _setLogRepository;

    public InternalRoadmapWorkoutController(
        IWorkoutExecutionLogService executionLogService,
        IExerciseSetLogService setLogService,
        IRecoveryProfileService recoveryService,
        IRoadmapSessionService sessionService,
        IWorkoutExecutionLogRepository executionLogRepository,
        IExerciseSetLogRepository setLogRepository)
    {
        _executionLogService = executionLogService;
        _setLogService = setLogService;
        _recoveryService = recoveryService;
        _sessionService = sessionService;
        _executionLogRepository = executionLogRepository;
        _setLogRepository = setLogRepository;
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
        [FromQuery] string? timeZoneId,
        CancellationToken cancellationToken)
    {
        DateTimeOffset start;
        DateTimeOffset end;
        if (from is null || to is null)
        {
            var (localStart, localEnd) = UserLocalTime.LastDaysRange(timeZoneId, 7);
            end = to ?? localEnd;
            start = from ?? localStart;
        }
        else
        {
            start = from.Value;
            end = to.Value;
        }

        var logs = await _executionLogRepository.GetByUserIdAndDateRangeAsync(userId, start, end, cancellationToken);
        var setLogs = await _setLogRepository.GetByExecutionIdsAsync(logs.Select(l => l.Id), cancellationToken);
        var setsByExecution = setLogs
            .GroupBy(s => s.ExecutionId)
            .ToDictionary(g => g.Key, g => g.Select(x => x.ToDto()).ToList());

        // Set logs chỉ lưu ExerciseId — AI/report cần tên bài. Map tên từ
        // ExecutionBlocks của các session liên quan.
        var nameByExercise = new Dictionary<Guid, string>();
        foreach (var sessionId in logs.Select(l => l.SessionId).Where(id => id != Guid.Empty).Distinct())
        {
            try
            {
                var session = await _sessionService.GetByIdAsync(sessionId, cancellationToken);
                foreach (var block in session.ExecutionBlocks)
                {
                    if (block.ExerciseId != Guid.Empty && !string.IsNullOrWhiteSpace(block.ExerciseName))
                        nameByExercise[block.ExerciseId] = block.ExerciseName;
                }
            }
            catch
            {
                // Session đã bị xoá — set logs của nó đành thiếu tên.
            }
        }

        var dtos = logs.Select(l =>
        {
            var dto = l.ToLogDto();
            if (setsByExecution.TryGetValue(l.Id, out var sets))
            {
                foreach (var set in sets)
                {
                    if (nameByExercise.TryGetValue(set.ExerciseId, out var name))
                        set.ExerciseName = name;
                }
                dto.Sets = sets;
            }
            return dto;
        }).ToList();
        return Ok(ApiResponse<IReadOnlyList<WorkoutExecutionLogDto>>.SuccessResponse(
            dtos, "Workout executions retrieved."));
    }

    [HttpGet("{userId:guid}/timeseries")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<WorkoutTimeseriesBucketDto>>>> GetWorkoutTimeseries(
        Guid userId,
        [FromQuery] DateTimeOffset? from,
        [FromQuery] DateTimeOffset? to,
        [FromQuery] string? granularity,
        [FromQuery] string? timeZoneId,
        CancellationToken cancellationToken)
    {
        DateTimeOffset start;
        DateTimeOffset end;
        if (from is null || to is null)
        {
            var (localStart, localEnd) = UserLocalTime.LastDaysRange(timeZoneId, 28);
            end = to ?? localEnd;
            start = from ?? localStart;
        }
        else
        {
            start = from.Value;
            end = to.Value;
        }

        if (end < start)
            (start, end) = (end, start);

        var logs = await _executionLogRepository.GetByUserIdAndDateRangeAsync(userId, start, end, cancellationToken);
        var setLogs = await _setLogRepository.GetByExecutionIdsAsync(logs.Select(l => l.Id), cancellationToken);
        var volumeByExecution = setLogs
            .GroupBy(s => s.ExecutionId)
            .ToDictionary(
                g => g.Key,
                g => g.Sum(s => (double)s.ActualReps * (double)s.WeightKg));

        IReadOnlyList<Roadmap.Application.DTOs.RoadmapSessionDto> planned = [];

        var gran = (granularity ?? "week").Trim().ToLowerInvariant();
        if (gran is not ("day" or "week" or "month"))
            gran = "week";

        string KeyOf(DateTimeOffset ts)
        {
            var local = ts.UtcDateTime.Date;
            return gran switch
            {
                "month" => $"{local.Year:D4}-{local.Month:D2}",
                "week" => $"{System.Globalization.ISOWeek.GetYear(local)}-W{System.Globalization.ISOWeek.GetWeekOfYear(local):D2}",
                _ => local.ToString("yyyy-MM-dd"),
            };
        }

        var buckets = new Dictionary<string, WorkoutTimeseriesBucketDto>(StringComparer.Ordinal);

        WorkoutTimeseriesBucketDto Ensure(string key)
        {
            if (!buckets.TryGetValue(key, out var b))
            {
                b = new WorkoutTimeseriesBucketDto { Key = key };
                buckets[key] = b;
            }
            return b;
        }

        // Planned sessions omitted here (requires active-roadmap lookup in AI controller).
        // Completion uses executed logs; AI may cross-check via get_sessions_by_range.
        _ = planned;

        foreach (var log in logs)
        {
            var key = KeyOf(log.StartedAt);
            var b = Ensure(key);
            b.SessionsCompleted += 1;
            b.CaloriesBurned += log.CaloriesBurned;
            b.CompletionRateSum += log.CompletionRate;
            if (volumeByExecution.TryGetValue(log.Id, out var vol))
                b.Volume += vol;
        }

        foreach (var b in buckets.Values)
        {
            if (b.SessionsCompleted > 0)
                b.CompletionRate = Math.Round(b.CompletionRateSum / b.SessionsCompleted, 1);
            else if (b.SessionsPlanned > 0)
                b.CompletionRate = 0;
        }

        var ordered = buckets.Values.OrderBy(x => x.Key).ToList();
        return Ok(ApiResponse<IReadOnlyList<WorkoutTimeseriesBucketDto>>.SuccessResponse(
            ordered, "Workout timeseries retrieved."));
    }

    [HttpGet("{userId:guid}/strength-progression")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<StrengthProgressPointDto>>>> GetStrengthProgression(
        Guid userId,
        [FromQuery] Guid exerciseId,
        [FromQuery] DateTimeOffset? from,
        [FromQuery] DateTimeOffset? to,
        [FromQuery] string? timeZoneId,
        CancellationToken cancellationToken)
    {
        if (exerciseId == Guid.Empty)
            return BadRequest(ApiResponse<object>.FailureResponse("exerciseId is required."));

        DateTimeOffset start;
        DateTimeOffset end;
        if (from is null || to is null)
        {
            var (localStart, localEnd) = UserLocalTime.LastDaysRange(timeZoneId, 90);
            end = to ?? localEnd;
            start = from ?? localStart;
        }
        else
        {
            start = from.Value;
            end = to.Value;
        }

        var logs = await _executionLogRepository.GetByUserIdAndDateRangeAsync(userId, start, end, cancellationToken);
        var logById = logs.ToDictionary(l => l.Id);
        var setLogs = await _setLogRepository.GetByExecutionIdsAsync(logs.Select(l => l.Id), cancellationToken);
        var points = setLogs
            .Where(s => s.ExerciseId == exerciseId && s.WeightKg > 0)
            .Select(s =>
            {
                logById.TryGetValue(s.ExecutionId, out var log);
                var day = (log?.StartedAt ?? s.CreatedAt).UtcDateTime.Date;
                return new { Day = day, s.WeightKg };
            })
            .GroupBy(x => x.Day)
            .OrderBy(g => g.Key)
            .Select(g => new StrengthProgressPointDto
            {
                Date = DateOnly.FromDateTime(g.Key),
                WeightKg = g.Max(x => x.WeightKg),
            })
            .ToList();

        return Ok(ApiResponse<IReadOnlyList<StrengthProgressPointDto>>.SuccessResponse(
            points, "Strength progression retrieved."));
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

public class WorkoutTimeseriesBucketDto
{
    public string Key { get; set; } = string.Empty;
    public int SessionsCompleted { get; set; }
    public int SessionsPlanned { get; set; }
    public double CompletionRate { get; set; }
    public double CompletionRateSum { get; set; }
    public double Volume { get; set; }
    public int CaloriesBurned { get; set; }
}

public class StrengthProgressPointDto
{
    public DateOnly Date { get; set; }
    public decimal WeightKg { get; set; }
}
