using Libs.Auth.Constants;
using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Services;

namespace Marketplace.API.Controllers;

[ApiController]
[Route("api/v1/affiliate-products")]
public class AffiliateProductsController : ControllerBase
{
    private readonly IAffiliateProductService _service;
    private readonly IAffiliateClickService _clickService;
    private readonly ICurrentUserContext _currentUser;

    public AffiliateProductsController(
        IAffiliateProductService service,
        IAffiliateClickService clickService,
        ICurrentUserContext currentUser)
    {
        _service = service;
        _clickService = clickService;
        _currentUser = currentUser;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<AffiliateProductDto>>>> Search(
        [FromQuery] AffiliateProductSearchRequest request,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _service.SearchAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<AffiliateProductDto>>.SuccessPagedResponse(
            items, pagination, "Affiliate products retrieved successfully."));
    }

    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<AffiliateProductDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<AffiliateProductDto>.SuccessResponse(result, "Affiliate product retrieved successfully."));
    }

    [HttpPost("partners/{partnerId:guid}")]
    [Authorize(Policy = AuthPolicies.PartnerOnly)]
    public async Task<ActionResult<ApiResponse<AffiliateProductDto>>> Create(
        Guid partnerId,
        [FromBody] CreateAffiliateProductDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.CreateAsync(_currentUser.RequireUserId(), partnerId, dto, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = result.Id },
            ApiResponse<AffiliateProductDto>.SuccessResponse(result, "Affiliate product created successfully."));
    }

    [HttpPut("partners/{partnerId:guid}/{productId:guid}")]
    [Authorize(Policy = AuthPolicies.PartnerOnly)]
    public async Task<ActionResult<ApiResponse<AffiliateProductDto>>> Update(
        Guid partnerId,
        Guid productId,
        [FromBody] UpdateAffiliateProductDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.UpdateAsync(_currentUser.RequireUserId(), partnerId, productId, dto, cancellationToken);
        return Ok(ApiResponse<AffiliateProductDto>.SuccessResponse(result, "Affiliate product updated successfully."));
    }

    [HttpDelete("partners/{partnerId:guid}/{productId:guid}")]
    [Authorize(Policy = AuthPolicies.PartnerOnly)]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(
        Guid partnerId,
        Guid productId,
        CancellationToken cancellationToken)
    {
        await _service.SoftDeleteAsync(_currentUser.RequireUserId(), partnerId, productId, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Affiliate product deleted successfully."));
    }

    [HttpPost("{id:guid}/click")]
    [Authorize(Policy = AuthPolicies.AuthenticatedUser)]
    public async Task<ActionResult<ApiResponse<AffiliateClickResponseDto>>> TrackClick(
        Guid id,
        [FromQuery] AffiliateClickRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _clickService.TrackClickAsync(_currentUser.RequireUserId(), id, request, cancellationToken);
        return Ok(ApiResponse<AffiliateClickResponseDto>.SuccessResponse(result, "Affiliate click tracked successfully."));
    }
}
