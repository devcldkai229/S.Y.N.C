using Libs.Shared.Enums;
using Libs.Shared.Time;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Roadmap.Application.Common;
using Roadmap.Application.DTOs;
using Roadmap.Application.Services;

namespace Roadmap.API.Controllers;

/// <summary>AI-triggered roadmap read/write (PersonalizedRoadmap + schedule + mutations).</summary>
[ApiController]
[Route("api/internal/roadmap")]
[AllowAnonymous]
public class InternalRoadmapAiController : ControllerBase
{
    private readonly IPersonalizedRoadmapService _roadmapService;
    private readonly IRoadmapSessionService _sessionService;

    public InternalRoadmapAiController(
        IPersonalizedRoadmapService roadmapService,
        IRoadmapSessionService sessionService)
    {
        _roadmapService = roadmapService;
        _sessionService = sessionService;
    }

    // ── DELETE roadmap (cascade sessions/schedules) ──────────────────────────

    [HttpDelete("{roadmapId:guid}")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteRoadmap(
        Guid roadmapId,
        CancellationToken cancellationToken)
    {
        await _roadmapService.DeleteAsync(roadmapId, cancellationToken);
        return Ok(ApiResponse<object>.SuccessResponse(new { roadmapId }, "Roadmap deleted."));
    }

    // ── Sessions by date window ──────────────────────────────────────────────

    [HttpGet("users/{userId:guid}/sessions")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<RoadmapSessionDto>>>> GetSessionsByDateRange(
        Guid userId,
        [FromQuery] DateTimeOffset? from,
        [FromQuery] DateTimeOffset? to,
        [FromQuery] string? timeZoneId,
        CancellationToken cancellationToken)
    {
        var active = await _roadmapService.GetActiveByUserIdAsync(userId, cancellationToken);
        if (active is null)
            return Ok(ApiResponse<IReadOnlyList<RoadmapSessionDto>>.SuccessResponse(
                [], "No active roadmap found."));

        DateTimeOffset start;
        DateTimeOffset end;
        if (from is null || to is null)
        {
            var (localStart, localEnd) = UserLocalTime.TodayRange(timeZoneId);
            start = from ?? localStart;
            end = to ?? localEnd;
        }
        else
        {
            start = from.Value;
            end = to.Value;
        }

        var result = await _sessionService.GetByRoadmapIdAndDateRangeAsync(active.Id, start, end, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<RoadmapSessionDto>>.SuccessResponse(result, "Sessions retrieved."));
    }

    // ── Batch week schedule ──────────────────────────────────────────────────

    [HttpPost("sessions/schedule-week")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<ScheduledSessionResultDto>>>> ScheduleWeek(
        [FromBody] InternalScheduleWeekRequestDto request,
        CancellationToken cancellationToken)
    {
        if (request.Sessions is null || request.Sessions.Count == 0)
            return BadRequest(ApiResponse<object>.FailureResponse("At least one session is required."));

        // Validate AllowAiReschedule for the roadmap if provided
        var roadmapId = request.Sessions.FirstOrDefault()?.RoadmapId;
        if (roadmapId.HasValue)
        {
            var roadmap = await _roadmapService.GetByIdAsync(roadmapId.Value, cancellationToken);
            if (!roadmap.AllowAiReschedule)
                return BadRequest(ApiResponse<object>.FailureResponse("AI reschedule is disabled for this roadmap."));
        }

        var results = await _sessionService.ScheduleWeekAsync(request.Sessions, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<ScheduledSessionResultDto>>.SuccessResponse(results, "Week scheduled."));
    }

    // ── Reschedule single session ────────────────────────────────────────────

    /// <summary>AI flow — đọc 1 session để validate luật đổi lịch (ngày/giờ hiện tại).</summary>
    [HttpGet("sessions/{sessionId:guid}")]
    public async Task<ActionResult<ApiResponse<RoadmapSessionDto>>> GetSession(
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        var result = await _sessionService.GetByIdAsync(sessionId, cancellationToken);
        return Ok(ApiResponse<RoadmapSessionDto>.SuccessResponse(result, "Session retrieved."));
    }

    [HttpPost("sessions/{sessionId:guid}/reschedule")]
    public async Task<ActionResult<ApiResponse<RoadmapSessionDto>>> RescheduleSession(
        Guid sessionId,
        [FromBody] RoadmapRescheduleSessionRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _sessionService.RescheduleSessionAsync(
            sessionId, request.UserId, request.NewDate, request.NewTime, cancellationToken);
        return Ok(ApiResponse<RoadmapSessionDto>.SuccessResponse(result, "Session rescheduled."));
    }

    [HttpPut("sessions/{sessionId:guid}")]
    public async Task<ActionResult<ApiResponse<RoadmapSessionDto>>> UpdateSession(
        Guid sessionId,
        [FromBody] UpdateRoadmapSessionDto request,
        CancellationToken cancellationToken)
    {
        // Gate AI edits against the parent roadmap when known.
        if (request.RoadmapId != Guid.Empty)
        {
            var roadmap = await _roadmapService.GetByIdAsync(request.RoadmapId, cancellationToken);
            if (!roadmap.AllowAiReschedule && !roadmap.AllowAiIntensityAdjustment)
            {
                return BadRequest(ApiResponse<object>.FailureResponse(
                    "AI session edits are disabled for this roadmap."));
            }
        }

        var result = await _sessionService.UpdateAsync(sessionId, request, cancellationToken);
        return Ok(ApiResponse<RoadmapSessionDto>.SuccessResponse(result, "Session updated."));
    }

    [HttpDelete("sessions/{sessionId:guid}")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteSession(
        Guid sessionId,
        CancellationToken cancellationToken)
    {
        await _sessionService.DeleteAsync(sessionId, cancellationToken);
        return Ok(ApiResponse<object>.SuccessResponse(new { sessionId }, "Session deleted."));
    }

    [HttpGet("users/{userId:guid}/active")]
    public async Task<ActionResult<ApiResponse<PersonalizedRoadmapDto?>>> GetActiveRoadmap(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _roadmapService.GetActiveByUserIdAsync(userId, cancellationToken);
        return Ok(ApiResponse<PersonalizedRoadmapDto?>.SuccessResponse(result, "Active roadmap retrieved."));
    }

    [HttpGet("{roadmapId:guid}")]
    public async Task<ActionResult<ApiResponse<PersonalizedRoadmapDto>>> GetRoadmap(
        Guid roadmapId,
        CancellationToken cancellationToken)
    {
        var result = await _roadmapService.GetByIdAsync(roadmapId, cancellationToken);
        return Ok(ApiResponse<PersonalizedRoadmapDto>.SuccessResponse(result, "Roadmap retrieved."));
    }



    [HttpPost]
    public async Task<ActionResult<ApiResponse<PersonalizedRoadmapDto>>> CreateRoadmap(
        [FromBody] InternalCreatePersonalizedRoadmapRequestDto request,
        CancellationToken cancellationToken)
    {
        var dto = new CreatePersonalizedRoadmapDto
        {
            UserId = request.UserId,
            RoadmapName = request.RoadmapName,
            FitnessGoal = request.FitnessGoal,
            CurrentPhase = request.CurrentPhase,
            StartDate = request.StartDate,
            ExpectedEndDate = request.ExpectedEndDate,
            CurrentWeightKg = request.CurrentWeightKg,
            TargetWeightKg = request.TargetWeightKg,
            InitialFatPercentage = request.InitialFatPercentage,
            TargetFatPercentage = request.TargetFatPercentage,
            AdaptiveAiEnabled = request.AdaptiveAiEnabled,
            AllowAiReschedule = request.AllowAiReschedule,
            AllowAiIntensityAdjustment = request.AllowAiIntensityAdjustment,
            AllowAiRecoveryDeload = request.AllowAiRecoveryDeload,
            RoadmapStatus = request.RoadmapStatus,
        };
        var result = await _roadmapService.CreateAsync(dto, cancellationToken);
        return Ok(ApiResponse<PersonalizedRoadmapDto>.SuccessResponse(result, "Roadmap created."));
    }

    [HttpPatch("{roadmapId:guid}")]
    public async Task<ActionResult<ApiResponse<PersonalizedRoadmapDto>>> PatchRoadmap(
        Guid roadmapId,
        [FromBody] InternalPatchPersonalizedRoadmapDto request,
        CancellationToken cancellationToken)
    {
        var result = await _roadmapService.PatchForAiAsync(roadmapId, request, cancellationToken);
        return Ok(ApiResponse<PersonalizedRoadmapDto>.SuccessResponse(result, "Roadmap updated."));
    }

    [HttpGet("{roadmapId:guid}/sessions")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<RoadmapSessionDto>>>> GetRoadmapSessions(
        Guid roadmapId,
        CancellationToken cancellationToken)
    {
        var result = await _sessionService.GetByRoadmapIdAsync(roadmapId, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<RoadmapSessionDto>>.SuccessResponse(
            result, "Roadmap sessions retrieved."));
    }

    [HttpPost("sessions/schedule")]
    public async Task<ActionResult<ApiResponse<ScheduledSessionResultDto>>> ScheduleSession(
        [FromBody] InternalScheduleSessionRequestDto request,
        CancellationToken cancellationToken)
    {
        if (request.RoadmapId.HasValue)
        {
            var roadmap = await _roadmapService.GetByIdAsync(request.RoadmapId.Value, cancellationToken);
            if (!roadmap.AllowAiReschedule)
            {
                return BadRequest(ApiResponse<object>.FailureResponse(
                    "AI reschedule is disabled for this roadmap."));
            }
        }

        var result = await _sessionService.ScheduleAsync(request, cancellationToken);
        return Ok(ApiResponse<ScheduledSessionResultDto>.SuccessResponse(result, "Session scheduled."));
    }

    [HttpPost("replan")]
    public async Task<ActionResult<ApiResponse<RoadmapReplanTicketDto>>> RequestReplan(
        [FromBody] RoadmapReplanRequestDto request,
        CancellationToken cancellationToken)
    {
        var active = await _roadmapService.GetActiveByUserIdAsync(request.UserId, cancellationToken);
        if (active is null)
        {
            return NotFound(ApiResponse<RoadmapReplanTicketDto>.FailureResponse(
                $"No active roadmap for user {request.UserId}."));
        }

        if (!active.AllowAiReschedule)
        {
            return BadRequest(ApiResponse<RoadmapReplanTicketDto>.FailureResponse(
                "AI reschedule is disabled for this roadmap."));
        }

        var ticket = new RoadmapReplanTicketDto
        {
            TicketId = Guid.NewGuid(),
            UserId = request.UserId,
            RoadmapId = active.Id,
            Status = "queued",
            Message = string.IsNullOrWhiteSpace(request.Reason)
                ? "Replan request accepted. Sessions will be rescheduled in the next sync."
                : $"Replan accepted: {request.Reason}",
        };
        return Ok(ApiResponse<RoadmapReplanTicketDto>.SuccessResponse(ticket, "Replan queued."));
    }

    [HttpPost("sessions/{sessionId:guid}/adjust-intensity")]
    public async Task<ActionResult<ApiResponse<RoadmapIntensityAdjustmentDto>>> AdjustIntensity(
        Guid sessionId,
        [FromBody] RoadmapAdjustIntensityRequestDto request,
        CancellationToken cancellationToken)
    {
        var session = await _sessionService.AdjustIntensityAsync(
            sessionId, request.UserId, request.Factor, cancellationToken);

        var result = new RoadmapIntensityAdjustmentDto
        {
            SessionId = sessionId,
            UserId = request.UserId,
            Factor = request.Factor,
            Status = "applied",
            Message = "Intensity adjustment applied to session execution blocks.",
            Session = session,
        };
        return Ok(ApiResponse<RoadmapIntensityAdjustmentDto>.SuccessResponse(
            result,
            "Intensity adjustment applied."));
    }
}

public class RoadmapRescheduleSessionRequestDto
{
    public Guid UserId { get; set; }

    public DateTimeOffset NewDate { get; set; }

    public string NewTime { get; set; } = "07:00";
}

public class InternalScheduleWeekRequestDto
{
    public List<ScheduleSessionDto> Sessions { get; set; } = [];
}

public class RoadmapReplanRequestDto
{
    public Guid UserId { get; set; }

    public string Reason { get; set; } = string.Empty;
}

public class RoadmapReplanTicketDto
{
    public Guid TicketId { get; set; }

    public Guid UserId { get; set; }

    public Guid RoadmapId { get; set; }

    public string Status { get; set; } = "queued";

    public string Message { get; set; } = string.Empty;
}

public class RoadmapAdjustIntensityRequestDto
{
    public Guid UserId { get; set; }

    public double Factor { get; set; } = 1.0;
}

public class RoadmapIntensityAdjustmentDto
{
    public Guid SessionId { get; set; }

    public Guid UserId { get; set; }

    public double Factor { get; set; }

    public string Status { get; set; } = "accepted";

    public string Message { get; set; } = string.Empty;

    public RoadmapSessionDto? Session { get; set; }
}
