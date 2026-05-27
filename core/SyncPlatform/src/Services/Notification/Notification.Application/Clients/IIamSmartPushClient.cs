using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Clients;

public interface IIamSmartPushClient
{
    Task<IReadOnlyList<DueSmartPushUserDto>> GetDueUsersAsync(DateTime utcNow, CancellationToken cancellationToken);
    Task<IamSmartPushContextDto?> GetContextAsync(Guid userId, CancellationToken cancellationToken);
}
