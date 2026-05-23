using Notification.Domain.Models;

namespace Notification.Domain.Repositories;

public interface INotificationTemplateRepository : IGenericRepository<NotificationTemplate>
{
    Task<NotificationTemplate?> GetByCodeAsync(string templateCode, CancellationToken cancellationToken = default);
}
