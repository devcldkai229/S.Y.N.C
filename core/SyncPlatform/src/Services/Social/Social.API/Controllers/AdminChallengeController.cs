using Libs.Auth.Constants;
using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Social.Application.Clients;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;
using Social.Infrastructure.Options;

namespace Social.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AdminOnly)]
[Route("api/v1/admin/challenges")]
public class AdminChallengeController : ControllerBase
{
    private readonly ICommunityChallengeService _challenges;
    private readonly ICurrentUserContext _currentUser;
    private readonly IPlaceIndexClient _placeIndex;
    private readonly AwsLocationOptions _awsLocation;

    public AdminChallengeController(
        ICommunityChallengeService challenges,
        ICurrentUserContext currentUser,
        IPlaceIndexClient placeIndex,
        IOptions<AwsLocationOptions> awsLocation)
    {
        _challenges = challenges;
        _currentUser = currentUser;
        _placeIndex = placeIndex;
        _awsLocation = awsLocation.Value;
    }

    [HttpGet("location/search")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<AddressSuggestionDto>>>> SearchLocation(
        [FromQuery] string q,
        [FromQuery] double? lat,
        [FromQuery] double? lng,
        CancellationToken cancellationToken)
    {
        var results = await _placeIndex.SearchAsync(q, lat, lng, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<AddressSuggestionDto>>.SuccessResponse(
            results,
            "Address suggestions retrieved."));
    }

    [HttpGet("location/reverse")]
    public async Task<ActionResult<ApiResponse<ReverseGeocodeResultDto>>> ReverseLocation(
        [FromQuery] double lat,
        [FromQuery] double lng,
        CancellationToken cancellationToken)
    {
        var result = await _placeIndex.ReverseAsync(lat, lng, cancellationToken);
        return Ok(ApiResponse<ReverseGeocodeResultDto>.SuccessResponse(result, "Address resolved."));
    }

    [HttpGet("location/map-config")]
    public ActionResult<ApiResponse<ChallengeMapConfigDto>> GetMapConfig()
    {
        var config = new ChallengeMapConfigDto
        {
            Region = _awsLocation.Region,
            MapName = _awsLocation.MapName,
            MapStyle = _awsLocation.MapStyle,
            PlacesEnabled = _awsLocation.IsPlacesConfigured,
        };

        return Ok(ApiResponse<ChallengeMapConfigDto>.SuccessResponse(config, "Map configuration retrieved."));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<CommunityChallengeDto>>> Create(
        [FromBody] AdminCreateCommunityChallengeDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _challenges.CreateAdminAsync(
            _currentUser.RequireUserId(),
            dto,
            cancellationToken);

        return Ok(ApiResponse<CommunityChallengeDto>.SuccessResponse(
            result,
            "Community challenge created successfully."));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ApiResponse<CommunityChallengeDto>>> Update(
        Guid id,
        [FromBody] AdminUpdateCommunityChallengeDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _challenges.UpdateAdminAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<CommunityChallengeDto>.SuccessResponse(
            result,
            "Community challenge updated successfully."));
    }

    [HttpDelete("{id:guid}")]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(
        Guid id,
        CancellationToken cancellationToken)
    {
        await _challenges.DeleteAdminAsync(id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Community challenge deleted successfully."));
    }

    [HttpPatch("{id:guid}/activate")]
    public async Task<ActionResult<ApiResponse<CommunityChallengeDto>>> Activate(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _challenges.ActivateAsync(id, cancellationToken);
        return Ok(ApiResponse<CommunityChallengeDto>.SuccessResponse(
            result,
            "Community challenge activated successfully."));
    }

    [HttpPatch("{id:guid}/complete")]
    public async Task<ActionResult<ApiResponse<CommunityChallengeDto>>> Complete(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _challenges.CompleteAsync(id, cancellationToken);
        return Ok(ApiResponse<CommunityChallengeDto>.SuccessResponse(
            result,
            "Community challenge completed successfully."));
    }

    [HttpGet]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<CommunityChallengeDto>>>> GetAll(
        [FromQuery] ChallengeAdminListQuery query,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _challenges.GetAdminPagedAsync(query, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<CommunityChallengeDto>>.SuccessPagedResponse(
            items,
            pagination,
            "Challenges retrieved successfully."));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ApiResponse<CommunityChallengeDto>>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _challenges.GetAdminByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<CommunityChallengeDto>.SuccessResponse(
            result,
            "Challenge retrieved successfully."));
    }
}
