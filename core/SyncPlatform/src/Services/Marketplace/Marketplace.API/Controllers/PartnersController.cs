using Libs.Auth.Constants;
using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Services;

namespace Marketplace.API.Controllers;

[ApiController]
[Route("api/v1/partners")]
public class PartnersController : ControllerBase
{
    private readonly IPartnerService _service;
    private readonly ICurrentUserContext _currentUser;

    public PartnersController(IPartnerService service, ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<PartnerDto>>>> Search(
        [FromQuery] PartnerSearchRequest request,
        CancellationToken cancellationToken)
    {
        var (items, pagination) = await _service.SearchAsync(request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<PartnerDto>>.SuccessPagedResponse(
            items, pagination, "Partners retrieved successfully."));
    }

    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<PartnerDetailDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _service.GetDetailAsync(id, cancellationToken);
        return Ok(ApiResponse<PartnerDetailDto>.SuccessResponse(result, "Partner retrieved successfully."));
    }

    [HttpGet("me")]
    [Authorize(Policy = AuthPolicies.PartnerOnly)]
    public async Task<ActionResult<ApiResponse<PartnerDto>>> GetMyPartner(CancellationToken cancellationToken)
    {
        var result = await _service.GetMyPartnerAsync(_currentUser.RequireUserId(), cancellationToken);
        return Ok(ApiResponse<PartnerDto>.SuccessResponse(result, "Partner profile retrieved successfully."));
    }

    [HttpPost("register")]
    [Authorize(Policy = AuthPolicies.PartnerOnly)]
    public async Task<ActionResult<ApiResponse<PartnerDto>>> Register(
        [FromBody] RegisterPartnerDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.RegisterAsync(_currentUser.RequireUserId(), dto, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = result.Id },
            ApiResponse<PartnerDto>.SuccessResponse(result, "Partner registered successfully."));
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = AuthPolicies.PartnerOnly)]
    public async Task<ActionResult<ApiResponse<PartnerDto>>> Update(
        Guid id,
        [FromBody] UpdatePartnerDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.UpdateAsync(_currentUser.RequireUserId(), id, dto, cancellationToken);
        return Ok(ApiResponse<PartnerDto>.SuccessResponse(result, "Partner updated successfully."));
    }
}
