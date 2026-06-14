using Libs.Auth.Constants;
using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Services;

namespace Marketplace.API.Controllers;

[ApiController]
[Route("api/v1/reviews")]
public class ReviewsController : ControllerBase
{
    private readonly IReviewService _service;
    private readonly ICurrentUserContext _currentUser;

    public ReviewsController(IReviewService service, ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<ReviewDto>>>> List(
        [FromQuery] ReviewListRequest request,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _service.ListByTargetAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<ReviewDto>>.SuccessPagedResponse(
            items, pagination, "Reviews retrieved successfully."));
    }

    [HttpPost]
    [Authorize(Policy = AuthPolicies.AuthenticatedUser)]
    public async Task<ActionResult<ApiResponse<ReviewDto>>> Create(
        [FromBody] CreateReviewDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.CreateAsync(_currentUser.RequireUserId(), dto, cancellationToken);
        return Ok(ApiResponse<ReviewDto>.SuccessResponse(result, "Review created successfully."));
    }

    [HttpGet("partners/{partnerId:guid}")]
    [Authorize(Policy = AuthPolicies.PartnerOnly)]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<ReviewDto>>>> ListForPartner(
        Guid partnerId,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var (items, pagination) = await _service.ListForPartnerAsync(
            _currentUser.RequireUserId(), partnerId, pageNumber, pageSize, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<ReviewDto>>.SuccessPagedResponse(
            items, pagination, "Partner reviews retrieved successfully."));
    }

    [HttpPost("partners/{partnerId:guid}/{reviewId:guid}/reply")]
    [Authorize(Policy = AuthPolicies.PartnerOnly)]
    public async Task<ActionResult<ApiResponse<ReviewDto>>> Reply(
        Guid partnerId,
        Guid reviewId,
        [FromBody] PartnerReplyDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.ReplyAsync(_currentUser.RequireUserId(), partnerId, reviewId, dto, cancellationToken);
        return Ok(ApiResponse<ReviewDto>.SuccessResponse(result, "Reply posted successfully."));
    }
}
