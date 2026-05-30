using MongoDB.Driver;
using Social.Domain.Enums;
using Social.Domain.Exceptions;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class PostEngagementRepository : IPostEngagementRepository
{
    private readonly IMongoClient _client;
    private readonly IMongoCollection<Post> _posts;
    private readonly IMongoCollection<Interaction> _interactions;
    private readonly IMongoCollection<Comment> _comments;

    public PostEngagementRepository(IMongoClient client, IMongoDatabase database)
    {
        _client = client;
        _posts = database.GetCollection<Post>("Posts");
        _interactions = database.GetCollection<Interaction>("Interactions");
        _comments = database.GetCollection<Comment>("Comments");
    }

    public async Task<Interaction> LikePostAsync(
        Guid postId,
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var existing = await _interactions
            .Find(x => x.PostId == postId && x.UserId == userId && x.InteractionType == InteractionType.Like)
            .FirstOrDefaultAsync(cancellationToken);

        if (existing is not null)
            throw new DuplicateLikeException(postId, userId);

        var interaction = new Interaction
        {
            PostId = postId,
            UserId = userId,
            InteractionType = InteractionType.Like,
            CreatedAt = DateTimeOffset.UtcNow,
        };

        try
        {
            return await LikePostInTransactionAsync(interaction, postId, cancellationToken);
        }
        catch (NotSupportedException)
        {
            return await LikePostSequentiallyAsync(interaction, postId, userId, cancellationToken);
        }
        catch (MongoCommandException ex) when (IsTransactionNotSupported(ex))
        {
            return await LikePostSequentiallyAsync(interaction, postId, userId, cancellationToken);
        }
    }

    public async Task UnlikePostAsync(
        Guid postId,
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var result = await _interactions.DeleteOneAsync(
            x => x.PostId == postId && x.UserId == userId && x.InteractionType == InteractionType.Like,
            cancellationToken);

        if (result.DeletedCount == 0)
            return; // Already unliked — idempotent

        await _posts.UpdateOneAsync(
            p => p.Id == postId,
            Builders<Post>.Update.Inc(p => p.Metrics.LikeCount, -1),
            cancellationToken: cancellationToken);
    }

    public async Task<HashSet<Guid>> GetLikedPostIdsAsync(
        Guid userId,
        IEnumerable<Guid> postIds,
        CancellationToken cancellationToken = default)
    {
        var postIdList = postIds.ToList();
        if (postIdList.Count == 0) return [];

        var interactions = await _interactions
            .Find(x => x.UserId == userId && postIdList.Contains(x.PostId) && x.InteractionType == InteractionType.Like)
            .ToListAsync(cancellationToken);

        return [.. interactions.Select(x => x.PostId)];
    }

    public async Task<Comment> AddCommentAsync(
        Guid postId,
        Guid userId,
        string content,
        AuthorSnapshot? authorSnapshot,
        CancellationToken cancellationToken = default)
    {
        var comment = new Comment
        {
            PostId = postId,
            UserId = userId,
            Content = content,
            AuthorSnapshot = authorSnapshot,
            CreatedAt = DateTimeOffset.UtcNow,
        };

        try
        {
            return await AddCommentInTransactionAsync(comment, postId, cancellationToken);
        }
        catch (NotSupportedException)
        {
            return await AddCommentSequentiallyAsync(comment, postId, cancellationToken);
        }
        catch (MongoCommandException ex) when (IsTransactionNotSupported(ex))
        {
            return await AddCommentSequentiallyAsync(comment, postId, cancellationToken);
        }
    }

    private async Task<Interaction> LikePostInTransactionAsync(
        Interaction interaction,
        Guid postId,
        CancellationToken cancellationToken)
    {
        using var session = await _client.StartSessionAsync(cancellationToken: cancellationToken);
        session.StartTransaction();

        try
        {
            await _interactions.InsertOneAsync(session, interaction, cancellationToken: cancellationToken);
            await IncrementPostMetricInSessionAsync(session, postId, likeDelta: 1, commentDelta: 0, cancellationToken);
            await session.CommitTransactionAsync(cancellationToken);
            return interaction;
        }
        catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
        {
            await session.AbortTransactionAsync(cancellationToken);
            throw new DuplicateLikeException(postId, interaction.UserId);
        }
        catch
        {
            await session.AbortTransactionAsync(cancellationToken);
            throw;
        }
    }

    private async Task<Interaction> LikePostSequentiallyAsync(
        Interaction interaction,
        Guid postId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        try
        {
            await _interactions.InsertOneAsync(interaction, cancellationToken: cancellationToken);
        }
        catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
        {
            throw new DuplicateLikeException(postId, userId);
        }

        var updateResult = await _posts.UpdateOneAsync(
            p => p.Id == postId,
            Builders<Post>.Update.Inc(p => p.Metrics.LikeCount, 1),
            cancellationToken: cancellationToken);

        if (updateResult.MatchedCount == 0)
        {
            await _interactions.DeleteOneAsync(x => x.Id == interaction.Id, cancellationToken);
            throw new InvalidOperationException($"Post {postId} was not found.");
        }

        return interaction;
    }

    private async Task<Comment> AddCommentInTransactionAsync(
        Comment comment,
        Guid postId,
        CancellationToken cancellationToken)
    {
        using var session = await _client.StartSessionAsync(cancellationToken: cancellationToken);
        session.StartTransaction();

        try
        {
            await _comments.InsertOneAsync(session, comment, cancellationToken: cancellationToken);
            await IncrementPostMetricInSessionAsync(session, postId, likeDelta: 0, commentDelta: 1, cancellationToken);
            await session.CommitTransactionAsync(cancellationToken);
            return comment;
        }
        catch
        {
            await session.AbortTransactionAsync(cancellationToken);
            throw;
        }
    }

    private async Task<Comment> AddCommentSequentiallyAsync(
        Comment comment,
        Guid postId,
        CancellationToken cancellationToken)
    {
        await _comments.InsertOneAsync(comment, cancellationToken: cancellationToken);

        var updateResult = await _posts.UpdateOneAsync(
            p => p.Id == postId,
            Builders<Post>.Update.Inc(p => p.Metrics.CommentCount, 1),
            cancellationToken: cancellationToken);

        if (updateResult.MatchedCount == 0)
        {
            await _comments.DeleteOneAsync(x => x.Id == comment.Id, cancellationToken);
            throw new InvalidOperationException($"Post {postId} was not found.");
        }

        return comment;
    }

    private async Task IncrementPostMetricInSessionAsync(
        IClientSessionHandle session,
        Guid postId,
        int likeDelta,
        int commentDelta,
        CancellationToken cancellationToken)
    {
        var updates = new List<UpdateDefinition<Post>>();
        if (likeDelta != 0)
            updates.Add(Builders<Post>.Update.Inc(p => p.Metrics.LikeCount, likeDelta));
        if (commentDelta != 0)
            updates.Add(Builders<Post>.Update.Inc(p => p.Metrics.CommentCount, commentDelta));

        var combined = Builders<Post>.Update.Combine(updates);
        var updateResult = await _posts.UpdateOneAsync(session, p => p.Id == postId, combined, cancellationToken: cancellationToken);

        if (updateResult.MatchedCount == 0)
            throw new InvalidOperationException($"Post {postId} was not found.");
    }

    private static bool IsTransactionNotSupported(MongoCommandException ex) =>
        ex.Message.Contains("replica set", StringComparison.OrdinalIgnoreCase)
        || ex.Message.Contains("mongos", StringComparison.OrdinalIgnoreCase);
}
