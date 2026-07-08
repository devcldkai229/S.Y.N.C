using Iam.Application.DTOs;

namespace Iam.Application.Services;

/// <summary>
/// Cung cấp bối cảnh tổng hợp cho SYNC AI Layer (đọc nội bộ).
/// </summary>
public interface IInternalAiContextService
{
    Task<InternalAiContextDto?> GetFullContextAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<InternalAiContextDto?> PatchAsync(
        Guid userId,
        InternalPatchAiContextDto patch,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Kiểm tra và tăng bộ đếm AI chat theo tháng. Free = 30/tháng; Premium/Ultra = không giới hạn.
    /// </summary>
    Task<InternalAiQuotaResultDto?> TryConsumeAiQuotaAsync(
        Guid userId,
        CancellationToken cancellationToken = default);
}
