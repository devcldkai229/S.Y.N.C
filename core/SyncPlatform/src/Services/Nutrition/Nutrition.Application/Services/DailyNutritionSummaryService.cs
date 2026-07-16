using Libs.Shared.Time;
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

        var date = dto.Date ?? UserLocalTime.TodayDate(null);
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
        var (from, to) = UserLocalTime.DayRange(date, null);

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

    public async Task<IReadOnlyList<NutritionTimeseriesBucketDto>> GetTimeseriesAsync(
        Guid userId,
        DateOnly from,
        DateOnly to,
        string granularity,
        CancellationToken cancellationToken = default)
    {
        if (to < from)
            (from, to) = (to, from);

        var spanDays = to.DayNumber - from.DayNumber + 1;
        if (spanDays > 366)
            to = from.AddDays(365);

        var targets = await _iamBiometricClient.GetNutritionTargetsAsync(userId, cancellationToken);
        var rows = await _summaryRepository.GetByUserAndDateRangeAsync(userId, from, to, cancellationToken);
        var byDate = rows.ToDictionary(x => x.Date);

        var gran = (granularity ?? "day").Trim().ToLowerInvariant();
        if (gran is not ("day" or "week" or "month"))
            gran = "day";

        var buckets = new Dictionary<string, NutritionTimeseriesBucketDto>(StringComparer.Ordinal);

        for (var d = from; d <= to; d = d.AddDays(1))
        {
            var key = gran switch
            {
                "month" => $"{d.Year:D4}-{d.Month:D2}",
                "week" => $"{System.Globalization.ISOWeek.GetYear(d.ToDateTime(TimeOnly.MinValue))}-W{System.Globalization.ISOWeek.GetWeekOfYear(d.ToDateTime(TimeOnly.MinValue)):D2}",
                _ => d.ToString("yyyy-MM-dd"),
            };

            if (!buckets.TryGetValue(key, out var bucket))
            {
                bucket = new NutritionTimeseriesBucketDto
                {
                    Key = key,
                    From = d,
                    To = d,
                    TargetCalories = targets?.TargetCalories ?? 0,
                    TargetProteinGram = targets?.TargetProteinGram ?? 0,
                    TargetCarbGram = targets?.TargetCarbGram ?? 0,
                    TargetFatGram = targets?.TargetFatGram ?? 0,
                };
                buckets[key] = bucket;
            }

            bucket.To = d;
            bucket.DayCount += 1;
            if (!byDate.TryGetValue(d, out var row))
                continue;

            bucket.ConsumedCalories += row.ConsumedCalories;
            bucket.ConsumedProteinGram += row.ConsumedProteinGram;
            bucket.ConsumedCarbGram += row.ConsumedCarbGram;
            bucket.ConsumedFatGram += row.ConsumedFatGram;
            bucket.WaterIntakeMl += row.WaterIntakeMl;
            bucket.MealsLoggedCount += row.MealsLoggedCount;
            if (row.MealsLoggedCount > 0 || row.ConsumedCalories > 0)
                bucket.DaysWithLog += 1;

            if (row.TargetCalories > 0)
                bucket.TargetCalories = row.TargetCalories;
            if (row.TargetProteinGram > 0)
                bucket.TargetProteinGram = row.TargetProteinGram;
            if (row.TargetCarbGram > 0)
                bucket.TargetCarbGram = row.TargetCarbGram;
            if (row.TargetFatGram > 0)
                bucket.TargetFatGram = row.TargetFatGram;
        }

        // Average targets across days for week/month buckets (consumed stays summed —
        // AI charts plot per-bucket; for week/month convert consumed to daily avg for readability)
        if (gran is "week" or "month")
        {
            foreach (var b in buckets.Values)
            {
                if (b.DayCount <= 1) continue;
                b.ConsumedCalories = (int)Math.Round(b.ConsumedCalories / (double)b.DayCount);
                b.ConsumedProteinGram = Math.Round(b.ConsumedProteinGram / b.DayCount, 1);
                b.ConsumedCarbGram = Math.Round(b.ConsumedCarbGram / b.DayCount, 1);
                b.ConsumedFatGram = Math.Round(b.ConsumedFatGram / b.DayCount, 1);
                b.WaterIntakeMl = (int)Math.Round(b.WaterIntakeMl / (double)b.DayCount);
            }
        }

        return buckets.Values.OrderBy(b => b.Key).ToList();
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
