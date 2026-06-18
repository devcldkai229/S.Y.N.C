using Iam.Domain.Models;

namespace Iam.Domain.Repositories;

public interface IInternalSmartPushRepository
{
    Task<IReadOnlyList<User>> GetUsersForSmartPushAsync(CancellationToken cancellationToken);
    Task<User?> GetUserSmartPushContextAsync(Guid userId, CancellationToken cancellationToken);
}
