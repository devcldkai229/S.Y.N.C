using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

[ApiController]
[Route("api/internal/biometrics")]
[AllowAnonymous]
public class InternalBiometricController : ControllerBase
{
    private readonly IInternalBiometricService _service;

    public InternalBiometricController(IInternalBiometricService service)
    {
        _service = service;
    }

    [HttpGet("{userId:guid}/nutrition-targets")]
    public async Task<ActionResult<ApiResponse<InternalNutritionTargetsDto>>> GetNutritionTargets(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetNutritionTargetsAsync(userId, cancellationToken);
        if (result == null)
        {
            return NotFound(ApiResponse<InternalNutritionTargetsDto>.FailureResponse(
                $"Nutrition targets not found for user {userId}."));
        }

        return Ok(ApiResponse<InternalNutritionTargetsDto>.SuccessResponse(
            result,
            "Nutrition targets retrieved successfully."));
    }

    // ── Adaptive Coaching Engine ────────────────────────────────────────────

    /// <summary>Ghi weigh-in vào BiometricHistory + cập nhật CurrentWeightKg.</summary>
    [HttpPost("{userId:guid}/weigh-in")]
    public async Task<ActionResult<ApiResponse<InternalWeighInResultDto>>> RecordWeighIn(
        Guid userId,
        [FromBody] InternalWeighInRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _service.RecordWeighInAsync(userId, request, cancellationToken);
        if (result == null)
        {
            return BadRequest(ApiResponse<InternalWeighInResultDto>.FailureResponse(
                "Weigh-in rejected: profile not found or weight out of range (20-400kg)."));
        }

        return Ok(ApiResponse<InternalWeighInResultDto>.SuccessResponse(result, "Weigh-in recorded."));
    }

    /// <summary>Chuỗi cân nặng cho engine (EMA/TDEE reconciliation).</summary>
    [HttpGet("{userId:guid}/weight-history")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<InternalWeightHistoryItemDto>>>> GetWeightHistory(
        Guid userId,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to,
        CancellationToken cancellationToken)
    {
        // Query date-only values bind as Unspecified; Npgsql timestamptz compares require UTC.
        static DateTime AsUtc(DateTime dt) =>
            dt.Kind == DateTimeKind.Utc ? dt
            : dt.Kind == DateTimeKind.Local ? dt.ToUniversalTime()
            : DateTime.SpecifyKind(dt, DateTimeKind.Utc);

        var toUtc = AsUtc(to ?? DateTime.UtcNow);
        var fromUtc = AsUtc(from ?? toUtc.AddDays(-90));
        var result = await _service.GetWeightHistoryAsync(userId, fromUtc, toUtc, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<InternalWeightHistoryItemDto>>.SuccessResponse(
            result, "Weight history retrieved."));
    }

    /// <summary>Áp targets engine đã tính + ghi TargetAdjustmentLog (audit/rollback).</summary>
    [HttpPost("{userId:guid}/apply-targets")]
    public async Task<ActionResult<ApiResponse<InternalApplyTargetsResultDto>>> ApplyTargets(
        Guid userId,
        [FromBody] InternalApplyTargetsRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _service.ApplyTargetsAsync(userId, request, cancellationToken);
        if (result == null)
        {
            return BadRequest(ApiResponse<InternalApplyTargetsResultDto>.FailureResponse(
                "Apply targets rejected: profile not found or calories out of sane range."));
        }

        return Ok(ApiResponse<InternalApplyTargetsResultDto>.SuccessResponse(result, "Targets applied."));
    }

    /// <summary>Ghi UserLevelSnapshot từ AI Adaptive Engine.</summary>
    [HttpPost("{userId:guid}/level-snapshots")]
    public async Task<ActionResult<ApiResponse<InternalLevelSnapshotDto>>> CreateLevelSnapshot(
        Guid userId,
        [FromBody] InternalLevelSnapshotRequestDto request,
        CancellationToken cancellationToken)
    {
        var result = await _service.CreateLevelSnapshotAsync(userId, request, cancellationToken);
        if (result == null)
        {
            return BadRequest(ApiResponse<InternalLevelSnapshotDto>.FailureResponse(
                "Level snapshot rejected: LevelScore must be 0–100."));
        }

        return Ok(ApiResponse<InternalLevelSnapshotDto>.SuccessResponse(result, "Level snapshot saved."));
    }

    /// <summary>Lấy UserLevelSnapshot mới nhất (nếu có).</summary>
    [HttpGet("{userId:guid}/level-snapshots/latest")]
    public async Task<ActionResult<ApiResponse<InternalLevelSnapshotDto>>> GetLatestLevelSnapshot(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetLatestLevelSnapshotAsync(userId, cancellationToken);
        if (result == null)
        {
            return NotFound(ApiResponse<InternalLevelSnapshotDto>.FailureResponse(
                $"No level snapshot for user {userId}."));
        }

        return Ok(ApiResponse<InternalLevelSnapshotDto>.SuccessResponse(result, "Latest level snapshot."));
    }
}
