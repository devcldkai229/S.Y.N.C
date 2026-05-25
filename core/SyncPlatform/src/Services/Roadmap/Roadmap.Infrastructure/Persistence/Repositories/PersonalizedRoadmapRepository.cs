using MongoDB.Driver;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Infrastructure.Persistence.Repositories;

public class PersonalizedRoadmapRepository : GenericRepository<PersonalizedRoadmap>, IPersonalizedRoadmapRepository
{
    public PersonalizedRoadmapRepository(IMongoDatabase database)
        : base(database, "PersonalizedRoadmaps") { }

    public async Task<IReadOnlyList<PersonalizedRoadmap>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await Collection
            .Find(x => x.UserId == userId)
            .SortByDescending(x => x.CreatedAt)
            .ToListAsync(cancellationToken);
    }
}
