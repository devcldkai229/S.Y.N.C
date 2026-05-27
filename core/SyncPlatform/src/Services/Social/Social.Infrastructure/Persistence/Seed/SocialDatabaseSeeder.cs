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

        await InsertMissingAsync(posts, SocialSeedData.GetPosts(utcNow), "posts", cancellationToken);

        await InsertMissingAsync(
            _database.GetCollection<Comment>("Comments"),
            SocialSeedData.GetComments(utcNow),
            "comments",
            cancellationToken);

        await InsertMissingInteractionsAsync(utcNow, cancellationToken);

        _logger.LogInformation(
            "Social seed completed. Demo user {DemoUserId} — feed, likes, comments ready.",
            SocialSeedUserIds.Demo);
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
}
