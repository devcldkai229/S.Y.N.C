using Marketplace.Domain.Models;

namespace Marketplace.Domain.Repositories;

public interface IAffiliateClickEventRepository : IGenericRepository<AffiliateClickEvent>
{
    Task<AffiliateClickEvent?> GetByClickTokenAsync(string clickToken, CancellationToken cancellationToken = default);
}
