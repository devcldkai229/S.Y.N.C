using MongoDB.Driver;
using Nutrition.Domain.Models;

namespace Nutrition.Infrastructure.Persistence;

public static class MongoDbIndexInitializer
{
    public static async Task InitializeAsync(IMongoDatabase database)
    {
        await ConfigureFoodItemIndexesAsync(database);
        await ConfigureMealLogIndexesAsync(database);
        await ConfigureDailySummaryIndexesAsync(database);
    }

    private static async Task ConfigureFoodItemIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<FoodItem>("FoodItems");
        var ix = Builders<FoodItem>.IndexKeys;

        await collection.Indexes.CreateManyAsync(
        [
            new CreateIndexModel<FoodItem>(ix.Ascending(x => x.Slug), new CreateIndexOptions { Unique = true, Name = "UIX_Slug" }),
            new CreateIndexModel<FoodItem>(
                ix.Text(x => x.NameVi).Text(x => x.NameEn),
                new CreateIndexOptions { Name = "TXT_Search_Names" }),
            new CreateIndexModel<FoodItem>(
                ix.Ascending(x => x.Category).Ascending(x => x.IsActive),
                new CreateIndexOptions { Name = "IX_Category_IsActive" }),
            new CreateIndexModel<FoodItem>(
                ix.Ascending(x => x.Barcode),
                new CreateIndexOptions<FoodItem>
                {
                    Name = "UIX_Barcode",
                    Unique = true,
                    PartialFilterExpression = Builders<FoodItem>.Filter.Exists(x => x.Barcode),
                }),
        ]);
    }

    private static async Task ConfigureMealLogIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<MealLog>("MealLogs");
        var ix = Builders<MealLog>.IndexKeys;

        await collection.Indexes.CreateManyAsync(
        [
            new CreateIndexModel<MealLog>(
                ix.Ascending(x => x.UserId).Descending(x => x.LoggedAt),
                new CreateIndexOptions { Name = "IX_UserId_LoggedAt" }),
            new CreateIndexModel<MealLog>(
                ix.Ascending(x => x.RelatedOrderId),
                new CreateIndexOptions<MealLog>
                {
                    Name = "UIX_RelatedOrderId",
                    Unique = true,
                    PartialFilterExpression = Builders<MealLog>.Filter.Exists(x => x.RelatedOrderId),
                }),
        ]);
    }

    private static async Task ConfigureDailySummaryIndexesAsync(IMongoDatabase database)
    {
        var collection = database.GetCollection<DailyNutritionSummary>("DailyNutritionSummaries");
        var ix = Builders<DailyNutritionSummary>.IndexKeys;

        await collection.Indexes.CreateOneAsync(new CreateIndexModel<DailyNutritionSummary>(
            ix.Ascending(x => x.UserId).Ascending(x => x.Date),
            new CreateIndexOptions { Unique = true, Name = "UIX_UserId_Date" }));
    }
}
