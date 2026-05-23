using Libs.Shared.Enums;
using Roadmap.Domain.Models;

namespace Roadmap.Domain.Repositories;

public interface IRoadmapSessionRepository : IGenericRepository<RoadmapSession>
{
    Task<IReadOnlyList<RoadmapSession>> GetByRoadmapIdAsync(Guid roadmapId, CancellationToken cancellationToken = default);
    Task UpdateStatusAsync(Guid id, SessionStatus status, CancellationToken cancellationToken = default);
}
