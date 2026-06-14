using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[Route("api/v1/payments/subscription-plans")]
public class SubscriptionPlansController : ControllerBase
{
    private readonly ISubscriptionPlanService _planService;

    public SubscriptionPlansController(ISubscriptionPlanService planService)
    {
        _planService = planService;
    }

    /// <summary>
    /// GET /api/v1/payments/subscription-plans
    /// Lấy danh sách các gói subscription đang kích hoạt (Active) - Dành cho khách/người dùng
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<SubscriptionPlanDto>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<IEnumerable<SubscriptionPlanDto>>>> GetActivePlans(CancellationToken cancellationToken)
    {
        var result = await _planService.GetActivePlansAsync(cancellationToken);
        return Ok(ApiResponse<IEnumerable<SubscriptionPlanDto>>.SuccessResponse(result, "Active subscription plans retrieved."));
    }

    /// <summary>
    /// GET /api/v1/payments/subscription-plans/{id}
    /// Lấy chi tiết gói subscription theo ID
    /// </summary>
    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<SubscriptionPlanDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<SubscriptionPlanDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _planService.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<SubscriptionPlanDto>.SuccessResponse(result, "Subscription plan retrieved."));
    }

    /// <summary>
    /// GET /api/v1/payments/subscription-plans/admin
    /// Lấy toàn bộ danh sách gói subscription (bao gồm cả Inactive và Deleted) - Dành cho Admin
    /// </summary>
    [HttpGet("admin")]
    [Authorize(Roles = "SystemAdmin")]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<SubscriptionPlanDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ApiResponse<IEnumerable<SubscriptionPlanDto>>>> GetAllPlans(
        [FromQuery] bool includeInactive = true,
        [FromQuery] bool includeDeleted = true,
        CancellationToken cancellationToken = default)
    {
        var result = await _planService.GetAllPlansAsync(includeInactive, includeDeleted, cancellationToken);
        return Ok(ApiResponse<IEnumerable<SubscriptionPlanDto>>.SuccessResponse(result, "All subscription plans retrieved."));
    }

    /// <summary>
    /// POST /api/v1/payments/subscription-plans
    /// Tạo mới gói subscription - Dành cho Admin
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "SystemAdmin")]
    [ProducesResponseType(typeof(ApiResponse<SubscriptionPlanDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ApiResponse<SubscriptionPlanDto>>> Create(
        [FromBody] CreateSubscriptionPlanDto request,
        CancellationToken cancellationToken)
    {
        var result = await _planService.CreateAsync(request, cancellationToken);
        return StatusCode(
            StatusCodes.Status201Created,
            ApiResponse<SubscriptionPlanDto>.SuccessResponse(result, "Subscription plan created successfully."));
    }

    /// <summary>
    /// PUT /api/v1/payments/subscription-plans/{id}
    /// Cập nhật thông tin gói subscription - Dành cho Admin
    /// </summary>
    [HttpPut("{id:guid}")]
    [Authorize(Roles = "SystemAdmin")]
    [ProducesResponseType(typeof(ApiResponse<SubscriptionPlanDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ApiResponse<SubscriptionPlanDto>>> Update(
        Guid id,
        [FromBody] UpdateSubscriptionPlanDto request,
        CancellationToken cancellationToken)
    {
        var result = await _planService.UpdateAsync(id, request, cancellationToken);
        return Ok(ApiResponse<SubscriptionPlanDto>.SuccessResponse(result, "Subscription plan updated successfully."));
    }

    /// <summary>
    /// DELETE /api/v1/payments/subscription-plans/{id}
    /// Xoá mềm/Xoá cứng gói subscription - Dành cho Admin
    /// </summary>
    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "SystemAdmin")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<object>>> Delete(
        Guid id,
        [FromQuery] bool softDelete = true,
        CancellationToken cancellationToken = default)
    {
        await _planService.DeleteAsync(id, softDelete, cancellationToken);
        var message = softDelete ? "Subscription plan soft-deleted successfully." : "Subscription plan hard-deleted successfully.";
        return Ok(ApiResponse<object>.SuccessResponse(null!, message));
    }
}
