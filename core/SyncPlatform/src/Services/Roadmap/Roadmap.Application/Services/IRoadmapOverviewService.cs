using Roadmap.Application.DTOs;

namespace Roadmap.Application.Services;

public interface IRoadmapOverviewService
{
    /// <summary>
    /// Aggregated mobile overview for the current user's active roadmap.
    /// Returns null when the user has no roadmap.
    /// </summary>
    Task<RoadmapOverviewDto?> GetMyOverviewAsync(
        Guid userId,
        string? experienceLevel = null,
        CancellationToken cancellationToken = default);
}
