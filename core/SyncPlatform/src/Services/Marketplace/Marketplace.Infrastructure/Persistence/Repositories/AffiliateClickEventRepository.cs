using Marketplace.Domain.Models;
using Marketplace.Domain.Repositories;
using MongoDB.Driver;

namespace Marketplace.Infrastructure.Persistence.Repositories;

public class AffiliateClickEventRepository : GenericRepository<AffiliateClickEvent>, IAffiliateClickEventRepository
{
    public AffiliateClickEventRepository(IMongoDatabase database) : base(database, "AffiliateClickEvents")
    {
    }

    public async Task<AffiliateClickEvent?> GetByClickTokenAsync(string clickToken, CancellationToken cancellationToken = default)
    {
        return await Collection.Find(x => x.ClickToken == clickToken).FirstOrDefaultAsync(cancellationToken);
    }
}
