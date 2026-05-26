using Iam.Application.DTOs;

namespace Iam.Application.Services;

public interface IInternalSmartPushService
{
    Task<IReadOnlyList<DueSmartPushUserDto>> GetDueUsersAsync(DateTime utcNow, CancellationToken cancellationToken);
    Task<IamSmartPushContextDto?> GetSmartPushContextAsync(Guid userId, CancellationToken cancellationToken);
}
