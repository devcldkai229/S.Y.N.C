using Iam.Application.Abstractions;
using Iam.Domain.Enums;
using Iam.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence.Repositories;

public sealed class AdminDashboardReadRepository : IAdminDashboardReadRepository
{
    private readonly IamDbContext _db;

    public AdminDashboardReadRepository(IamDbContext db) => _db = db;

    public async Task<IReadOnlyList<UserDashboardRow>> GetUserRowsAsync(CancellationToken cancellationToken = default)
    {
        return await _db.Users
            .AsNoTracking()
            .Where(u => u.Status != UserStatus.Deleted)
            .Select(u => new UserDashboardRow(
                u.Id,
                u.Email,
                u.FullName,
                u.AvatarUrl,
                u.Role,
                u.Status,
                u.SubscriptionTier,
                u.EmailVerified,
                u.LastActiveAt,
                u.LastLoginAt,
                u.CreatedAt))
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<PlatformCountRow>> GetPlatformCountsAsync(CancellationToken cancellationToken = default)
    {
        return await _db.UserDevices
            .AsNoTracking()
            .GroupBy(d => d.Platform)
            .Select(g => new PlatformCountRow(g.Key.ToString(), g.Count()))
            .ToListAsync(cancellationToken);
    }
}
