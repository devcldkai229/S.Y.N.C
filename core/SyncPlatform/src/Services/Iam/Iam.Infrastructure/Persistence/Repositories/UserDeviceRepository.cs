using Iam.Domain.Models;
using Iam.Domain.Repositories;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence.Repositories;

public class UserDeviceRepository : IUserDeviceRepository
{
    private readonly IamDbContext _db;

    public UserDeviceRepository(IamDbContext db)
    {
        _db = db;
    }

    public Task<UserDevice?> GetByUserAndDeviceAsync(Guid userId, string deviceId, CancellationToken cancellationToken = default)
        => _db.UserDevices.FirstOrDefaultAsync(d => d.UserId == userId && d.DeviceId == deviceId, cancellationToken);

    public Task<UserDevice?> GetByDeviceIdAsync(string deviceId, CancellationToken cancellationToken = default)
        => _db.UserDevices.FirstOrDefaultAsync(d => d.DeviceId == deviceId, cancellationToken);

    public async Task AddAsync(UserDevice device, CancellationToken cancellationToken = default)
        => await _db.UserDevices.AddAsync(device, cancellationToken);

    public void Update(UserDevice device)
        => _db.UserDevices.Update(device);

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => _db.SaveChangesAsync(cancellationToken);
}
