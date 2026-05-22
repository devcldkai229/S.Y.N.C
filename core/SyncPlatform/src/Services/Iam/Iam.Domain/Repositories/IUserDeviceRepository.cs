using Iam.Domain.Models;

namespace Iam.Domain.Repositories;

public interface IUserDeviceRepository
{
    Task<UserDevice?> GetByUserAndDeviceAsync(Guid userId, string deviceId, CancellationToken cancellationToken = default);
    Task<UserDevice?> GetByDeviceIdAsync(string deviceId, CancellationToken cancellationToken = default);
    Task AddAsync(UserDevice device, CancellationToken cancellationToken = default);
    void Update(UserDevice device);
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
