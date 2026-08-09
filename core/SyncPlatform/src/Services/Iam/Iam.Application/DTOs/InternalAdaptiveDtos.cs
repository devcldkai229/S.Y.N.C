namespace Iam.Application.DTOs;

/// <summary>Request ghi weigh-in từ AI service (Adaptive Engine).</summary>
public class InternalWeighInRequestDto
{
    public decimal WeightKg { get; set; }
    public decimal? BodyFatPercentage { get; set; }
    public decimal? MuscleMassKg { get; set; }
    public string Source { get; set; } = "Manual";
    public string? Note { get; set; }
    /// <summary>Thời điểm cân UTC; null = now.</summary>
    public DateTime? RecordedAtUtc { get; set; }
}

public class InternalWeighInResultDto
{
    public Guid HistoryId { get; set; }
    public decimal CurrentWeightKg { get; set; }
    public int BaseTdee { get; set; }
    public int Bmr { get; set; }
    public int WeighInCount30d { get; set; }
}

public class InternalWeightHistoryItemDto
{
    public DateTime RecordedAtUtc { get; set; }
    public decimal WeightKg { get; set; }
    public decimal? BodyFatPercentage { get; set; }
    public string Source { get; set; } = "Manual";
}

/// <summary>Engine apply targets đã hiệu chỉnh + ghi TargetAdjustmentLog.</summary>
public class InternalApplyTargetsRequestDto
{
    public int NewCalories { get; set; }
    public int NewProteinGram { get; set; }
    public int NewCarbGram { get; set; }
    public int NewFatGram { get; set; }

    public int EstimatedTdee { get; set; }
    public int FormulaTdee { get; set; }

    public string Trigger { get; set; } = "WeighIn";
    public string ConfidenceLevel { get; set; } = "thấp";
    public string ReasonCode { get; set; } = string.Empty;
    public string? ReasonText { get; set; }
    /// <summary>Auto | Confirmed</summary>
    public string AppliedMode { get; set; } = "Confirmed";
    public bool RoadmapChanged { get; set; }
}

public class InternalApplyTargetsResultDto
{
    public Guid LogId { get; set; }
    public int? PrevCalories { get; set; }
    public int NewCalories { get; set; }
    public bool TargetsManagedByEngine { get; set; }
}

/// <summary>Engine ghi snapshot trình độ (consistency/progression/recovery).</summary>
public class InternalLevelSnapshotRequestDto
{
    public DateTime? ComputedAt { get; set; }
    public decimal LevelScore { get; set; }
    public string Tier { get; set; } = "Beginner";
    public decimal ConsistencyScore { get; set; }
    public decimal ProgressionScore { get; set; }
    public decimal RecoveryCapacityScore { get; set; }
    public decimal VolumeLoadWeekly { get; set; }
}

public class InternalLevelSnapshotDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public DateTime ComputedAt { get; set; }
    public decimal LevelScore { get; set; }
    public string Tier { get; set; } = "Beginner";
    public decimal ConsistencyScore { get; set; }
    public decimal ProgressionScore { get; set; }
    public decimal RecoveryCapacityScore { get; set; }
    public decimal VolumeLoadWeekly { get; set; }
}
