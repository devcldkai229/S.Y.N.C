using Microsoft.Extensions.DependencyInjection;
using Nutrition.Application.Services;

namespace Nutrition.Application.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddNutritionApplication(this IServiceCollection services)
    {
        services.AddScoped<IFoodItemService, FoodItemService>();
        services.AddScoped<IMealLogService, MealLogService>();
        services.AddScoped<IDailyNutritionSummaryService, DailyNutritionSummaryService>();
        services.AddScoped<IOrderCompletedHandler, OrderCompletedHandler>();
        services.AddSingleton<INutritionRealtimePublisher, NoOpNutritionRealtimePublisher>();

        return services;
    }
}
