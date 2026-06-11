using Nutrition.Application.Clients;
using Nutrition.Application.DTOs;
using Nutrition.Application.Mappers;
using Nutrition.Domain.Models;
using Nutrition.Domain.Repositories;

namespace Nutrition.Application.Services;

public class DailyNutritionSummaryService : IDailyNutritionSummaryService
{
    private readonly IDailyNutritionSummaryRepository _summaryRepository;
    private readonly IMealLogRepository _mealLogRepository;
    private readonly IIamBiometricClient _iamBiometricClient;

    public DailyNutritionSummaryService(
        IDailyNutritionSummaryRepository summaryRepository,
        IMealLogRepository mealLogRepository,
        IIamBiometricClient iamBiometricClient)
    {
        _summaryRepository = summaryRepository;
        _mealLogRepository = mealLogRepository;
        _iamBiometricClient = iamBiometricClient;
    }

    public async Task<DailyNutritionSummaryDto> GetDailySummaryAsync(
        Guid userId,
        DateOnly date,
        CancellationToken cancellationToken = default)
    {
        var targets = await _iamBiometricClient.GetNutritionTargetsAsync(userId, cancellationToken);
        var summary = await _summaryRepository.GetByUserAndDateAsync(userId, date, cancellationToken);

        if (summary == null)
        {
            await RecomputeForDateAsync(userId, date, cancellationToken);
            summary = await _summaryRepository.GetByUserAndDateAsync(userId, date, cancellationToken);
        }

        summary ??= new DailyNutritionSummary
        {
            UserId = userId,
            Date = date,
        };

        return summary.ToDto(MapTargets(targets));
    }

    public async Task<DailyNutritionSummaryDto> AddWaterIntakeAsync(
        Guid userId,
        AddWaterIntakeDto dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.Milliliters <= 0)
            throw new Exceptions.BadRequestException("Milliliters must be greater than zero.");

        var date = dto.Date ?? DateOnly.FromDateTime(DateTimeOffset.UtcNow.UtcDateTime);
        var summary = await _summaryRepository.GetByUserAndDateAsync(userId, date, cancellationToken)
            ?? new DailyNutritionSummary
            {
                UserId = userId,
                Date = date,
            };

        summary.WaterIntakeMl += dto.Milliliters;
        await _summaryRepository.UpsertAsync(summary, cancellationToken);

        var targets = await _iamBiometricClient.GetNutritionTargetsAsync(userId, cancellationToken);
        return summary.ToDto(MapTargets(targets));
    }

    public async Task RecomputeForDateAsync(Guid userId, DateOnly date, CancellationToken cancellationToken = default)
    {
        var from = new DateTimeOffset(date.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var to = from.AddDays(1);

        var logs = await _mealLogRepository.GetByUserAndDateRangeAsync(userId, from, to, cancellationToken);
        var existing = await _summaryRepository.GetByUserAndDateAsync(userId, date, cancellationToken);
        var targets = await _iamBiometricClient.GetNutritionTargetsAsync(userId, cancellationToken);

        var summary = existing ?? new DailyNutritionSummary
        {
            UserId = userId,
            Date = date,
        };

        summary.TargetCalories = targets?.TargetCalories ?? 0;
        summary.TargetProteinGram = targets?.TargetProteinGram ?? 0;
        summary.TargetCarbGram = targets?.TargetCarbGram ?? 0;
        summary.TargetFatGram = targets?.TargetFatGram ?? 0;
        summary.ConsumedCalories = logs.Sum(l => l.TotalCalories);
        summary.ConsumedProteinGram = logs.Sum(l => l.TotalProteinGram);
        summary.ConsumedCarbGram = logs.Sum(l => l.TotalCarbGram);
        summary.ConsumedFatGram = logs.Sum(l => l.TotalFatGram);
        summary.MealsLoggedCount = logs.Count;
        summary.WaterIntakeMl = existing?.WaterIntakeMl ?? 0;

        await _summaryRepository.UpsertAsync(summary, cancellationToken);
    }

    private static NutritionTargetsDto? MapTargets(NutritionTargetsDto? targets) =>
        targets == null
            ? null
            : new NutritionTargetsDto
            {
                TargetCalories = targets.TargetCalories,
                TargetProteinGram = targets.TargetProteinGram,
                TargetCarbGram = targets.TargetCarbGram,
                TargetFatGram = targets.TargetFatGram,
            };
}
