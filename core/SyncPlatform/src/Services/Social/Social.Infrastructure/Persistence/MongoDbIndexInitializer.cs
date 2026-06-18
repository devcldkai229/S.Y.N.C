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
        await ConfigureChallengeParticipantIndexesAsync(database);
        await ConfigureUserFollowIndexesAsync(database);
        await ConfigureStoryIndexesAsync(database);
        await ConfigureBlogIndexesAsync(database);
        await ConfigureBlogInteractionIndexesAsync(database);
        await ConfigureUserSocialSettingsIndexesAsync(database);
        await ConfigureStoryInteractionIndexesAsync(database);
        await ConfigureStoryViewIndexesAsync(database);
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

        var contentTextIndex = new CreateIndexModel<Post>(
            ix.Text(x => x.Content),
            new CreateIndexOptions { Name = "IX_Content_Text" });

        await collection.Indexes.CreateOneAsync(contentTextIndex);
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

        var locationIndex = new CreateIndexModel<CommunityChallenge>(
            Builders<CommunityChallenge>.IndexKeys.Geo2DSphere(x => x.Location),
            new CreateIndexOptions<CommunityChallenge>
            {
                Name = "IX_Location_2dsphere",
                PartialFilterExpression = Builders<CommunityChallenge>.Filter.Exists(x => x.Location, true),
            });

        await collection.Indexes.CreateManyAsync([statusDatesIndex, creatorIndex, locationIndex]);
    }

    private static async Task ConfigureChallengeParticipantIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<ChallengeParticipant>("ChallengeParticipants");
        var ix = Builders<ChallengeParticipant>.IndexKeys;

        var uniqueJoin = new CreateIndexModel<ChallengeParticipant>(
            ix.Ascending(x => x.ChallengeId).Ascending(x => x.UserId),
            new CreateIndexOptions { Unique = true, Name = "UIX_ChallengeId_UserId" });

        var challengeIndex = new CreateIndexModel<ChallengeParticipant>(
            ix.Ascending(x => x.ChallengeId).Ascending(x => x.Status),
            new CreateIndexOptions { Name = "IX_ChallengeId_Status" });

        var userActiveIndex = new CreateIndexModel<ChallengeParticipant>(
            ix.Ascending(x => x.UserId).Ascending(x => x.IsActive).Descending(x => x.JoinedAt),
            new CreateIndexOptions { Name = "IX_UserId_IsActive_JoinedAt_Desc" });

        await collection.Indexes.CreateManyAsync([uniqueJoin, challengeIndex, userActiveIndex]);
    }

    private static async Task ConfigureUserFollowIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<UserFollow>("UserFollows");
        var ix = Builders<UserFollow>.IndexKeys;

        var uniqueFollow = new CreateIndexModel<UserFollow>(
            ix.Ascending(x => x.FollowerId).Ascending(x => x.FolloweeId),
            new CreateIndexOptions { Unique = true, Name = "UIX_FollowerId_FolloweeId" });

        var followeeIndex = new CreateIndexModel<UserFollow>(
            ix.Ascending(x => x.FolloweeId).Ascending(x => x.Status),
            new CreateIndexOptions { Name = "IX_FolloweeId_Status" });

        var followerIndex = new CreateIndexModel<UserFollow>(
            ix.Ascending(x => x.FollowerId).Ascending(x => x.Status),
            new CreateIndexOptions { Name = "IX_FollowerId_Status" });

        await collection.Indexes.CreateManyAsync([uniqueFollow, followeeIndex, followerIndex]);
    }

    private static async Task ConfigureUserSocialSettingsIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<UserSocialSettings>("UserSocialSettings");

        var userIdIndex = new CreateIndexModel<UserSocialSettings>(
            Builders<UserSocialSettings>.IndexKeys.Ascending(x => x.UserId),
            new CreateIndexOptions { Unique = true, Name = "UIX_UserId" });

        await collection.Indexes.CreateManyAsync([userIdIndex]);
    }

    private static async Task ConfigureStoryIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<Story>("Stories");
        var ix = Builders<Story>.IndexKeys;

        var activeExpiryIndex = new CreateIndexModel<Story>(
            ix.Ascending(x => x.IsActive).Ascending(x => x.ExpiresAt),
            new CreateIndexOptions { Name = "IX_IsActive_ExpiresAt" });

        var authorIndex = new CreateIndexModel<Story>(
            ix.Ascending(x => x.AuthorId).Descending(x => x.CreatedAt),
            new CreateIndexOptions { Name = "IX_AuthorId_CreatedAt_Desc" });

        await collection.Indexes.CreateManyAsync([activeExpiryIndex, authorIndex]);
    }

    private static async Task ConfigureBlogIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<Blog>("Blogs");
        var ix = Builders<Blog>.IndexKeys;

        var slugIndex = new CreateIndexModel<Blog>(
            ix.Ascending(x => x.Slug),
            new CreateIndexOptions { Unique = true, Name = "UIX_Slug" });

        var statusPublishedIndex = new CreateIndexModel<Blog>(
            ix.Ascending(x => x.Status).Descending(x => x.PublishedAt),
            new CreateIndexOptions { Name = "IX_Status_PublishedAt_Desc" });

        var tagsIndex = new CreateIndexModel<Blog>(
            ix.Ascending(x => x.Tags),
            new CreateIndexOptions { Name = "IX_Tags" });

        var authorCreatedIndex = new CreateIndexModel<Blog>(
            ix.Ascending(x => x.AuthorId).Descending(x => x.CreatedAt),
            new CreateIndexOptions { Name = "IX_AuthorId_CreatedAt_Desc" });

        await collection.Indexes.CreateManyAsync([slugIndex, statusPublishedIndex, tagsIndex, authorCreatedIndex]);
    }

    private static async Task ConfigureBlogInteractionIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<BlogInteraction>("BlogInteractions");
        var ix = Builders<BlogInteraction>.IndexKeys;

        var uniqueInteraction = new CreateIndexModel<BlogInteraction>(
            ix.Ascending(x => x.BlogId).Ascending(x => x.UserId).Ascending(x => x.InteractionType),
            new CreateIndexOptions { Unique = true, Name = "UIX_BlogId_UserId_InteractionType" });

        await collection.Indexes.CreateManyAsync([uniqueInteraction]);
    }

    private static async Task ConfigureStoryInteractionIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<StoryInteraction>("StoryInteractions");
        var ix = Builders<StoryInteraction>.IndexKeys;

        var uniqueLike = new CreateIndexModel<StoryInteraction>(
            ix.Ascending(x => x.StoryId).Ascending(x => x.UserId).Ascending(x => x.InteractionType),
            new CreateIndexOptions { Unique = true, Name = "UIX_StoryId_UserId_InteractionType" });

        await collection.Indexes.CreateManyAsync([uniqueLike]);
    }

    private static async Task ConfigureStoryViewIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<StoryView>("StoryViews");
        var ix = Builders<StoryView>.IndexKeys;

        var uniqueView = new CreateIndexModel<StoryView>(
            ix.Ascending(x => x.StoryId).Ascending(x => x.ViewerId),
            new CreateIndexOptions { Unique = true, Name = "UIX_StoryId_ViewerId" });

        await collection.Indexes.CreateManyAsync([uniqueView]);
    }
}
