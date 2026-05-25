using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Services;
using Payment.Domain.Enums;

namespace Payment.API.Controllers;

[ApiController]
[Route("api/v1/payments/user-subscriptions")]
public class UserSubscriptionsController : ControllerBase
{
    private readonly IUserSubscriptionService _subService;
    private readonly ICurrentUserContext _currentUser;

    public UserSubscriptionsController(IUserSubscriptionService subService, ICurrentUserContext currentUser)
    {
        _subService = subService;
        _currentUser = currentUser;
    }

    /// <summary>
    /// GET /api/v1/payments/user-subscriptions/me
    /// Lấy danh sách lịch sử gói subscription của người dùng hiện tại
    /// </summary>
    [HttpGet("me")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<UserSubscriptionDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ApiResponse<IEnumerable<UserSubscriptionDto>>>> GetMySubscriptions(CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _subService.GetByUserIdAsync(userId, cancellationToken);
        return Ok(ApiResponse<IEnumerable<UserSubscriptionDto>>.SuccessResponse(result, "Your subscription history retrieved."));
    }

    /// <summary>
    /// GET /api/v1/payments/user-subscriptions/me/active
    /// Lấy gói subscription đang kích hoạt của người dùng hiện tại
    /// </summary>
    [HttpGet("me/active")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<UserSubscriptionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<UserSubscriptionDto>>> GetMyActiveSubscription(CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _subService.GetActiveByUserIdAsync(userId, cancellationToken);
        if (result == null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("No active subscription found."));
        }
        return Ok(ApiResponse<UserSubscriptionDto>.SuccessResponse(result, "Active subscription retrieved."));
    }

    /// <summary>
    /// POST /api/v1/payments/user-subscriptions/me/cancel
    /// Hủy gói gia hạn subscription của người dùng hiện tại
    /// </summary>
    [HttpPost("me/cancel")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<UserSubscriptionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<UserSubscriptionDto>>> CancelMySubscription(
        [FromBody] CancelSubscriptionRequest request,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var activeSub = await _subService.GetActiveByUserIdAsync(userId, cancellationToken);
        if (activeSub == null)
        {
            return NotFound(ApiResponse<object>.FailureResponse("No active subscription found to cancel."));
        }

        var result = await _subService.CancelSubscriptionAsync(activeSub.Id, request, cancellationToken);
        return Ok(ApiResponse<UserSubscriptionDto>.SuccessResponse(result, "Subscription cancelled successfully."));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ADMIN ENDPOINTS
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// GET /api/v1/payments/user-subscriptions
    /// Lấy danh sách toàn bộ gói đăng ký người dùng (Dành cho Admin)
    /// </summary>
    [HttpGet]
    [Authorize(Roles = "Admin,Staff")]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<UserSubscriptionDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ApiResponse<IEnumerable<UserSubscriptionDto>>>> GetAllSubscriptions(
        [FromQuery] Guid? userId,
        [FromQuery] SubscriptionStatus? status,
        [FromQuery] bool includeDeleted = true,
        CancellationToken cancellationToken = default)
    {
        var result = await _subService.GetAllSubscriptionsAsync(userId, status, includeDeleted, cancellationToken);
        return Ok(ApiResponse<IEnumerable<UserSubscriptionDto>>.SuccessResponse(result, "User subscriptions retrieved."));
    }

    /// <summary>
    /// GET /api/v1/payments/user-subscriptions/{id}
    /// Lấy chi tiết gói đăng ký theo ID (Dành cho Admin)
    /// </summary>
    [HttpGet("{id:guid}")]
    [Authorize(Roles = "Admin,Staff")]
    [ProducesResponseType(typeof(ApiResponse<UserSubscriptionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<UserSubscriptionDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _subService.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<UserSubscriptionDto>.SuccessResponse(result, "User subscription details retrieved."));
    }

    /// <summary>
    /// POST /api/v1/payments/user-subscriptions
    /// Tạo mới thủ công một gói đăng ký cho người dùng (Dành cho Admin)
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(typeof(ApiResponse<UserSubscriptionDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<UserSubscriptionDto>>> Create(
        [FromBody] CreateUserSubscriptionDto request,
        CancellationToken cancellationToken)
    {
        var result = await _subService.CreateAsync(request, cancellationToken);
        return StatusCode(
            StatusCodes.Status201Created,
            ApiResponse<UserSubscriptionDto>.SuccessResponse(result, "User subscription created successfully."));
    }

    /// <summary>
    /// PUT /api/v1/payments/user-subscriptions/{id}
    /// Cập nhật thông tin gói đăng ký của người dùng (Dành cho Admin)
    /// </summary>
    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(typeof(ApiResponse<UserSubscriptionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<UserSubscriptionDto>>> Update(
        Guid id,
        [FromBody] UpdateUserSubscriptionDto request,
        CancellationToken cancellationToken)
    {
        var result = await _subService.UpdateAsync(id, request, cancellationToken);
        return Ok(ApiResponse<UserSubscriptionDto>.SuccessResponse(result, "User subscription updated successfully."));
    }

    /// <summary>
    /// DELETE /api/v1/payments/user-subscriptions/{id}
    /// Xóa/Hủy vĩnh viễn gói đăng ký (Dành cho Admin)
    /// </summary>
    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<object>>> Delete(
        Guid id,
        [FromQuery] bool softDelete = true,
        CancellationToken cancellationToken = default)
    {
        await _subService.DeleteAsync(id, softDelete, cancellationToken);
        var message = softDelete ? "User subscription soft-deleted successfully." : "User subscription hard-deleted successfully.";
        return Ok(ApiResponse<object>.SuccessResponse(null!, message));
    }
}
