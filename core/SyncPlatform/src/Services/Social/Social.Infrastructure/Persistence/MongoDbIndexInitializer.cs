using MongoDB.Driver;
using Social.Domain.Models;

namespace Social.Infrastructure.Persistence;

public static class MongoDbIndexInitializer
{
    public static async Task InitializeAsync(IMongoDatabase database)
    {
        await ConfigurePostIndexesAsync(database);
        await ConfigureInteractionIndexesAsync(database);
        await ConfigureCommentIndexesAsync(database);
        await ConfigureCommunityChallengeIndexesAsync(database);
    }

    private static async Task ConfigurePostIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<Post>("Posts");
        var ix = Builders<Post>.IndexKeys;

        var feedIndex = new CreateIndexModel<Post>(
            ix.Ascending(x => x.IsPublic).Descending(x => x.CreatedAt),
            new CreateIndexOptions { Name = "IX_IsPublic_CreatedAt_Desc" });

        var authorIndex = new CreateIndexModel<Post>(
            ix.Ascending(x => x.AuthorId).Descending(x => x.CreatedAt),
            new CreateIndexOptions { Name = "IX_AuthorId_CreatedAt_Desc" });

        var typeIndex = new CreateIndexModel<Post>(
            ix.Ascending(x => x.PostType),
            new CreateIndexOptions { Name = "IX_PostType" });

        // Partial unique index: only non-empty ShareCode. $ne "" becomes $not (unsupported); $regex is also unsupported in partial indexes.
        // String order: any non-empty ShareCode satisfies ShareCode > "".
        var shareCodeIndex = new CreateIndexModel<Post>(
            ix.Ascending(x => x.ShareCode),
            new CreateIndexOptions<Post>
            {
                Unique = true,
                Name = "UIX_ShareCode",
                PartialFilterExpression = Builders<Post>.Filter.And(
                    Builders<Post>.Filter.Exists(x => x.ShareCode, true),
                    Builders<Post>.Filter.Gt(x => x.ShareCode, string.Empty)),
            });

        await collection.Indexes.CreateManyAsync([feedIndex, authorIndex, typeIndex, shareCodeIndex]);
    }

    private static async Task ConfigureInteractionIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<Interaction>("Interactions");
        var ix = Builders<Interaction>.IndexKeys;

        // One Like/Share per user per post — prevents fake engagement / spam.
        var uniqueInteraction = new CreateIndexModel<Interaction>(
            ix.Ascending(x => x.PostId).Ascending(x => x.UserId).Ascending(x => x.InteractionType),
            new CreateIndexOptions { Unique = true, Name = "UIX_PostId_UserId_InteractionType" });

        var postIndex = new CreateIndexModel<Interaction>(
            ix.Ascending(x => x.PostId).Descending(x => x.CreatedAt),
            new CreateIndexOptions { Name = "IX_PostId_CreatedAt_Desc" });

        await collection.Indexes.CreateManyAsync([uniqueInteraction, postIndex]);
    }

    private static async Task ConfigureCommentIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<Comment>("Comments");
        var ix = Builders<Comment>.IndexKeys;

        var postCreatedIndex = new CreateIndexModel<Comment>(
            ix.Ascending(x => x.PostId).Descending(x => x.CreatedAt),
            new CreateIndexOptions { Name = "IX_PostId_CreatedAt_Desc" });

        await collection.Indexes.CreateManyAsync([postCreatedIndex]);
    }

    private static async Task ConfigureCommunityChallengeIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<CommunityChallenge>("CommunityChallenges");
        var ix = Builders<CommunityChallenge>.IndexKeys;

        var statusDatesIndex = new CreateIndexModel<CommunityChallenge>(
            ix.Ascending(x => x.Status).Ascending(x => x.StartDate).Ascending(x => x.EndDate),
            new CreateIndexOptions { Name = "IX_Status_StartDate_EndDate" });

        var creatorIndex = new CreateIndexModel<CommunityChallenge>(
            ix.Ascending(x => x.CreatorId).Descending(x => x.CreatedAt),
            new CreateIndexOptions { Name = "IX_CreatorId_CreatedAt_Desc" });

        await collection.Indexes.CreateManyAsync([statusDatesIndex, creatorIndex]);
    }
}
