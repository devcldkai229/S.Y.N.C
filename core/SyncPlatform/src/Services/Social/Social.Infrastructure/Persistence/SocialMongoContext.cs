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

    public IMongoCollection<ChallengeParticipant> ChallengeParticipants =>
        _db.GetCollection<ChallengeParticipant>("ChallengeParticipants");

    public IMongoCollection<UserFollow> UserFollows =>
        _db.GetCollection<UserFollow>("UserFollows");

    public IMongoCollection<Story> Stories =>
        _db.GetCollection<Story>("Stories");

    public IMongoCollection<Blog> Blogs =>
        _db.GetCollection<Blog>("Blogs");

    public IMongoCollection<UserSocialSettings> UserSocialSettings =>
        _db.GetCollection<UserSocialSettings>("UserSocialSettings");

    public IMongoCollection<StoryInteraction> StoryInteractions =>
        _db.GetCollection<StoryInteraction>("StoryInteractions");

    public IMongoCollection<StoryView> StoryViews =>
        _db.GetCollection<StoryView>("StoryViews");
}
