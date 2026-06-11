using Marketplace.Domain.Common;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Models;

namespace Marketplace.Domain.Repositories;

public class PartnerWithDistance
{
    public Partner Partner { get; set; } = null!;

    public double? DistanceKm { get; set; }
}

public interface IPartnerRepository : IGenericRepository<Partner>
{
    Task<Partner?> GetByOwnerUserIdAsync(Guid ownerUserId, CancellationToken cancellationToken = default);

    Task<Partner?> GetBySlugAsync(string slug, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<PartnerWithDistance> Items, int TotalRecords)> SearchPagedAsync(
        PartnerSearchCriteria criteria,
        CancellationToken cancellationToken = default);

    Task UpdateStatusAsync(Guid id, PartnerStatus status, CancellationToken cancellationToken = default);

    Task UpdateRatingAsync(Guid id, decimal ratingAverage, int ratingCount, CancellationToken cancellationToken = default);
}
