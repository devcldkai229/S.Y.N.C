using MongoDB.Driver;
using Social.Domain.Models;

namespace Social.Infrastructure.Persistence;

public sealed class SocialMongoContext
{
    private readonly IMongoDatabase _db;

    public SocialMongoContext(IMongoDatabase db) => _db = db;

    public IMongoCollection<Post> Posts => _db.GetCollection<Post>("Posts");

    public IMongoCollection<Interaction> Interactions => _db.GetCollection<Interaction>("Interactions");

    public IMongoCollection<Comment> Comments => _db.GetCollection<Comment>("Comments");

    public IMongoCollection<CommunityChallenge> CommunityChallenges =>
        _db.GetCollection<CommunityChallenge>("CommunityChallenges");
}
