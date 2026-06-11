using Marketplace.Domain.Models;
using MongoDB.Driver;

namespace Marketplace.Infrastructure.Persistence;

public static class MongoDbIndexInitializer
{
    public static async Task InitializeAsync(IMongoDatabase database)
    {
        await ConfigurePartnerIndexesAsync(database);
        await ConfigureFoodMenuItemIndexesAsync(database);
        await ConfigureAffiliateProductIndexesAsync(database);
        await ConfigureReviewIndexesAsync(database);
        await ConfigureAffiliateClickIndexesAsync(database);
    }

    private static async Task ConfigurePartnerIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<Partner>("Partners");
        var ix = Builders<Partner>.IndexKeys;

        await collection.Indexes.CreateManyAsync(
        [
            new CreateIndexModel<Partner>(ix.Ascending(x => x.Slug), new CreateIndexOptions { Unique = true, Name = "UIX_Slug" }),
            new CreateIndexModel<Partner>(ix.Ascending(x => x.OwnerUserId), new CreateIndexOptions { Unique = true, Name = "UIX_OwnerUserId" }),
            new CreateIndexModel<Partner>(ix.Ascending(x => x.Status).Ascending(x => x.Type), new CreateIndexOptions { Name = "IX_Status_Type" }),
            new CreateIndexModel<Partner>(ix.Geo2DSphere(x => x.Location), new CreateIndexOptions { Name = "GEO2D_Location" }),
        ]);
    }

    private static async Task ConfigureFoodMenuItemIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<FoodMenuItem>("FoodMenuItems");
        var ix = Builders<FoodMenuItem>.IndexKeys;

        await collection.Indexes.CreateManyAsync(
        [
            new CreateIndexModel<FoodMenuItem>(
                ix.Text(x => x.NameVi).Text(x => x.NameEn),
                new CreateIndexOptions { Name = "TXT_Search_Names" }),
            new CreateIndexModel<FoodMenuItem>(
                ix.Ascending(x => x.PartnerId).Ascending(x => x.Availability),
                new CreateIndexOptions { Name = "IX_Partner_Availability" }),
            new CreateIndexModel<FoodMenuItem>(
                ix.Ascending(x => x.Category).Ascending(x => x.Price),
                new CreateIndexOptions { Name = "IX_Category_Price" }),
        ]);
    }

    private static async Task ConfigureAffiliateProductIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<AffiliateProduct>("AffiliateProducts");
        var ix = Builders<AffiliateProduct>.IndexKeys;

        await collection.Indexes.CreateManyAsync(
        [
            new CreateIndexModel<AffiliateProduct>(ix.Ascending(x => x.Slug), new CreateIndexOptions { Unique = true, Name = "UIX_Slug" }),
            new CreateIndexModel<AffiliateProduct>(
                ix.Ascending(x => x.Category).Ascending(x => x.Availability),
                new CreateIndexOptions { Name = "IX_Category_Availability" }),
            new CreateIndexModel<AffiliateProduct>(
                ix.Ascending(x => x.PartnerId),
                new CreateIndexOptions { Name = "IX_PartnerId" }),
        ]);
    }

    private static async Task ConfigureReviewIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<Review>("Reviews");
        var ix = Builders<Review>.IndexKeys;

        await collection.Indexes.CreateManyAsync(
        [
            new CreateIndexModel<Review>(
                ix.Ascending(x => x.TargetType).Ascending(x => x.TargetId).Descending(x => x.CreatedAt),
                new CreateIndexOptions { Name = "IX_Target_CreatedAt" }),
            new CreateIndexModel<Review>(
                ix.Ascending(x => x.UserId).Ascending(x => x.TargetType).Ascending(x => x.TargetId).Ascending(x => x.OrderId),
                new CreateIndexOptions { Unique = true, Name = "UIX_User_Target_Order" }),
        ]);
    }

    private static async Task ConfigureAffiliateClickIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<AffiliateClickEvent>("AffiliateClickEvents");
        var ix = Builders<AffiliateClickEvent>.IndexKeys;

        await collection.Indexes.CreateManyAsync(
        [
            new CreateIndexModel<AffiliateClickEvent>(
                ix.Ascending(x => x.ClickToken),
                new CreateIndexOptions { Unique = true, Name = "UIX_ClickToken" }),
            new CreateIndexModel<AffiliateClickEvent>(
                ix.Ascending(x => x.AffiliateProductId).Descending(x => x.ClickedAt),
                new CreateIndexOptions { Name = "IX_Product_ClickedAt" }),
        ]);
    }
}
