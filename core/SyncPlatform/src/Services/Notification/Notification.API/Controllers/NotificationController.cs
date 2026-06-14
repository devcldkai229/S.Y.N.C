using Libs.Auth.Context;
using Notification.Application.Common;
using Notification.Application.DTOs;
using Notification.Application.Exceptions;
using Notification.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Notification.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/notifications")]
public class NotificationController : ControllerBase
{
    private readonly INotificationService _service;
    private readonly ICurrentUserContext _currentUser;

    public NotificationController(INotificationService service, ICurrentUserContext currentUser)
    {
        _service = service;
        _currentUser = currentUser;
    }

    [HttpGet("me")]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<NotificationMessageDto>>>> GetMyPaged(
        [FromQuery] NotificationSearchRequest request,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _service.GetPagedByUserIdAsync(userId, request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<NotificationMessageDto>>.SuccessPagedResponse(
            result.Items,
            result.Pagination,
            "Notifications retrieved successfully."));
    }

    [HttpGet("me/unread-count")]
    public async Task<ActionResult<ApiResponse<int>>> GetMyUnreadCount(
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var count = await _service.GetUnreadCountByUserIdAsync(userId, cancellationToken);
        return Ok(ApiResponse<int>.SuccessResponse(count, "Unread count retrieved successfully."));
    }

    [HttpPatch("me/{id:guid}/read")]
    public async Task<ActionResult<ApiResponse<object?>>> MarkMyAsRead(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        await _service.MarkAsReadAsync(userId, id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Notification marked as read successfully."));
    }

    [HttpPost("me/read-all")]
    public async Task<ActionResult<ApiResponse<object?>>> MarkAllMyAsRead(
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        await _service.MarkAllAsReadAsync(userId, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "All notifications marked as read successfully."));
    }

    [HttpGet("users/{userId:guid}")]
    public async Task<ActionResult<PagedApiResponse<IReadOnlyList<NotificationMessageDto>>>> GetPaged(
        Guid userId,
        [FromQuery] NotificationSearchRequest request,
        CancellationToken cancellationToken)
    {
        EnsureUserAccess(userId);
        var result = await _service.GetPagedByUserIdAsync(userId, request, cancellationToken);
        return Ok(PagedApiResponse<IReadOnlyList<NotificationMessageDto>>.SuccessPagedResponse(
            result.Items,
            result.Pagination,
            "Notifications retrieved successfully."));
    }

    [HttpGet("users/{userId:guid}/unread-count")]
    public async Task<ActionResult<ApiResponse<int>>> GetUnreadCount(
        Guid userId,
        CancellationToken cancellationToken)
    {
        EnsureUserAccess(userId);
        var count = await _service.GetUnreadCountByUserIdAsync(userId, cancellationToken);
        return Ok(ApiResponse<int>.SuccessResponse(count, "Unread count retrieved successfully."));
    }

    [HttpPatch("users/{userId:guid}/{id:guid}/read")]
    public async Task<ActionResult<ApiResponse<object?>>> MarkAsRead(
        Guid userId,
        Guid id,
        CancellationToken cancellationToken)
    {
        EnsureUserAccess(userId);
        await _service.MarkAsReadAsync(userId, id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Notification marked as read successfully."));
    }

    [HttpPost("users/{userId:guid}/read-all")]
    public async Task<ActionResult<ApiResponse<object?>>> MarkAllAsRead(
        Guid userId,
        CancellationToken cancellationToken)
    {
        EnsureUserAccess(userId);
        await _service.MarkAllAsReadAsync(userId, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "All notifications marked as read successfully."));
    }

    [HttpDelete("users/{userId:guid}/{id:guid}")]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(
        Guid userId,
        Guid id,
        CancellationToken cancellationToken)
    {
        EnsureUserAccess(userId);
        await _service.DeleteNotificationAsync(userId, id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Notification deleted successfully."));
    }

    [HttpPost("send")]
    public async Task<ActionResult<ApiResponse<NotificationMessageDto>>> Send(
        [FromBody] SendNotificationDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.SendNotificationAsync(dto, cancellationToken);
        return Ok(ApiResponse<NotificationMessageDto>.SuccessResponse(result, "Notification sent/scheduled successfully."));
    }

    [HttpPost("send-templated")]
    public async Task<ActionResult<ApiResponse<NotificationMessageDto>>> SendTemplated(
        [FromBody] SendTemplatedNotificationDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _service.SendTemplatedNotificationAsync(dto, cancellationToken);
        return Ok(ApiResponse<NotificationMessageDto>.SuccessResponse(result, "Templated notification sent/scheduled successfully."));
    }

    [HttpDelete("scheduled/{id:guid}")]
    public async Task<ActionResult<ApiResponse<object?>>> CancelScheduled(
        Guid id,
        CancellationToken cancellationToken)
    {
        await _service.CancelScheduledNotificationAsync(id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Scheduled notification cancelled successfully."));
    }

    private void EnsureUserAccess(Guid userId)
    {
        if (_currentUser.RequireUserId() != userId)
            throw new ForbiddenException("You can only access notifications for your own account.");
    }
}
