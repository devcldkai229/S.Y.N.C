using Libs.Shared.Enums;
using Nutrition.Application.DTOs;
using Nutrition.Application.Exceptions;
using Nutrition.Application.Helpers;
using Nutrition.Application.Mappers;
using Nutrition.Domain.Enums;
using Nutrition.Domain.Models;
using Nutrition.Domain.Repositories;

namespace Nutrition.Application.Services;

public class MealLogService : IMealLogService
{
    private readonly IMealLogRepository _mealLogRepository;
    private readonly IFoodItemRepository _foodItemRepository;
    private readonly IDailyNutritionSummaryService _dailySummaryService;
    private readonly INutritionRealtimePublisher _realtimePublisher;

    public MealLogService(
        IMealLogRepository mealLogRepository,
        IFoodItemRepository foodItemRepository,
        IDailyNutritionSummaryService dailySummaryService,
        INutritionRealtimePublisher realtimePublisher)
    {
        _mealLogRepository = mealLogRepository;
        _foodItemRepository = foodItemRepository;
        _dailySummaryService = dailySummaryService;
        _realtimePublisher = realtimePublisher;
    }

    public async Task<MealLogDto> CreateAsync(
        Guid userId,
        CreateMealLogDto dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.Items.Count == 0)
            throw new BadRequestException("At least one meal item is required.");

        var log = new MealLog
        {
            UserId = userId,
            MealType = dto.MealType,
            LoggedAt = dto.LoggedAt ?? DateTimeOffset.UtcNow,
            Source = MealLogSource.Manual,
            PhotoUrl = dto.PhotoUrl,
            Notes = dto.Notes,
        };

        log.Items = await BuildItemsAsync(dto.Items, cancellationToken);
        NutritionMacroCalculator.ApplyTotals(log);

        await _mealLogRepository.CreateAsync(log, cancellationToken);
        var logDate = DateOnly.FromDateTime(log.LoggedAt.UtcDateTime);
        await _dailySummaryService.RecomputeForDateAsync(userId, logDate, cancellationToken);
        await _realtimePublisher.PublishNutritionUpdatedAsync(userId, logDate, cancellationToken);

        return log.ToDto();
    }

    public async Task<MealLogDto> UpdateAsync(
        Guid userId,
        Guid id,
        UpdateMealLogDto dto,
        CancellationToken cancellationToken = default)
    {
        var log = await GetOwnedLogAsync(userId, id, cancellationToken);
        var oldDate = DateOnly.FromDateTime(log.LoggedAt.UtcDateTime);

        if (dto.Items.Count == 0)
            throw new BadRequestException("At least one meal item is required.");

        log.MealType = dto.MealType;
        log.LoggedAt = dto.LoggedAt;
        log.PhotoUrl = dto.PhotoUrl;
        log.Notes = dto.Notes;
        log.Items = await BuildItemsAsync(dto.Items, cancellationToken);
        NutritionMacroCalculator.ApplyTotals(log);

        await _mealLogRepository.UpdateAsync(id, log, cancellationToken);

        var newDate = DateOnly.FromDateTime(log.LoggedAt.UtcDateTime);
        await _dailySummaryService.RecomputeForDateAsync(userId, oldDate, cancellationToken);
        if (newDate != oldDate)
            await _dailySummaryService.RecomputeForDateAsync(userId, newDate, cancellationToken);

        await _realtimePublisher.PublishNutritionUpdatedAsync(userId, newDate, cancellationToken);

        return log.ToDto();
    }

    public async Task DeleteAsync(Guid userId, Guid id, CancellationToken cancellationToken = default)
    {
        var log = await GetOwnedLogAsync(userId, id, cancellationToken);
        var date = DateOnly.FromDateTime(log.LoggedAt.UtcDateTime);
        await _mealLogRepository.DeleteAsync(id, cancellationToken);
        await _dailySummaryService.RecomputeForDateAsync(userId, date, cancellationToken);
        await _realtimePublisher.PublishNutritionUpdatedAsync(userId, date, cancellationToken);
    }

    public async Task<IReadOnlyList<MealLogDto>> ListAsync(
        Guid userId,
        MealLogListRequest request,
        CancellationToken cancellationToken = default)
    {
        var (from, to) = ResolveDateRange(request);
        var logs = await _mealLogRepository.GetByUserAndDateRangeAsync(userId, from, to, cancellationToken);
        return logs.Select(l => l.ToDto()).ToList();
    }

    public async Task<MealLogDto> GetByIdAsync(Guid userId, Guid id, CancellationToken cancellationToken = default)
    {
        var log = await GetOwnedLogAsync(userId, id, cancellationToken);
        return log.ToDto();
    }

    private async Task<MealLog> GetOwnedLogAsync(Guid userId, Guid id, CancellationToken cancellationToken)
    {
        var log = await _mealLogRepository.GetByIdAsync(id, cancellationToken);
        if (log == null)
            throw new NotFoundException(nameof(MealLog), id);
        if (log.UserId != userId)
            throw new ForbiddenException("You can only access your own meal logs.");
        return log;
    }

    private async Task<List<MealLog.MealLogItem>> BuildItemsAsync(
        IEnumerable<MealLogItemInputDto> inputs,
        CancellationToken cancellationToken)
    {
        var items = new List<MealLog.MealLogItem>();
        foreach (var input in inputs)
        {
            if (input.QuantityGram <= 0)
                throw new BadRequestException("QuantityGram must be greater than zero.");

            if (input.FoodItemId is Guid foodItemId)
            {
                var food = await _foodItemRepository.GetByIdAsync(foodItemId, cancellationToken);
                if (food == null || !food.IsActive)
                    throw new NotFoundException(nameof(FoodItem), foodItemId);

                items.Add(NutritionMacroCalculator.CalculateFromFoodItem(
                    food,
                    input.QuantityGram,
                    input.FoodName));
                continue;
            }

            if (string.IsNullOrWhiteSpace(input.FoodName))
                throw new BadRequestException("FoodName is required when FoodItemId is not provided.");

            if (input.Calories is null || input.ProteinGram is null || input.CarbGram is null || input.FatGram is null)
                throw new BadRequestException("Calories and macros are required for free-text food items.");

            items.Add(NutritionMacroCalculator.CalculateFromFreeText(
                input.FoodName.Trim(),
                input.QuantityGram,
                input.Calories.Value,
                input.ProteinGram.Value,
                input.CarbGram.Value,
                input.FatGram.Value));
        }

        return items;
    }

    private static (DateTimeOffset From, DateTimeOffset To) ResolveDateRange(MealLogListRequest request)
    {
        if (request.Date is DateOnly singleDate)
        {
            var from = new DateTimeOffset(singleDate.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
            return (from, from.AddDays(1));
        }

        var fromDate = request.From ?? DateOnly.FromDateTime(DateTimeOffset.UtcNow.UtcDateTime);
        var toDate = request.To ?? fromDate;
        if (toDate < fromDate)
            throw new BadRequestException("To date must be on or after From date.");

        var rangeFrom = new DateTimeOffset(fromDate.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var rangeTo = new DateTimeOffset(toDate.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero).AddDays(1);
        return (rangeFrom, rangeTo);
    }
}
