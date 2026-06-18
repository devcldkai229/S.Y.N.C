using Iam.Application.DTOs;
using Iam.Application.Exceptions;
using Iam.Domain.Enums;
using Iam.Domain.Models;
using Iam.Domain.Repositories;
using Libs.Storage.Services;

namespace Iam.Application.Services;

public class AdminUserService : IAdminUserService
{
    private readonly IUserRepository _users;
    private readonly IMediaUrlResolver _media;

    public AdminUserService(IUserRepository users, IMediaUrlResolver media)
    {
        _users = users;
        _media = media;
    }

    public async Task<IReadOnlyList<AdminUserListItemDto>> GetAllAsync(
        string? search,
        UserRole? role,
        UserStatus? status,
        CancellationToken cancellationToken = default)
    {
        var users = await _users.GetAllForAdminAsync(search, role, status, cancellationToken);
        return users.Select(Map).ToList();
    }

    public async Task<AdminUserListItemDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var user = await _users.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException("User not found.");
        return Map(user);
    }

    public async Task<AdminUserListItemDto> UpdateStatusAsync(Guid id, UserStatus status, CancellationToken cancellationToken = default)
    {
        var user = await _users.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException("User not found.");
        user.Status = status;
        await _users.UpdateAsync(user, cancellationToken);
        return Map(user);
    }

    public async Task<AdminUserListItemDto> UpdateRoleAsync(Guid id, UserRole role, CancellationToken cancellationToken = default)
    {
        var user = await _users.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException("User not found.");
        user.Role = role;
        await _users.UpdateAsync(user, cancellationToken);
        return Map(user);
    }

    private AdminUserListItemDto Map(User u) => new()
    {
        Id = u.Id,
        Email = u.Email,
        FullName = u.FullName,
        AvatarUrl = _media.ResolveForDisplay(u.AvatarUrl),
        Role = u.Role,
        Status = u.Status,
        SubscriptionTier = u.SubscriptionTier,
        EmailVerified = u.EmailVerified,
        LastActiveAt = u.LastActiveAt,
        LastLoginAt = u.LastLoginAt,
        CreatedAt = u.CreatedAt,
    };
}
