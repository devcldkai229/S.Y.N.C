using MongoDB.Driver;
using MongoDB.Driver.GeoJsonObjectModel;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Persistence.Repositories;

public class CommunityChallengeRepository : GenericRepository<CommunityChallenge>, ICommunityChallengeRepository
{
    public CommunityChallengeRepository(IMongoDatabase database)
        : base(database, "CommunityChallenges")
    {
    }

    public async Task<(IReadOnlyList<CommunityChallenge> Items, int TotalRecords)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        ChallengeStatus? status,
        ChallengeGoalType? goalType,
        DateTimeOffset? startDateFrom,
        DateTimeOffset? startDateTo,
        DateTimeOffset? endDateFrom,
        DateTimeOffset? endDateTo,
        ChallengeStatus? requiredStatus = null,
        CancellationToken cancellationToken = default)
    {
        var filter = BuildListFilter(
            status,
            goalType,
            startDateFrom,
            startDateTo,
            endDateFrom,
            endDateTo,
            requiredStatus);

        var total = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);

        var items = await Collection.Find(filter)
            .SortByDescending(x => x.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task<(IReadOnlyList<CommunityChallenge> Items, int TotalRecords)> GetBrowsablePagedAsync(
        int pageNumber,
        int pageSize,
        ChallengeGoalType? goalType,
        DateTimeOffset? startDateFrom,
        DateTimeOffset? startDateTo,
        DateTimeOffset? endDateFrom,
        DateTimeOffset? endDateTo,
        CancellationToken cancellationToken = default)
    {
        var visibleStatuses = new[]
        {
            ChallengeStatus.Active,
            ChallengeStatus.Upcoming,
            ChallengeStatus.InProgress,
        };

        var filters = new List<FilterDefinition<CommunityChallenge>>
        {
            Builders<CommunityChallenge>.Filter.In(x => x.Status, visibleStatuses),
        };

        if (goalType.HasValue)
            filters.Add(Builders<CommunityChallenge>.Filter.Eq(x => x.GoalType, goalType.Value));

        if (startDateFrom.HasValue)
            filters.Add(Builders<CommunityChallenge>.Filter.Gte(x => x.StartDate, startDateFrom.Value));

        if (startDateTo.HasValue)
            filters.Add(Builders<CommunityChallenge>.Filter.Lte(x => x.StartDate, startDateTo.Value));

        if (endDateFrom.HasValue)
            filters.Add(Builders<CommunityChallenge>.Filter.Gte(x => x.EndDate, endDateFrom.Value));

        if (endDateTo.HasValue)
            filters.Add(Builders<CommunityChallenge>.Filter.Lte(x => x.EndDate, endDateTo.Value));

        var filter = Builders<CommunityChallenge>.Filter.And(filters);
        var total = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);

        var items = await Collection.Find(filter)
            .SortByDescending(x => x.StartDate)
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    public async Task<(IReadOnlyList<CommunityChallenge> Items, int TotalRecords)> GetNearbyActiveAsync(
        double latitude,
        double longitude,
        double radiusKm,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var point = new GeoJsonPoint<GeoJson2DGeographicCoordinates>(
            new GeoJson2DGeographicCoordinates(longitude, latitude));

        var maxDistanceMeters = radiusKm * 1000;

        var visibleStatuses = new[]
        {
            ChallengeStatus.Active,
            ChallengeStatus.Upcoming,
            ChallengeStatus.InProgress,
        };

        var filter = Builders<CommunityChallenge>.Filter.And(
            Builders<CommunityChallenge>.Filter.In(x => x.Status, visibleStatuses),
            Builders<CommunityChallenge>.Filter.NearSphere(
                x => x.Location,
                point,
                maxDistance: maxDistanceMeters));

        // CountDocuments + NearSphere is invalid in MongoDB; fetch then paginate in memory.
        var allNearby = await Collection.Find(filter).ToListAsync(cancellationToken);
        var total = allNearby.Count;
        var items = allNearby
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return (items, total);
    }

    public async Task RefreshStatusAsync(
        Guid id,
        ChallengeStatus status,
        CancellationToken cancellationToken = default)
    {
        var update = Builders<CommunityChallenge>.Update
            .Set(x => x.Status, status)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        await Collection.UpdateOneAsync(x => x.Id == id, update, cancellationToken: cancellationToken);
    }

    public async Task<bool> IncrementParticipantCountAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var update = Builders<CommunityChallenge>.Update
            .Inc(x => x.ParticipantCount, 1)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        var result = await Collection.UpdateOneAsync(x => x.Id == id, update, cancellationToken: cancellationToken);
        return result.ModifiedCount > 0;
    }

    public async Task<bool> DecrementParticipantCountAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var update = Builders<CommunityChallenge>.Update
            .Inc(x => x.ParticipantCount, -1)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        var result = await Collection.UpdateOneAsync(
            x => x.Id == id && x.ParticipantCount > 0,
            update,
            cancellationToken: cancellationToken);

        return result.ModifiedCount > 0;
    }

    private static FilterDefinition<CommunityChallenge> BuildListFilter(
        ChallengeStatus? status,
        ChallengeGoalType? goalType,
        DateTimeOffset? startDateFrom,
        DateTimeOffset? startDateTo,
        DateTimeOffset? endDateFrom,
        DateTimeOffset? endDateTo,
        ChallengeStatus? requiredStatus)
    {
        var filters = new List<FilterDefinition<CommunityChallenge>>();

        if (requiredStatus.HasValue)
            filters.Add(Builders<CommunityChallenge>.Filter.Eq(x => x.Status, requiredStatus.Value));
        else if (status.HasValue)
            filters.Add(Builders<CommunityChallenge>.Filter.Eq(x => x.Status, status.Value));

        if (goalType.HasValue)
            filters.Add(Builders<CommunityChallenge>.Filter.Eq(x => x.GoalType, goalType.Value));

        if (startDateFrom.HasValue)
            filters.Add(Builders<CommunityChallenge>.Filter.Gte(x => x.StartDate, startDateFrom.Value));

        if (startDateTo.HasValue)
            filters.Add(Builders<CommunityChallenge>.Filter.Lte(x => x.StartDate, startDateTo.Value));

        if (endDateFrom.HasValue)
            filters.Add(Builders<CommunityChallenge>.Filter.Gte(x => x.EndDate, endDateFrom.Value));

        if (endDateTo.HasValue)
            filters.Add(Builders<CommunityChallenge>.Filter.Lte(x => x.EndDate, endDateTo.Value));

        return filters.Count == 0
            ? Builders<CommunityChallenge>.Filter.Empty
            : Builders<CommunityChallenge>.Filter.And(filters);
    }
}
