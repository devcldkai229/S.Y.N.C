using Iam.Application.DTOs;

namespace Iam.Application.Services;

public interface IInternalBiometricService
{
    Task<InternalNutritionTargetsDto?> GetNutritionTargetsAsync(Guid userId, CancellationToken cancellationToken = default);

    // ── Adaptive Coaching Engine ────────────────────────────────────────────
    Task<InternalWeighInResultDto?> RecordWeighInAsync(
        Guid userId, InternalWeighInRequestDto request, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<InternalWeightHistoryItemDto>> GetWeightHistoryAsync(
        Guid userId, DateTime fromUtc, DateTime toUtc, CancellationToken cancellationToken = default);

    Task<InternalApplyTargetsResultDto?> ApplyTargetsAsync(
        Guid userId, InternalApplyTargetsRequestDto request, CancellationToken cancellationToken = default);

    Task<InternalLevelSnapshotDto?> CreateLevelSnapshotAsync(
        Guid userId, InternalLevelSnapshotRequestDto request, CancellationToken cancellationToken = default);

    Task<InternalLevelSnapshotDto?> GetLatestLevelSnapshotAsync(
        Guid userId, CancellationToken cancellationToken = default);
}
