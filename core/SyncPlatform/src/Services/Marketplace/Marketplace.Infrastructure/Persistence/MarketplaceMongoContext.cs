using Marketplace.Domain.Models;
using MongoDB.Driver;

namespace Marketplace.Infrastructure.Persistence;

public sealed class MarketplaceMongoContext
{
    private readonly IMongoDatabase _db;

    public MarketplaceMongoContext(IMongoDatabase db) => _db = db;

    public IMongoCollection<Partner> Partners => _db.GetCollection<Partner>("Partners");

    public IMongoCollection<FoodMenuItem> FoodMenuItems => _db.GetCollection<FoodMenuItem>("FoodMenuItems");

    public IMongoCollection<AffiliateProduct> AffiliateProducts =>
        _db.GetCollection<AffiliateProduct>("AffiliateProducts");

    public IMongoCollection<AffiliateClickEvent> AffiliateClickEvents =>
        _db.GetCollection<AffiliateClickEvent>("AffiliateClickEvents");

    public IMongoCollection<Review> Reviews => _db.GetCollection<Review>("Reviews");
}
