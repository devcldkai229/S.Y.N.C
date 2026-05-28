using MongoDB.Driver;
using Notification.Domain.Enums;
using Notification.Domain.Models;

namespace Notification.Infrastructure.Persistence.Seed;

public static class NotificationSeedData
{
    public static readonly Guid DemoUserId = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");

    public static List<NotificationMessage> GetDemoNotifications()
    {
        var now = DateTimeOffset.UtcNow;
        return
        [
            new NotificationMessage
            {
                Id = Guid.Parse("a1000001-0001-0001-0001-000000000001"),
                UserId = DemoUserId,
                Type = NotificationType.WorkoutReminder,
                Channel = NotificationChannel.InApp,
                Priority = NotificationPriority.Normal,
                Title = "Workout reminder",
                Body = "Your evening strength session starts in 30 minutes. Warm up and stay hydrated.",
                Status = NotificationStatus.Sent,
                SentAt = now.AddHours(-2),
                CreatedAt = now.AddHours(-2),
            },
            new NotificationMessage
            {
                Id = Guid.Parse("a1000002-0002-0002-0002-000000000002"),
                UserId = DemoUserId,
                Type = NotificationType.RewardMinted,
                Channel = NotificationChannel.InApp,
                Priority = NotificationPriority.Normal,
                Title = "Achievement unlocked",
                Body = "You earned the \"7-day streak\" badge. +150 Sync Coins added to your wallet.",
                Status = NotificationStatus.Sent,
                SentAt = now.AddHours(-5),
                CreatedAt = now.AddHours(-5),
            },
            new NotificationMessage
            {
                Id = Guid.Parse("a1000003-0003-0003-0003-000000000003"),
                UserId = DemoUserId,
                Type = NotificationType.AiIntervention,
                Channel = NotificationChannel.InApp,
                Priority = NotificationPriority.High,
                Title = "AI Coach insight",
                Body = "Recovery score is low today. Consider a mobility session instead of heavy legs.",
                Status = NotificationStatus.Delivered,
                SentAt = now.AddDays(-1),
                DeliveredAt = now.AddDays(-1),
                CreatedAt = now.AddDays(-1),
            },
            new NotificationMessage
            {
                Id = Guid.Parse("a1000004-0004-0004-0004-000000000004"),
                UserId = DemoUserId,
                Type = NotificationType.Motivational,
                Channel = NotificationChannel.InApp,
                Priority = NotificationPriority.Low,
                Title = "Keep the momentum",
                Body = "You completed 3 workouts this week. One more to hit your roadmap goal.",
                Status = NotificationStatus.Read,
                SentAt = now.AddDays(-2),
                ReadAt = now.AddDays(-1),
                CreatedAt = now.AddDays(-2),
            },
            new NotificationMessage
            {
                Id = Guid.Parse("a1000005-0005-0005-0005-000000000005"),
                UserId = DemoUserId,
                Type = NotificationType.SystemAlert,
                Channel = NotificationChannel.InApp,
                Priority = NotificationPriority.Normal,
                Title = "Profile updated",
                Body = "Your biometric targets were recalculated after the latest weight log.",
                Status = NotificationStatus.Read,
                SentAt = now.AddDays(-3),
                ReadAt = now.AddDays(-2),
                CreatedAt = now.AddDays(-3),
            },
            new NotificationMessage
            {
                Id = Guid.Parse("a1000006-0006-0006-0006-000000000006"),
                UserId = DemoUserId,
                Type = NotificationType.Promotion,
                Channel = NotificationChannel.InApp,
                Priority = NotificationPriority.Low,
                Title = "Community challenge",
                Body = "Join the 10K steps challenge — 48 hours left to register with your squad.",
                Status = NotificationStatus.Sent,
                SentAt = now.AddMinutes(-45),
                CreatedAt = now.AddMinutes(-45),
            },
        ];
    }

    public static class NotificationMongoSeeder
    {
        public static async Task SeedAsync(IMongoDatabase database)
        {
            var collection = database.GetCollection<NotificationMessage>("NotificationMessages");
            var hasDemo = await collection
                .Find(x => x.UserId == DemoUserId)
                .Limit(1)
                .AnyAsync();

            if (hasDemo)
                return;

            await collection.InsertManyAsync(GetDemoNotifications());
        }
    }
}
