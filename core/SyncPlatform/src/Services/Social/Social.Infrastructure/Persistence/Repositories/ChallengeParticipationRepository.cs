using MongoDB.Driver;
using Social.Domain.Enums;
using Social.Domain.Exceptions;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class ChallengeParticipationRepository : IChallengeParticipationRepository
{
    private readonly IMongoClient _client;
    private readonly IMongoCollection<ChallengeParticipant> _participants;
    private readonly IMongoCollection<CommunityChallenge> _challenges;

    public ChallengeParticipationRepository(IMongoClient client, IMongoDatabase database)
    {
        _client = client;
        _participants = database.GetCollection<ChallengeParticipant>("ChallengeParticipants");
        _challenges = database.GetCollection<CommunityChallenge>("CommunityChallenges");
    }

    public async Task<ChallengeParticipant> JoinAsync(
        Guid challengeId,
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var existing = await _participants
            .Find(x => x.ChallengeId == challengeId && x.UserId == userId)
            .FirstOrDefaultAsync(cancellationToken);

        if (existing is not null)
        {
            if (existing.IsActive)
                throw new DuplicateChallengeJoinException(challengeId, userId);

            return await ReactivateJoinAsync(existing, challengeId, cancellationToken);
        }

        var participant = new ChallengeParticipant
        {
            ChallengeId = challengeId,
            UserId = userId,
            Status = ParticipantStatus.Joined,
            JoinedAt = DateTimeOffset.UtcNow,
            IsActive = true,
        };

        try
        {
            return await JoinInTransactionAsync(participant, challengeId, cancellationToken);
        }
        catch (NotSupportedException)
        {
            return await JoinSequentiallyAsync(participant, challengeId, userId, cancellationToken);
        }
        catch (MongoCommandException ex) when (IsTransactionNotSupported(ex))
        {
            return await JoinSequentiallyAsync(participant, challengeId, userId, cancellationToken);
        }
    }

    public async Task<ChallengeParticipant> LeaveAsync(
        Guid challengeId,
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        try
        {
            return await LeaveInTransactionAsync(challengeId, userId, cancellationToken);
        }
        catch (NotSupportedException)
        {
            return await LeaveSequentiallyAsync(challengeId, userId, cancellationToken);
        }
        catch (MongoCommandException ex) when (IsTransactionNotSupported(ex))
        {
            return await LeaveSequentiallyAsync(challengeId, userId, cancellationToken);
        }
    }

    private async Task<ChallengeParticipant> ReactivateJoinAsync(
        ChallengeParticipant existing,
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        var update = Builders<ChallengeParticipant>.Update
            .Set(x => x.IsActive, true)
            .Set(x => x.Status, ParticipantStatus.Joined)
            .Set(x => x.JoinedAt, now)
            .Set(x => x.CompletedAt, null)
            .Set(x => x.UpdatedAt, now);

        var result = await _participants.UpdateOneAsync(
            x => x.Id == existing.Id && !x.IsActive,
            update,
            cancellationToken: cancellationToken);

        if (result.ModifiedCount == 0)
            throw new DuplicateChallengeJoinException(challengeId, existing.UserId);

        await IncrementParticipantCountAsync(challengeId, cancellationToken);

        existing.IsActive = true;
        existing.Status = ParticipantStatus.Joined;
        existing.JoinedAt = now;
        existing.CompletedAt = null;
        existing.UpdatedAt = now;
        return existing;
    }

    private async Task<ChallengeParticipant> JoinInTransactionAsync(
        ChallengeParticipant participant,
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        participant.CreatedAt = DateTimeOffset.UtcNow;

        using var session = await _client.StartSessionAsync(cancellationToken: cancellationToken);
        session.StartTransaction();

        try
        {
            await _participants.InsertOneAsync(session, participant, cancellationToken: cancellationToken);
            await IncrementParticipantCountInSessionAsync(session, challengeId, cancellationToken);
            await session.CommitTransactionAsync(cancellationToken);
            return participant;
        }
        catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
        {
            await session.AbortTransactionAsync(cancellationToken);
            throw new DuplicateChallengeJoinException(challengeId, participant.UserId);
        }
        catch
        {
            await session.AbortTransactionAsync(cancellationToken);
            throw;
        }
    }

    private async Task<ChallengeParticipant> JoinSequentiallyAsync(
        ChallengeParticipant participant,
        Guid challengeId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        participant.CreatedAt = DateTimeOffset.UtcNow;

        try
        {
            await _participants.InsertOneAsync(participant, cancellationToken: cancellationToken);
        }
        catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
        {
            throw new DuplicateChallengeJoinException(challengeId, userId);
        }

        var updated = await IncrementParticipantCountAsync(challengeId, cancellationToken);
        if (!updated)
        {
            await _participants.DeleteOneAsync(x => x.Id == participant.Id, cancellationToken);
            throw new InvalidOperationException($"Challenge {challengeId} was not found.");
        }

        return participant;
    }

    private async Task<ChallengeParticipant> LeaveInTransactionAsync(
        Guid challengeId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        using var session = await _client.StartSessionAsync(cancellationToken: cancellationToken);
        session.StartTransaction();

        try
        {
            var participant = await LeaveParticipantAsync(session, challengeId, userId, cancellationToken);
            await DecrementParticipantCountInSessionAsync(session, challengeId, cancellationToken);
            await session.CommitTransactionAsync(cancellationToken);
            return participant;
        }
        catch
        {
            await session.AbortTransactionAsync(cancellationToken);
            throw;
        }
    }

    private async Task<ChallengeParticipant> LeaveSequentiallyAsync(
        Guid challengeId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        var participant = await LeaveParticipantAsync(null, challengeId, userId, cancellationToken);
        await DecrementParticipantCountAsync(challengeId, cancellationToken);
        return participant;
    }

    private async Task<ChallengeParticipant> LeaveParticipantAsync(
        IClientSessionHandle? session,
        Guid challengeId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        ChallengeParticipant? participant;
        if (session is null)
        {
            participant = await _participants
                .Find(x => x.ChallengeId == challengeId && x.UserId == userId && x.IsActive)
                .FirstOrDefaultAsync(cancellationToken);
        }
        else
        {
            participant = await _participants
                .Find(session, x => x.ChallengeId == challengeId && x.UserId == userId && x.IsActive)
                .FirstOrDefaultAsync(cancellationToken);
        }

        if (participant is null)
            throw new InvalidOperationException($"Active participation for challenge {challengeId} was not found.");

        var update = Builders<ChallengeParticipant>.Update
            .Set(x => x.IsActive, false)
            .Set(x => x.Status, ParticipantStatus.Dropped)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        UpdateResult result;
        if (session is null)
        {
            result = await _participants.UpdateOneAsync(
                x => x.Id == participant.Id && x.IsActive,
                update,
                cancellationToken: cancellationToken);
        }
        else
        {
            result = await _participants.UpdateOneAsync(
                session,
                x => x.Id == participant.Id && x.IsActive,
                update,
                cancellationToken: cancellationToken);
        }

        if (result.ModifiedCount == 0)
            throw new InvalidOperationException($"Active participation for challenge {challengeId} was not found.");

        participant.IsActive = false;
        participant.Status = ParticipantStatus.Dropped;
        return participant;
    }

    private async Task<bool> IncrementParticipantCountAsync(
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        var update = Builders<CommunityChallenge>.Update
            .Inc(x => x.ParticipantCount, 1)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        var result = await _challenges.UpdateOneAsync(
            x => x.Id == challengeId,
            update,
            cancellationToken: cancellationToken);

        return result.MatchedCount > 0;
    }

    private async Task DecrementParticipantCountAsync(
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        var update = Builders<CommunityChallenge>.Update
            .Inc(x => x.ParticipantCount, -1)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        await _challenges.UpdateOneAsync(
            x => x.Id == challengeId && x.ParticipantCount > 0,
            update,
            cancellationToken: cancellationToken);
    }

    private async Task IncrementParticipantCountInSessionAsync(
        IClientSessionHandle session,
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        var update = Builders<CommunityChallenge>.Update
            .Inc(x => x.ParticipantCount, 1)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        var result = await _challenges.UpdateOneAsync(
            session,
            x => x.Id == challengeId,
            update,
            cancellationToken: cancellationToken);

        if (result.MatchedCount == 0)
            throw new InvalidOperationException($"Challenge {challengeId} was not found.");
    }

    private async Task DecrementParticipantCountInSessionAsync(
        IClientSessionHandle session,
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        var update = Builders<CommunityChallenge>.Update
            .Inc(x => x.ParticipantCount, -1)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        await _challenges.UpdateOneAsync(
            session,
            x => x.Id == challengeId && x.ParticipantCount > 0,
            update,
            cancellationToken: cancellationToken);
    }

    private static bool IsTransactionNotSupported(MongoCommandException ex) =>
        ex.Message.Contains("replica set", StringComparison.OrdinalIgnoreCase)
        || ex.Message.Contains("mongos", StringComparison.OrdinalIgnoreCase);
}
