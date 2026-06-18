using Libs.Shared.Seed;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MongoDB.Driver;
using Social.Domain.Models;
using Social.Infrastructure.Options;

namespace Social.Infrastructure.Persistence.Seed;

public class SocialDatabaseSeeder : ISocialDatabaseSeeder
{
    private readonly IMongoDatabase _database;
    private readonly SocialSeedOptions _options;
    private readonly ILogger<SocialDatabaseSeeder> _logger;

    public SocialDatabaseSeeder(
        IMongoDatabase database,
        IOptions<SocialSeedOptions> options,
        ILogger<SocialDatabaseSeeder> logger)
    {
        _database = database;
        _options = options.Value;
        _logger = logger;
    }

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        if (!_options.Enabled)
        {
            _logger.LogInformation("Social database seed is disabled (Social:Seed:Enabled = false).");
            return;
        }

        if (!_options.SeedDemoData)
        {
            _logger.LogInformation("Social demo seed is disabled (Social:Seed:SeedDemoData = false).");
            return;
        }

        await PatchLegacyCdnUrlsAsync(cancellationToken);
        await PatchChallengeBackgroundUrlsAsync(cancellationToken);

        var posts = _database.GetCollection<Post>("Posts");
        if (await posts.Find(x => x.Id == SocialSeedData.SeedMarkerPostId).AnyAsync(cancellationToken))
        {
            _logger.LogInformation(
                "Social seed: demo feed already present (marker post {PostId}).",
                SocialSeedData.SeedMarkerPostId);
            return;
        }

        var utcNow = DateTimeOffset.UtcNow;

        await InsertMissingAsync(
            _database.GetCollection<CommunityChallenge>("CommunityChallenges"),
            SocialSeedData.GetCommunityChallenges(utcNow),
            "community challenges",
            cancellationToken);

        await InsertMissingAsync(
            _database.GetCollection<ChallengeParticipant>("ChallengeParticipants"),
            SocialSeedData.GetSeedChallengeParticipants(utcNow),
            "challenge participants",
            cancellationToken);

        await InsertMissingAsync(posts, SocialSeedData.GetPosts(utcNow), "posts", cancellationToken);

        await InsertMissingAsync(
            _database.GetCollection<Story>("Stories"),
            SocialSeedData.GetSeedStories(utcNow),
            "stories",
            cancellationToken);

        await InsertMissingAsync(
            _database.GetCollection<Blog>("Blogs"),
            SocialSeedData.GetSeedBlogs(utcNow),
            "blogs",
            cancellationToken);

        await InsertMissingAsync(
            _database.GetCollection<UserFollow>("UserFollows"),
            SocialSeedData.GetSeedUserFollows(utcNow),
            "user follows",
            cancellationToken);

        await InsertMissingAsync(
            _database.GetCollection<Comment>("Comments"),
            SocialSeedData.GetComments(utcNow),
            "comments",
            cancellationToken);

        await InsertMissingInteractionsAsync(utcNow, cancellationToken);

        _logger.LogInformation(
            "Social seed completed. Primary demo user {DemoUserId} — feed, stories, challenges, blogs ready.",
            SocialSeedUserIds.Beginner);
    }

    private async Task InsertMissingInteractionsAsync(DateTimeOffset utcNow, CancellationToken cancellationToken)
    {
        var collection = _database.GetCollection<Interaction>("Interactions");
        var seeds = SocialSeedData.GetInteractions(utcNow);
        var ids = seeds.Select(x => x.Id).ToList();

        var existingIds = await collection
            .Find(Builders<Interaction>.Filter.In(x => x.Id, ids))
            .Project(x => x.Id)
            .ToListAsync(cancellationToken);

        var toInsert = seeds.Where(s => !existingIds.Contains(s.Id)).ToList();
        if (toInsert.Count == 0)
        {
            _logger.LogInformation("Social seed: interactions already present.");
            return;
        }

        await collection.InsertManyAsync(toInsert, cancellationToken: cancellationToken);
        _logger.LogInformation("Social seed: inserted {Count} interactions.", toInsert.Count);
    }

    private async Task InsertMissingAsync<T>(
        IMongoCollection<T> collection,
        IReadOnlyList<T> seeds,
        string label,
        CancellationToken cancellationToken) where T : BaseMongoEntity
    {
        var ids = seeds.Select(x => x.Id).ToList();
        var existingIds = await collection
            .Find(Builders<T>.Filter.In(x => x.Id, ids))
            .Project(x => x.Id)
            .ToListAsync(cancellationToken);

        var toInsert = seeds.Where(s => !existingIds.Contains(s.Id)).ToList();
        if (toInsert.Count == 0)
        {
            _logger.LogInformation("Social seed: {Label} already present.", label);
            return;
        }

        var now = DateTimeOffset.UtcNow;
        foreach (var entity in toInsert)
        {
            if (entity.CreatedAt == default)
                entity.CreatedAt = now;
            entity.UpdatedAt = now;
        }

        await collection.InsertManyAsync(toInsert, cancellationToken: cancellationToken);
        _logger.LogInformation("Social seed: inserted {Count} {Label}.", toInsert.Count, label);
    }

    private async Task PatchLegacyCdnUrlsAsync(CancellationToken cancellationToken)
    {
        var posts = _database.GetCollection<Post>("Posts");
        var legacyFilter = Builders<Post>.Filter.Or(
            Builders<Post>.Filter.Regex(
                x => x.AuthorSnapshot.AvatarUrl,
                new MongoDB.Bson.BsonRegularExpression(DevSeedMediaUrls.LegacyCdnHost, "i")),
            Builders<Post>.Filter.Regex(
                "MediaUrls",
                new MongoDB.Bson.BsonRegularExpression(DevSeedMediaUrls.LegacyCdnHost, "i")));

        var legacyPosts = await posts.Find(legacyFilter).ToListAsync(cancellationToken);
        if (legacyPosts.Count == 0)
            return;

        foreach (var post in legacyPosts)
        {
            if (post.AuthorSnapshot is not null &&
                !string.IsNullOrWhiteSpace(post.AuthorSnapshot.AvatarUrl))
            {
                post.AuthorSnapshot.AvatarUrl =
                    DevSeedMediaUrls.MigrateLegacyUrl(post.AuthorSnapshot.AvatarUrl);
            }

            if (post.MediaUrls is { Count: > 0 })
            {
                post.MediaUrls = post.MediaUrls
                    .Select(DevSeedMediaUrls.MigrateLegacyUrl)
                    .ToList();
            }

            await posts.ReplaceOneAsync(
                Builders<Post>.Filter.Eq(x => x.Id, post.Id),
                post,
                cancellationToken: cancellationToken);
        }

        _logger.LogInformation("Social seed: migrated {Count} posts from legacy CDN URLs.", legacyPosts.Count);
    }

    private async Task PatchChallengeBackgroundUrlsAsync(CancellationToken cancellationToken)
    {
        var collection = _database.GetCollection<CommunityChallenge>("CommunityChallenges");
        var patched = 0;

        foreach (var (id, backgroundUrl) in SocialSeedData.ChallengeBackgroundUrls)
        {
            var filter = Builders<CommunityChallenge>.Filter.And(
                Builders<CommunityChallenge>.Filter.Eq(x => x.Id, id),
                Builders<CommunityChallenge>.Filter.Or(
                    Builders<CommunityChallenge>.Filter.Exists(x => x.BackgroundUrl, false),
                    Builders<CommunityChallenge>.Filter.Eq(x => x.BackgroundUrl, null),
                    Builders<CommunityChallenge>.Filter.Eq(x => x.BackgroundUrl, string.Empty)));

            var update = Builders<CommunityChallenge>.Update
                .Set(x => x.BackgroundUrl, backgroundUrl)
                .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

            var result = await collection.UpdateOneAsync(filter, update, cancellationToken: cancellationToken);
            if (result.ModifiedCount > 0)
                patched++;
        }

        if (patched > 0)
            _logger.LogInformation("Social seed: patched BackgroundUrl on {Count} community challenges.", patched);
    }
}
