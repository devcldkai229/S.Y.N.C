using Contract.Events;
using Libs.Shared.Enums;
using Nutrition.Application.Helpers;
using Nutrition.Domain.Enums;
using Nutrition.Domain.Models;
using Nutrition.Domain.Repositories;

namespace Nutrition.Application.Services;

public class OrderCompletedHandler : IOrderCompletedHandler
{
    private readonly IMealLogRepository _mealLogRepository;
    private readonly IDailyNutritionSummaryService _dailySummaryService;
    private readonly INutritionRealtimePublisher _realtimePublisher;

    public OrderCompletedHandler(
        IMealLogRepository mealLogRepository,
        IDailyNutritionSummaryService dailySummaryService,
        INutritionRealtimePublisher realtimePublisher)
    {
        _mealLogRepository = mealLogRepository;
        _dailySummaryService = dailySummaryService;
        _realtimePublisher = realtimePublisher;
    }

    public async Task HandleAsync(OrderCompletedEvent orderEvent, CancellationToken cancellationToken = default)
    {
        if (orderEvent.Items.Count == 0)
            return;

        var existing = await _mealLogRepository.GetByRelatedOrderIdAsync(orderEvent.OrderId, cancellationToken);
        if (existing != null)
            return;

        var items = orderEvent.Items.Select(line => new MealLog.MealLogItem
        {
            FoodItemId = null,
            FoodNameSnapshot = line.NameSnapshot,
            QuantityGram = line.Quantity * 100m,
            Calories = line.Calories * line.Quantity,
            ProteinGram = line.ProteinGram * line.Quantity,
            CarbGram = line.CarbGram * line.Quantity,
            FatGram = line.FatGram * line.Quantity,
        }).ToList();

        var log = new MealLog
        {
            UserId = orderEvent.UserId,
            MealType = InferMealType(orderEvent.CompletedAt),
            LoggedAt = orderEvent.CompletedAt,
            Source = MealLogSource.FromMarketplaceOrder,
            RelatedOrderId = orderEvent.OrderId,
            Items = items,
        };

        NutritionMacroCalculator.ApplyTotals(log);
        await _mealLogRepository.CreateAsync(log, cancellationToken);
        var logDate = DateOnly.FromDateTime(orderEvent.CompletedAt.UtcDateTime);
        await _dailySummaryService.RecomputeForDateAsync(
            orderEvent.UserId,
            logDate,
            cancellationToken);
        await _realtimePublisher.PublishNutritionUpdatedAsync(orderEvent.UserId, logDate, cancellationToken);
    }

    private static MealType InferMealType(DateTimeOffset completedAt)
    {
        var hour = completedAt.UtcDateTime.Hour;
        return hour switch
        {
            < 10 => MealType.Breakfast,
            < 15 => MealType.Lunch,
            < 21 => MealType.Dinner,
            _ => MealType.Snack,
        };
    }
}
