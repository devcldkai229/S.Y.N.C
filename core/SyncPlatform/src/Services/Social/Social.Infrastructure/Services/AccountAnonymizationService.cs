using MongoDB.Driver;
using Social.Application.Services;
using Social.Domain.Models;
using Social.Infrastructure.Persistence;

namespace Social.Infrastructure.Services;

public sealed class AccountAnonymizationService : IAccountAnonymizationService
{
    private const string AnonymizedName = "Người dùng đã xoá";

    private readonly SocialMongoContext _db;
    private readonly IMongoDatabase _database;

    public AccountAnonymizationService(SocialMongoContext db, IMongoDatabase database)
    {
        _db = db;
        _database = database;
    }

    public async Task AnonymizeUserContentAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var snapshot = new AuthorSnapshot
        {
            FullName = AnonymizedName,
            AvatarUrl = null,
        };
        var now = DateTimeOffset.UtcNow;

        await _db.Posts.UpdateManyAsync(
            Builders<Post>.Filter.Eq(p => p.AuthorId, userId),
            Builders<Post>.Update
                .Set(p => p.AuthorSnapshot, snapshot)
                .Set(p => p.UpdatedAt, now),
            cancellationToken: cancellationToken);

        await _db.Comments.UpdateManyAsync(
            Builders<Comment>.Filter.Eq(c => c.UserId, userId),
            Builders<Comment>.Update
                .Set(c => c.AuthorSnapshot, snapshot)
                .Set(c => c.UpdatedAt, now),
            cancellationToken: cancellationToken);

        await _db.Blogs.UpdateManyAsync(
            Builders<Blog>.Filter.Eq(b => b.AuthorId, userId),
            Builders<Blog>.Update
                .Set(b => b.AuthorSnapshot, snapshot)
                .Set(b => b.UpdatedAt, now),
            cancellationToken: cancellationToken);

        await _db.Stories.UpdateManyAsync(
            Builders<Story>.Filter.Eq(s => s.AuthorId, userId),
            Builders<Story>.Update
                .Set(s => s.AuthorSnapshot, snapshot)
                .Set(s => s.UpdatedAt, now),
            cancellationToken: cancellationToken);

        var blogComments = _database.GetCollection<BlogComment>("BlogComments");
        await blogComments.UpdateManyAsync(
            Builders<BlogComment>.Filter.Eq(c => c.UserId, userId),
            Builders<BlogComment>.Update
                .Set(c => c.AuthorSnapshot, snapshot)
                .Set(c => c.UpdatedAt, now),
            cancellationToken: cancellationToken);
    }
}
