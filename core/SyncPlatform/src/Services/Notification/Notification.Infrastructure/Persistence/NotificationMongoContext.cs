using MongoDB.Driver;
using Notification.Domain.Models;

namespace Notification.Infrastructure.Persistence;

/// <summary>
/// Typed wrapper quanh IMongoDatabase — inject class này vào repositories.
/// </summary>
public sealed class NotificationMongoContext
{
    private readonly IMongoDatabase _db;

    public NotificationMongoContext(IMongoDatabase db) => _db = db;

    public IMongoCollection<NotificationMessage> NotificationMessages
        => _db.GetCollection<NotificationMessage>("NotificationMessages");

    public IMongoCollection<NotificationTemplate> NotificationTemplates
        => _db.GetCollection<NotificationTemplate>("NotificationTemplates");
}
