using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Route("api/v1/challenges")]
public class ChallengeController : ControllerBase
{
    private readonly ICommunityChallengeService _challenges;
    private readonly IChallengeParticipationService _participation;
    private readonly ICurrentUserContext _currentUser;

    public ChallengeController(
        ICommunityChallengeService challenges,
        IChallengeParticipationService participation,
        ICurrentUserContext currentUser)
    {
        _challenges = challenges;
        _participation = participation;
        _currentUser = currentUser;
    }

    /// <summary>Paginated list of active challenges.</summary>
    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<CommunityChallengeDto>>>> GetActive(
        [FromQuery] ChallengePublicListQuery query,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _challenges.GetActivePagedAsync(query, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<CommunityChallengeDto>>.SuccessPagedResponse(
            items,
            pagination,
            "Active challenges retrieved successfully."));
    }

    /// <summary>Active challenges near a location, sorted by distance ascending.</summary>
    [HttpGet("nearby")]
    [AllowAnonymous]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<NearbyCommunityChallengeDto>>>> GetNearby(
        [FromQuery] NearbyChallengeQuery query,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _challenges.GetNearbyAsync(query, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<NearbyCommunityChallengeDto>>.SuccessPagedResponse(
            items,
            pagination,
            "Nearby challenges retrieved successfully."));
    }

    /// <summary>Travel estimates and polyline from user location to challenge.</summary>
    [HttpGet("{id:guid}/route")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<ChallengeRouteDto>>> GetRoute(
        Guid id,
        [FromQuery] ChallengeRouteQuery query,
        CancellationToken cancellationToken)
    {
        var result = await _challenges.GetRouteAsync(id, query, cancellationToken);
        return Ok(ApiResponse<ChallengeRouteDto>.SuccessResponse(
            result,
            "Challenge route calculated successfully."));
    }

    [HttpPost("{id:guid}/join")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<ChallengeParticipantDto>>> Join(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _participation.JoinAsync(_currentUser.RequireUserId(), id, cancellationToken);
        return Ok(ApiResponse<ChallengeParticipantDto>.SuccessResponse(
            result,
            "Joined challenge successfully."));
    }

    [HttpPost("{id:guid}/leave")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<ChallengeParticipantDto>>> Leave(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _participation.LeaveAsync(_currentUser.RequireUserId(), id, cancellationToken);
        return Ok(ApiResponse<ChallengeParticipantDto>.SuccessResponse(
            result,
            "Left challenge successfully."));
    }

    [HttpPatch("{id:guid}/participants/me/progress")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<ChallengeParticipantDto>>> StartProgress(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _participation.StartProgressAsync(_currentUser.RequireUserId(), id, cancellationToken);
        return Ok(ApiResponse<ChallengeParticipantDto>.SuccessResponse(
            result,
            "Challenge progress started successfully."));
    }

    [HttpPatch("{id:guid}/participants/me/complete")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<ChallengeParticipantDto>>> Complete(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _participation.CompleteAsync(_currentUser.RequireUserId(), id, cancellationToken);
        return Ok(ApiResponse<ChallengeParticipantDto>.SuccessResponse(
            result,
            "Challenge completed successfully."));
    }

    [HttpGet("{id:guid}/participants")]
    [AllowAnonymous]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<ChallengeParticipantDto>>>> GetParticipants(
        Guid id,
        [FromQuery] ChallengeParticipantListQuery query,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _participation.GetParticipantsAsync(id, query, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<ChallengeParticipantDto>>.SuccessPagedResponse(
            items,
            pagination,
            "Challenge participants retrieved successfully."));
    }

    [HttpGet("{id:guid}/participation-status")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<ChallengeParticipationStatusDto>>> GetParticipationStatus(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _participation.GetParticipationStatusAsync(
            _currentUser.RequireUserId(),
            id,
            cancellationToken);

        return Ok(ApiResponse<ChallengeParticipationStatusDto>.SuccessResponse(
            result,
            "Participation status retrieved successfully."));
    }

    /// <summary>Full detail of an active challenge.</summary>
    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<CommunityChallengeDto>>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _challenges.GetActiveByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<CommunityChallengeDto>.SuccessResponse(
            result,
            "Challenge retrieved successfully."));
    }
}
