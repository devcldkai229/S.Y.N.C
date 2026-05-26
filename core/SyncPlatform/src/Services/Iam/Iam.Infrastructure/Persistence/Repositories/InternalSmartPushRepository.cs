using Iam.Domain.Models;
using Iam.Domain.Repositories;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence.Repositories;

public class InternalSmartPushRepository : IInternalSmartPushRepository
{
    private readonly IamDbContext _db;

    public InternalSmartPushRepository(IamDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<User>> GetUsersForSmartPushAsync(CancellationToken cancellationToken)
    {
        return await _db.Users
            .Include(u => u.UserPreference)
            .Where(u => u.UserPreference != null && u.UserPreference.SmartPushEnabled && u.UserPreference.AllowAiGeneratedNotification)
            .ToListAsync(cancellationToken);
    }

    public async Task<User?> GetUserSmartPushContextAsync(Guid userId, CancellationToken cancellationToken)
    {
        return await _db.Users
            .Include(u => u.UserPreference)
            .Include(u => u.AIContextProfile)
            .Include(u => u.GamificationProfile)
            .Include(u => u.BiometricProfile)
            .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);
    }
}
