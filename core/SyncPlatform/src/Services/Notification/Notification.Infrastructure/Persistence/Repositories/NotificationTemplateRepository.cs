using Notification.Domain.Models;
using Notification.Domain.Repositories;
using MongoDB.Driver;

namespace Notification.Infrastructure.Persistence.Repositories;

public class NotificationTemplateRepository : GenericRepository<NotificationTemplate>, INotificationTemplateRepository
{
    public NotificationTemplateRepository(IMongoDatabase database) : base(database, "NotificationTemplates")
    {
    }

    public async Task<NotificationTemplate?> GetByCodeAsync(string templateCode, CancellationToken cancellationToken = default)
    {
        return await Collection.Find(x => x.TemplateCode == templateCode).FirstOrDefaultAsync(cancellationToken);
    }
}
