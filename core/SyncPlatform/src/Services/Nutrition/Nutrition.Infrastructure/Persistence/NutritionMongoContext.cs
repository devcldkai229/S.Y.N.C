using MongoDB.Driver;
using Nutrition.Domain.Models;

namespace Nutrition.Infrastructure.Persistence;

public sealed class NutritionMongoContext
{
    private readonly IMongoDatabase _db;

    public NutritionMongoContext(IMongoDatabase db) => _db = db;

    public IMongoCollection<FoodItem> FoodItems => _db.GetCollection<FoodItem>("FoodItems");

    public IMongoCollection<MealLog> MealLogs => _db.GetCollection<MealLog>("MealLogs");

    public IMongoCollection<DailyNutritionSummary> DailyNutritionSummaries =>
        _db.GetCollection<DailyNutritionSummary>("DailyNutritionSummaries");
}
