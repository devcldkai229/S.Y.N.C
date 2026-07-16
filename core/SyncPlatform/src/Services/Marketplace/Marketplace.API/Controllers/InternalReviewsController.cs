using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Services;
using Marketplace.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Marketplace.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/reviews")]
public class InternalReviewsController : ControllerBase
{
    private readonly IReviewService _reviewService;

    public InternalReviewsController(IReviewService reviewService)
    {
        _reviewService = reviewService;
    }

    [HttpGet]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<ReviewDto>>>> List(
        [FromQuery] ReviewTargetType targetType,
        [FromQuery] Guid targetId,
        [FromQuery] int limit = 20,
        [FromQuery] int pageNumber = 1,
        CancellationToken cancellationToken = default)
    {
        var request = new ReviewListRequest
        {
            TargetType = targetType,
            TargetId = targetId,
            PageNumber = Math.Max(1, pageNumber),
            PageSize = Math.Clamp(limit, 1, 50),
        };
        var (items, pagination) = await _reviewService.ListByTargetAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<ReviewDto>>.SuccessPagedResponse(
            items, pagination, "Reviews retrieved."));
    }
}
