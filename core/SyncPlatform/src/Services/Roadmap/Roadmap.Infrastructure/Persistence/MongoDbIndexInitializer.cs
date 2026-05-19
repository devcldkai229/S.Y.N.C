using MongoDB.Driver;
using Roadmap.Domain.Models;

namespace Roadmap.Infrastructure.Persistence;

/// <summary>
/// Khởi tạo tất cả indexes cho Roadmap service.
/// Được gọi một lần khi app startup — idempotent, an toàn trên mọi lần deploy.
/// </summary>
public static class MongoDbIndexInitializer
{
    public static async Task InitializeAsync(IMongoDatabase database)
    {
        await ConfigurePersonalizedRoadmapIndexesAsync(database);
        await ConfigureRoadmapSessionIndexesAsync(database);
        await ConfigureScheduledWorkoutIndexesAsync(database);
        await ConfigureWorkoutExecutionLogIndexesAsync(database);
        await ConfigureUserCustomWorkoutIndexesAsync(database);
        await ConfigureRecoveryProfileIndexesAsync(database);
    }

    private static async Task ConfigurePersonalizedRoadmapIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<PersonalizedRoadmap>("PersonalizedRoadmaps");
        var ix = Builders<PersonalizedRoadmap>.IndexKeys;

        // Mỗi user chỉ có 1 roadmap active duy nhất
        var userIdIndex = new CreateIndexModel<PersonalizedRoadmap>(
            ix.Ascending(x => x.UserId),
            new CreateIndexOptions { Unique = true, Name = "UIX_UserId" });

        var userStatusIndex = new CreateIndexModel<PersonalizedRoadmap>(
            ix.Ascending(x => x.UserId).Ascending(x => x.RoadmapStatus),
            new CreateIndexOptions { Name = "IX_UserId_Status" });

        await collection.Indexes.CreateManyAsync([userIdIndex, userStatusIndex]);
    }

    private static async Task ConfigureRoadmapSessionIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<RoadmapSession>("RoadmapSessions");
        var ix = Builders<RoadmapSession>.IndexKeys;

        // Lấy tất cả sessions của một roadmap theo thứ tự ngày lịch
        var roadmapDateIndex = new CreateIndexModel<RoadmapSession>(
            ix.Ascending(x => x.RoadmapId).Ascending(x => x.ScheduledDate),
            new CreateIndexOptions { Name = "IX_RoadmapId_ScheduledDate" });

        // Lọc sessions theo trạng thái (Pending, Completed, Skipped...)
        var statusIndex = new CreateIndexModel<RoadmapSession>(
            ix.Ascending(x => x.SessionStatus),
            new CreateIndexOptions { Name = "IX_SessionStatus" });

        await collection.Indexes.CreateManyAsync([roadmapDateIndex, statusIndex]);
    }

    private static async Task ConfigureScheduledWorkoutIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<ScheduledWorkout>("ScheduledWorkouts");
        var ix = Builders<ScheduledWorkout>.IndexKeys;

        // Calendar view: tất cả workout đã lên lịch của user theo thời gian
        var userTimeIndex = new CreateIndexModel<ScheduledWorkout>(
            ix.Ascending(x => x.UserId).Ascending(x => x.ScheduledStartTime),
            new CreateIndexOptions { Name = "IX_UserId_ScheduledStartTime" });

        // Lookup ngược: session → scheduled workouts
        var sessionIndex = new CreateIndexModel<ScheduledWorkout>(
            ix.Ascending(x => x.SessionId),
            new CreateIndexOptions { Name = "IX_SessionId" });

        await collection.Indexes.CreateManyAsync([userTimeIndex, sessionIndex]);
    }

    private static async Task ConfigureWorkoutExecutionLogIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<WorkoutExecutionLog>("WorkoutExecutionLogs");
        var ix = Builders<WorkoutExecutionLog>.IndexKeys;

        // History view: toàn bộ lịch sử tập luyện của user, mới nhất trước
        var userHistoryIndex = new CreateIndexModel<WorkoutExecutionLog>(
            ix.Ascending(x => x.UserId).Descending(x => x.StartedAt),
            new CreateIndexOptions { Name = "IX_UserId_StartedAt_Desc" });

        // Lookup: tìm execution log của một session cụ thể
        var sessionIndex = new CreateIndexModel<WorkoutExecutionLog>(
            ix.Ascending(x => x.SessionId),
            new CreateIndexOptions { Name = "IX_SessionId" });

        await collection.Indexes.CreateManyAsync([userHistoryIndex, sessionIndex]);
    }

    private static async Task ConfigureUserCustomWorkoutIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<UserCustomWorkout>("UserCustomWorkouts");
        var ix = Builders<UserCustomWorkout>.IndexKeys;

        // Lấy tất cả custom workout của một user
        var userIndex = new CreateIndexModel<UserCustomWorkout>(
            ix.Ascending(x => x.UserId),
            new CreateIndexOptions { Name = "IX_UserId" });

        // Lọc theo visibility (Public/Private) — AI có thể recommend template public
        var userVisibilityIndex = new CreateIndexModel<UserCustomWorkout>(
            ix.Ascending(x => x.UserId).Ascending(x => x.Visibility),
            new CreateIndexOptions { Name = "IX_UserId_Visibility" });

        await collection.Indexes.CreateManyAsync([userIndex, userVisibilityIndex]);
    }

    private static async Task ConfigureRecoveryProfileIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<RecoveryProfile>("RecoveryProfiles");
        var ix = Builders<RecoveryProfile>.IndexKeys;

        var userIndex = new CreateIndexModel<RecoveryProfile>(
            ix.Ascending(x => x.UserId),
            new CreateIndexOptions { Unique = true, Name = "UIX_UserId" });

        await collection.Indexes.CreateOneAsync(userIndex);
    }
}
