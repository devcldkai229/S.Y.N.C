using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/social/users")]
public class UserFollowController : ControllerBase
{
    private readonly IUserFollowService _follows;
    private readonly ICurrentUserContext _currentUser;

    public UserFollowController(IUserFollowService follows, ICurrentUserContext currentUser)
    {
        _follows = follows;
        _currentUser = currentUser;
    }

    /// <summary>Follow a user. Public profiles → Accepted; private profiles → Pending.</summary>
    [HttpPost("{userId:guid}/follow")]
    public async Task<ActionResult<ApiResponse<UserFollowDto>>> Follow(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _follows.FollowAsync(_currentUser.RequireUserId(), userId, cancellationToken);
        return Ok(ApiResponse<UserFollowDto>.SuccessResponse(result, "Follow request processed successfully."));
    }

    /// <summary>Unfollow a user or cancel a pending outgoing request.</summary>
    [HttpDelete("{userId:guid}/follow")]
    public async Task<ActionResult<ApiResponse<object?>>> Unfollow(
        Guid userId,
        CancellationToken cancellationToken)
    {
        await _follows.UnfollowAsync(_currentUser.RequireUserId(), userId, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Unfollowed successfully."));
    }

    /// <summary>Accept a pending follow request from <paramref name="userId"/>.</summary>
    [HttpPost("{userId:guid}/follow/accept")]
    public async Task<ActionResult<ApiResponse<UserFollowDto>>> AcceptFollowRequest(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _follows.AcceptFollowRequestAsync(
            _currentUser.RequireUserId(),
            userId,
            cancellationToken);
        return Ok(ApiResponse<UserFollowDto>.SuccessResponse(result, "Follow request accepted."));
    }

    /// <summary>Reject a pending follow request from <paramref name="userId"/>.</summary>
    [HttpPost("{userId:guid}/follow/reject")]
    public async Task<ActionResult<ApiResponse<object?>>> RejectFollowRequest(
        Guid userId,
        CancellationToken cancellationToken)
    {
        await _follows.RejectFollowRequestAsync(
            _currentUser.RequireUserId(),
            userId,
            cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Follow request rejected."));
    }

    /// <summary>Block a user. Removes any existing follow relationship and prevents future follows.</summary>
    [HttpPost("{userId:guid}/block")]
    public async Task<ActionResult<ApiResponse<UserFollowDto>>> Block(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _follows.BlockUserAsync(_currentUser.RequireUserId(), userId, cancellationToken);
        return Ok(ApiResponse<UserFollowDto>.SuccessResponse(result, "User blocked successfully."));
    }

    /// <summary>Paginated list of users who follow <paramref name="userId"/>.</summary>
    [HttpGet("{userId:guid}/followers")]
    [AllowAnonymous]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<UserFollowDto>>>> GetFollowers(
        Guid userId,
        [FromQuery] FollowListQuery query,
        CancellationToken cancellationToken)
    {
        var result = await _follows.GetFollowersAsync(userId, query, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<UserFollowDto>>.SuccessPagedResponse(
            result.Items,
            result.Pagination,
            "Followers retrieved successfully."));
    }

    /// <summary>Paginated list of users that <paramref name="userId"/> follows.</summary>
    [HttpGet("{userId:guid}/following")]
    [AllowAnonymous]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<UserFollowDto>>>> GetFollowing(
        Guid userId,
        [FromQuery] FollowListQuery query,
        CancellationToken cancellationToken)
    {
        var result = await _follows.GetFollowingAsync(userId, query, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<UserFollowDto>>.SuccessPagedResponse(
            result.Items,
            result.Pagination,
            "Following list retrieved successfully."));
    }

    /// <summary>Relationship between the current user and <paramref name="userId"/>.</summary>
    [HttpGet("{userId:guid}/follow-status")]
    public async Task<ActionResult<ApiResponse<FollowStatusDto>>> GetFollowStatus(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _follows.GetFollowStatusAsync(
            _currentUser.RequireUserId(),
            userId,
            cancellationToken);
        return Ok(ApiResponse<FollowStatusDto>.SuccessResponse(result, "Follow status retrieved successfully."));
    }

    /// <summary>Follower and following counts for a user.</summary>
    [HttpGet("{userId:guid}/follow-counts")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<FollowCountsDto>>> GetFollowCounts(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _follows.GetFollowCountsAsync(userId, cancellationToken);
        return Ok(ApiResponse<FollowCountsDto>.SuccessResponse(result, "Follow counts retrieved successfully."));
    }
}
