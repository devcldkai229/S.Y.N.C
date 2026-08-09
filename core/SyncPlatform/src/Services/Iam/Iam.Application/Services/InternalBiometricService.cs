using Iam.Application.Abstractions;
using Iam.Application.DTOs;
using Iam.Domain.Models;
using Iam.Domain.Repositories;

namespace Iam.Application.Services;

public class InternalBiometricService : IInternalBiometricService
{
    private readonly IBiometricProfileRepository _biometricRepository;
    private readonly IBiometricHistoryRepository _historyRepository;
    private readonly ITargetAdjustmentLogRepository _adjustmentLogRepository;
    private readonly IUserLevelSnapshotRepository _levelSnapshotRepository;
    private readonly IRoadmapBodyMetricsClient _roadmapBodyMetrics;

    public InternalBiometricService(
        IBiometricProfileRepository biometricRepository,
        IBiometricHistoryRepository historyRepository,
        ITargetAdjustmentLogRepository adjustmentLogRepository,
        IUserLevelSnapshotRepository levelSnapshotRepository,
        IRoadmapBodyMetricsClient roadmapBodyMetrics)
    {
        _biometricRepository = biometricRepository;
        _historyRepository = historyRepository;
        _adjustmentLogRepository = adjustmentLogRepository;
        _levelSnapshotRepository = levelSnapshotRepository;
        _roadmapBodyMetrics = roadmapBodyMetrics;
    }

    public async Task<InternalNutritionTargetsDto?> GetNutritionTargetsAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var profile = await _biometricRepository.GetByUserIdAsync(userId, cancellationToken);
        if (profile == null)
            return null;

        return new InternalNutritionTargetsDto
        {
            // Engine-adjusted nếu có; fallback BaseTDEE giữ hành vi cũ cho user chưa bật engine.
            TargetCalories = profile.DailyCalorieTarget ?? profile.BaseTDEE,
            TargetProteinGram = profile.DailyProteinTargetGram,
            TargetCarbGram = profile.DailyCarbTargetGram,
            TargetFatGram = profile.DailyFatTargetGram,
        };
    }

    public async Task<InternalWeighInResultDto?> RecordWeighInAsync(
        Guid userId,
        InternalWeighInRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (request.WeightKg <= 20 || request.WeightKg > 400)
            return null; // giá trị phi lý — engine phía AI đã validate, đây là lớp chặn cuối

        var profile = await _biometricRepository.GetByUserIdAsync(userId, cancellationToken);
        if (profile == null)
            return null;

        var recordedAt = request.RecordedAtUtc ?? DateTime.UtcNow;

        var entry = new BiometricHistory
        {
            UserId = userId,
            RecordedAtUtc = recordedAt,
            WeightKg = request.WeightKg,
            BodyFatPercentage = request.BodyFatPercentage,
            MuscleMassKg = request.MuscleMassKg,
            Source = string.IsNullOrWhiteSpace(request.Source) ? "Manual" : request.Source,
            Note = request.Note,
        };
        await _historyRepository.CreateAsync(entry, cancellationToken);

        profile.CurrentWeightKg = request.WeightKg;
        if (request.BodyFatPercentage.HasValue)
            profile.CurrentBodyFatPercentage = request.BodyFatPercentage;
        if (request.MuscleMassKg.HasValue)
            profile.MuscleMassKg = request.MuscleMassKg;
        BiometricTargetCalculator.Recalculate(profile); // engine-managed → chỉ BMR/TDEE nền
        await _biometricRepository.UpdateAsync(profile, cancellationToken);

        await _roadmapBodyMetrics.SyncAsync(
            userId,
            profile.CurrentWeightKg,
            request.BodyFatPercentage ?? profile.CurrentBodyFatPercentage,
            cancellationToken);

        var from30 = DateTime.UtcNow.AddDays(-30);
        var recent = await _historyRepository.GetByUserIdAsync(userId, from30, DateTime.UtcNow, cancellationToken);

        return new InternalWeighInResultDto
        {
            HistoryId = entry.Id,
            CurrentWeightKg = profile.CurrentWeightKg,
            BaseTdee = profile.BaseTDEE,
            Bmr = profile.BMR,
            WeighInCount30d = recent.Count,
        };
    }

    public async Task<IReadOnlyList<InternalWeightHistoryItemDto>> GetWeightHistoryAsync(
        Guid userId,
        DateTime fromUtc,
        DateTime toUtc,
        CancellationToken cancellationToken = default)
    {
        var items = await _historyRepository.GetByUserIdAsync(userId, fromUtc, toUtc, cancellationToken);
        return items.Select(i => new InternalWeightHistoryItemDto
        {
            RecordedAtUtc = i.RecordedAtUtc,
            WeightKg = i.WeightKg,
            BodyFatPercentage = i.BodyFatPercentage,
            Source = i.Source,
        }).ToList();
    }

    public async Task<InternalApplyTargetsResultDto?> ApplyTargetsAsync(
        Guid userId,
        InternalApplyTargetsRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (request.NewCalories < 800 || request.NewCalories > 8000)
            return null; // lớp chặn cuối — engine đã có rào an toàn riêng

        var profile = await _biometricRepository.GetByUserIdAsync(userId, cancellationToken);
        if (profile == null)
            return null;

        var log = new TargetAdjustmentLog
        {
            UserId = userId,
            Trigger = request.Trigger,
            PrevCalories = profile.DailyCalorieTarget ?? profile.BaseTDEE,
            NewCalories = request.NewCalories,
            PrevProteinGram = profile.DailyProteinTargetGram,
            PrevCarbGram = profile.DailyCarbTargetGram,
            PrevFatGram = profile.DailyFatTargetGram,
            NewProteinGram = request.NewProteinGram,
            NewCarbGram = request.NewCarbGram,
            NewFatGram = request.NewFatGram,
            EstimatedTdee = request.EstimatedTdee,
            FormulaTdee = request.FormulaTdee,
            ConfidenceLevel = request.ConfidenceLevel,
            ReasonCode = request.ReasonCode,
            ReasonText = request.ReasonText,
            AppliedMode = request.AppliedMode,
            RoadmapChanged = request.RoadmapChanged,
        };
        await _adjustmentLogRepository.CreateAsync(log, cancellationToken);

        profile.DailyCalorieTarget = request.NewCalories;
        profile.DailyProteinTargetGram = request.NewProteinGram;
        profile.DailyCarbTargetGram = request.NewCarbGram;
        profile.DailyFatTargetGram = request.NewFatGram;
        profile.TargetsManagedByEngine = true;
        profile.TargetsAdjustedAtUtc = DateTime.UtcNow;
        await _biometricRepository.UpdateAsync(profile, cancellationToken);

        return new InternalApplyTargetsResultDto
        {
            LogId = log.Id,
            PrevCalories = log.PrevCalories,
            NewCalories = log.NewCalories,
            TargetsManagedByEngine = true,
        };
    }

    public async Task<InternalLevelSnapshotDto?> CreateLevelSnapshotAsync(
        Guid userId,
        InternalLevelSnapshotRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (request.LevelScore < 0 || request.LevelScore > 100)
            return null;

        var tier = NormalizeTier(request.Tier);
        var snapshot = new UserLevelSnapshot
        {
            UserId = userId,
            ComputedAt = request.ComputedAt ?? DateTime.UtcNow,
            LevelScore = request.LevelScore,
            Tier = tier,
            ConsistencyScore = ClampScore(request.ConsistencyScore),
            ProgressionScore = ClampScore(request.ProgressionScore),
            RecoveryCapacityScore = ClampScore(request.RecoveryCapacityScore),
            VolumeLoadWeekly = Math.Max(0, request.VolumeLoadWeekly),
        };
        await _levelSnapshotRepository.CreateAsync(snapshot, cancellationToken);
        return ToLevelDto(snapshot);
    }

    public async Task<InternalLevelSnapshotDto?> GetLatestLevelSnapshotAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var latest = await _levelSnapshotRepository.GetLatestAsync(userId, cancellationToken);
        return latest == null ? null : ToLevelDto(latest);
    }

    private static InternalLevelSnapshotDto ToLevelDto(UserLevelSnapshot s) => new()
    {
        Id = s.Id,
        UserId = s.UserId,
        ComputedAt = s.ComputedAt,
        LevelScore = s.LevelScore,
        Tier = s.Tier,
        ConsistencyScore = s.ConsistencyScore,
        ProgressionScore = s.ProgressionScore,
        RecoveryCapacityScore = s.RecoveryCapacityScore,
        VolumeLoadWeekly = s.VolumeLoadWeekly,
    };

    private static decimal ClampScore(decimal v) => Math.Clamp(v, 0, 100);

    private static string NormalizeTier(string? tier)
    {
        var t = (tier ?? "").Trim();
        if (t.Equals("Advanced", StringComparison.OrdinalIgnoreCase)) return "Advanced";
        if (t.Equals("Intermediate", StringComparison.OrdinalIgnoreCase)) return "Intermediate";
        return "Beginner";
    }
}
