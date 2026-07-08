using Iam.Application.DTOs;
using Iam.Domain.Enums;

namespace Iam.Application.Abstractions;

public interface IAdminDashboardReadRepository
{
    Task<IReadOnlyList<UserDashboardRow>> GetUserRowsAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PlatformCountRow>> GetPlatformCountsAsync(CancellationToken cancellationToken = default);
}

public sealed record UserDashboardRow(
    Guid Id,
    string Email,
    string FullName,
    string? AvatarUrl,
    UserRole Role,
    UserStatus Status,
    SubscriptionTier SubscriptionTier,
    bool EmailVerified,
    DateTimeOffset? LastActiveAt,
    DateTimeOffset? LastLoginAt,
    DateTimeOffset CreatedAt);

public sealed record PlatformCountRow(string Platform, int Count);
