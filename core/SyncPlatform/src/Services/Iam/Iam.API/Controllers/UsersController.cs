using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/v1/users")]
public class UsersController : ControllerBase
{
    private readonly IPublicProfileService _publicProfiles;
    private readonly IUserSearchService _userSearch;

    public UsersController(IPublicProfileService publicProfiles, IUserSearchService userSearch)
    {
        _publicProfiles = publicProfiles;
        _userSearch = userSearch;
    }

    [HttpGet("search")]
    [ProducesResponseType(typeof(PagedApiResponse<IReadOnlyList<UserSearchItemDto>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<UserSearchItemDto>>>> Search(
        [FromQuery] UserSearchRequest request,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _userSearch.SearchAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<UserSearchItemDto>>.SuccessPagedResponse(
            items,
            pagination,
            "Users retrieved successfully."));
    }

    /// <summary>
    /// Public profile for social walls — gamification summary only (no biometrics/preferences).
    /// </summary>
    [HttpGet("{id:guid}/public-profile")]
    [ProducesResponseType(typeof(ApiResponse<PublicProfileResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<PublicProfileResponse>>> GetPublicProfile(
        Guid id,
        CancellationToken cancellationToken)
    {
        var profile = await _publicProfiles.GetPublicProfileAsync(id, cancellationToken);
        return Ok(ApiResponse<PublicProfileResponse>.SuccessResponse(
            profile,
            "Public profile retrieved successfully."));
    }
}
