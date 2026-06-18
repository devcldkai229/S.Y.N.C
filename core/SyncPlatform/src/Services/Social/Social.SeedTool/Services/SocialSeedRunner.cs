using Libs.Seed.Services;
using MongoDB.Driver;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Infrastructure.Persistence;
using Social.SeedTool.Models;
using Microsoft.Extensions.Logging;

namespace Social.SeedTool.Services;

public static class SocialSeedMapper
{
    public static string AvatarKey(Guid userId) => SeedImagePipeline.AvatarKey(userId);

    public static AuthorSnapshot BuildAuthorSnapshot(AuthorSnapshotSeedDto? snapshot, Guid userId)
    {
        return new AuthorSnapshot
        {
            FullName = snapshot?.FullName ?? string.Empty,
            AvatarUrl = AvatarKey(userId),
        };
    }

    public static Post MapPost(PostSeedDto dto) => new()
    {
        Id = dto.Id,
        CreatedAt = dto.CreatedAt,
        UpdatedAt = dto.UpdatedAt,
        AuthorId = dto.AuthorId,
        AuthorSnapshot = BuildAuthorSnapshot(dto.AuthorSnapshot, dto.AuthorId),
        PostType = ParseEnum<PostType>(dto.PostType),
        Content = dto.Content,
        MediaUrls = [],
        ReferenceId = dto.ReferenceId,
        Metrics = new PostMetrics
        {
            LikeCount = dto.Metrics.LikeCount,
            CommentCount = dto.Metrics.CommentCount,
            ShareCount = dto.Metrics.ShareCount,
        },
        IsPublic = dto.IsPublic,
        ShareCode = dto.ShareCode,
    };

    public static Comment MapComment(CommentSeedDto dto) => new()
    {
        Id = dto.Id,
        CreatedAt = dto.CreatedAt,
        UpdatedAt = dto.UpdatedAt,
        PostId = dto.PostId,
        UserId = dto.UserId,
        Content = dto.Content,
        AuthorSnapshot = dto.AuthorSnapshot is null
            ? null
            : BuildAuthorSnapshot(dto.AuthorSnapshot, dto.UserId),
        ParentCommentId = dto.ParentCommentId,
    };

    public static Interaction MapInteraction(InteractionSeedDto dto) => new()
    {
        Id = dto.Id,
        CreatedAt = dto.CreatedAt,
        UpdatedAt = dto.UpdatedAt,
        PostId = dto.PostId,
        UserId = dto.UserId,
        InteractionType = ParseEnum<InteractionType>(dto.InteractionType),
    };

    public static UserFollow MapUserFollow(UserFollowSeedDto dto) => new()
    {
        Id = dto.Id,
        CreatedAt = dto.CreatedAt,
        UpdatedAt = dto.UpdatedAt,
        FollowerId = dto.FollowerId,
        FolloweeId = dto.FolloweeId,
        FollowedAt = dto.FollowedAt,
        Status = ParseEnum<FollowStatus>(dto.Status),
    };

    private static TEnum ParseEnum<TEnum>(string value) where TEnum : struct, Enum
    {
        if (Enum.TryParse<TEnum>(value, ignoreCase: true, out var parsed))
            return parsed;

        throw new ArgumentException($"Unknown {typeof(TEnum).Name} value: '{value}'");
    }
}

public sealed class SocialSeedRunner
{
    private readonly SocialSeedReader _reader;
    private readonly SocialMongoContext _mongo;
    private readonly ILogger<SocialSeedRunner> _logger;

    public SocialSeedRunner(
        SocialSeedReader reader,
        SocialMongoContext mongo,
        ILogger<SocialSeedRunner> logger)
    {
        _reader = reader;
        _mongo = mongo;
        _logger = logger;
    }

    public async Task<SocialSeedReport> RunAsync(SocialSeedRunOptions options, CancellationToken cancellationToken = default)
    {
        var report = new SocialSeedReport();
        var seed = _reader.Read(options.SeedFilePath);

        var posts = options.Limit.HasValue ? seed.Posts.Take(options.Limit.Value).ToList() : seed.Posts;
        var postIds = posts.Select(p => p.Id).ToHashSet();

        _logger.LogInformation("Seeding {Posts} posts, filtering related data", posts.Count);

        report.PostsUpserted += await UpsertManyAsync(
            _mongo.Posts,
            posts.Select(SocialSeedMapper.MapPost),
            cancellationToken);

        var comments = seed.Comments.Where(c => postIds.Contains(c.PostId)).ToList();
        if (!options.Limit.HasValue)
            comments = seed.Comments;

        report.CommentsUpserted += await UpsertManyAsync(
            _mongo.Comments,
            comments.Select(SocialSeedMapper.MapComment),
            cancellationToken);

        var interactions = seed.Interactions.Where(i => postIds.Contains(i.PostId)).ToList();
        if (!options.Limit.HasValue)
            interactions = seed.Interactions;

        report.InteractionsUpserted += await UpsertManyAsync(
            _mongo.Interactions,
            interactions.Select(SocialSeedMapper.MapInteraction),
            cancellationToken);

        var follows = options.Limit.HasValue
            ? seed.UserFollows.Take(options.Limit.Value * 4).ToList()
            : seed.UserFollows;

        report.UserFollowsUpserted += await UpsertManyAsync(
            _mongo.UserFollows,
            follows.Select(SocialSeedMapper.MapUserFollow),
            cancellationToken);

        report.PrintSummary();
        return report;
    }

    private static async Task<int> UpsertManyAsync<T>(
        IMongoCollection<T> collection,
        IEnumerable<T> entities,
        CancellationToken cancellationToken) where T : BaseMongoEntity
    {
        var count = 0;
        foreach (var entity in entities)
        {
            var filter = Builders<T>.Filter.Eq(x => x.Id, entity.Id);
            await collection.ReplaceOneAsync(
                filter,
                entity,
                new ReplaceOptions { IsUpsert = true },
                cancellationToken);
            count++;
        }

        return count;
    }
}

public sealed class SocialSeedRunOptions
{
    public int? Limit { get; init; }

    public string? SeedFilePath { get; init; }
}

public sealed class SocialSeedReport
{
    public int PostsUpserted { get; set; }
    public int CommentsUpserted { get; set; }
    public int InteractionsUpserted { get; set; }
    public int UserFollowsUpserted { get; set; }
    public List<string> Errors { get; } = [];

    public void PrintSummary()
    {
        Console.WriteLine("=== Social Seed Report ===");
        Console.WriteLine($"Posts upserted: {PostsUpserted}");
        Console.WriteLine($"Comments upserted: {CommentsUpserted}");
        Console.WriteLine($"Interactions upserted: {InteractionsUpserted}");
        Console.WriteLine($"UserFollows upserted: {UserFollowsUpserted}");
    }
}
