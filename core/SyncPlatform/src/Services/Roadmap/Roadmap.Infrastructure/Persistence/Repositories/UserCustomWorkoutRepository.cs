using MongoDB.Driver;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;
using Libs.Shared.Enums;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace Roadmap.Infrastructure.Persistence.Repositories;

public class UserCustomWorkoutRepository : GenericRepository<UserCustomWorkout>, IUserCustomWorkoutRepository
{
    public UserCustomWorkoutRepository(IMongoDatabase database)
        : base(database, "UserCustomWorkouts") { }

    public async Task<IReadOnlyList<UserCustomWorkout>> GetByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
        => await Collection
            .Find(x => x.UserId == userId)
            .SortByDescending(x => x.CreatedAt)
            .ToListAsync(cancellationToken);

    public async Task<(IReadOnlyList<UserCustomWorkout> Items, int TotalCount)> GetPublicPagedAsync(
        int pageNumber,
        int pageSize,
        string? search = null,
        string? sortBy = null,
        CancellationToken cancellationToken = default)
    {
        var builder = Builders<UserCustomWorkout>.Filter;
        var filter = builder.Eq(x => x.Visibility, Visibility.Public);

        if (!string.IsNullOrWhiteSpace(search))
        {
            filter &= builder.Regex(x => x.WorkoutName, new MongoDB.Bson.BsonRegularExpression(search, "i"));
        }

        var query = Collection.Find(filter);

        if (string.Equals(sortBy, "saves", StringComparison.OrdinalIgnoreCase))
        {
            query = query.SortByDescending(x => x.SavesCount);
        }
        else
        {
            query = query.SortByDescending(x => x.CreatedAt);
        }

        var totalCount = (int)await Collection.CountDocumentsAsync(filter, cancellationToken: cancellationToken);
        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(cancellationToken);

        return (items, totalCount);
    }
}

