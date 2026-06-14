using Iam.Application.DTOs;
using Iam.Domain.Enums;

namespace Iam.Application.Services;

public interface IAdminUserService
{
    Task<IReadOnlyList<AdminUserListItemDto>> GetAllAsync(
        string? search,
        UserRole? role,
        UserStatus? status,
        CancellationToken cancellationToken = default);

    Task<AdminUserListItemDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<AdminUserListItemDto> UpdateStatusAsync(Guid id, UserStatus status, CancellationToken cancellationToken = default);

    Task<AdminUserListItemDto> UpdateRoleAsync(Guid id, UserRole role, CancellationToken cancellationToken = default);
}
