using Roadmap.Domain.Models;

namespace Roadmap.Domain.Repositories;

public interface IPersonalizedRoadmapRepository : IGenericRepository<PersonalizedRoadmap>
{
    Task<IReadOnlyList<PersonalizedRoadmap>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
}
