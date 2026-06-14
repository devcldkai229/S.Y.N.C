using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Services;
using Iam.Domain.Enums;
using Libs.Auth.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AdminOnly)]
[Route("api/v1/users")]
public class AdminUsersController : ControllerBase
{
    private readonly IAdminUserService _adminUsers;

    public AdminUsersController(IAdminUserService adminUsers)
    {
        _adminUsers = adminUsers;
    }

    /// <summary>GET /api/v1/users — admin listing with optional search/role/status filters.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<AdminUserListItemDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<AdminUserListItemDto>>>> GetAll(
        [FromQuery] string? search,
        [FromQuery] UserRole? role,
        [FromQuery] UserStatus? status,
        CancellationToken cancellationToken)
    {
        var result = await _adminUsers.GetAllAsync(search, role, status, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<AdminUserListItemDto>>.SuccessResponse(result, "Users retrieved successfully."));
    }

    /// <summary>GET /api/v1/users/{id} — admin user detail.</summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<AdminUserListItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<AdminUserListItemDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _adminUsers.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<AdminUserListItemDto>.SuccessResponse(result, "User retrieved successfully."));
    }

    /// <summary>PUT /api/v1/users/{id}/status — ban/suspend/activate a user.</summary>
    [HttpPut("{id:guid}/status")]
    [ProducesResponseType(typeof(ApiResponse<AdminUserListItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<AdminUserListItemDto>>> UpdateStatus(
        Guid id,
        [FromBody] UpdateUserStatusDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _adminUsers.UpdateStatusAsync(id, dto.Status, cancellationToken);
        return Ok(ApiResponse<AdminUserListItemDto>.SuccessResponse(result, "User status updated successfully."));
    }

    /// <summary>PUT /api/v1/users/{id}/role — change a user's platform role.</summary>
    [HttpPut("{id:guid}/role")]
    [ProducesResponseType(typeof(ApiResponse<AdminUserListItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<AdminUserListItemDto>>> UpdateRole(
        Guid id,
        [FromBody] UpdateUserRoleDto dto,
        CancellationToken cancellationToken)
    {
        var result = await _adminUsers.UpdateRoleAsync(id, dto.Role, cancellationToken);
        return Ok(ApiResponse<AdminUserListItemDto>.SuccessResponse(result, "User role updated successfully."));
    }
}
