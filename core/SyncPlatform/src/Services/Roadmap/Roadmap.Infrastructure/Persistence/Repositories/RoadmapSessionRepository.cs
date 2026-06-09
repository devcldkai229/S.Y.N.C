using Libs.Shared.Enums;
using MongoDB.Driver;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Infrastructure.Persistence.Repositories;

public class RoadmapSessionRepository : GenericRepository<RoadmapSession>, IRoadmapSessionRepository
{
    public RoadmapSessionRepository(IMongoDatabase database)
        : base(database, "RoadmapSessions") { }

    public async Task<IReadOnlyList<RoadmapSession>> GetByRoadmapIdAsync(
        Guid roadmapId,
        CancellationToken cancellationToken = default)
        => await Collection
            .Find(x => x.RoadmapId == roadmapId)
            .SortBy(x => x.ScheduledDate)
            .ToListAsync(cancellationToken);

    public async Task UpdateStatusAsync(
        Guid id,
        SessionStatus status,
        CancellationToken cancellationToken = default)
    {
        var update = Builders<RoadmapSession>.Update
            .Set(x => x.SessionStatus, status)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);

        await Collection.UpdateOneAsync(x => x.Id == id, update, cancellationToken: cancellationToken);
    }
}
