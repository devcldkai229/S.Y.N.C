using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[Route("api/v1/payments/promotion-campaigns")]
public class PromotionCampaignsController : ControllerBase
{
    private readonly IPromotionCampaignService _campaignService;

    public PromotionCampaignsController(IPromotionCampaignService campaignService)
    {
        _campaignService = campaignService;
    }

    /// <summary>
    /// GET /api/v1/payments/promotion-campaigns/active
    /// Lấy danh sách chiến dịch khuyến mãi đang diễn ra và active - Dành cho khách/người dùng
    /// </summary>
    [HttpGet("active")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<PromotionCampaignDto>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<IEnumerable<PromotionCampaignDto>>>> GetActiveCampaigns(CancellationToken cancellationToken)
    {
        var result = await _campaignService.GetActiveCampaignsAsync(cancellationToken);
        return Ok(ApiResponse<IEnumerable<PromotionCampaignDto>>.SuccessResponse(result, "Active promotion campaigns retrieved."));
    }

    /// <summary>
    /// GET /api/v1/payments/promotion-campaigns/coupon/{code}
    /// Tra cứu chi tiết mã giảm giá (Coupon Code) đang active - Dành cho khách/người dùng khi thanh toán
    /// </summary>
    [HttpGet("coupon/{code}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<PromotionCampaignDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<PromotionCampaignDto>>> GetByCode(string code, CancellationToken cancellationToken)
    {
        var result = await _campaignService.GetByCodeAsync(code, cancellationToken);
        return Ok(ApiResponse<PromotionCampaignDto>.SuccessResponse(result, "Coupon details retrieved successfully."));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ADMIN ENDPOINTS
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// GET /api/v1/payments/promotion-campaigns
    /// Lấy toàn bộ danh sách chiến dịch khuyến mãi (Dành cho Admin/Staff)
    /// </summary>
    [HttpGet]
    [Authorize(Roles = "SystemAdmin")]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<PromotionCampaignDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ApiResponse<IEnumerable<PromotionCampaignDto>>>> GetAllCampaigns(
        [FromQuery] bool includeInactive = true,
        [FromQuery] bool includeDeleted = true,
        CancellationToken cancellationToken = default)
    {
        var result = await _campaignService.GetAllCampaignsAsync(includeInactive, includeDeleted, cancellationToken);
        return Ok(ApiResponse<IEnumerable<PromotionCampaignDto>>.SuccessResponse(result, "All promotion campaigns retrieved."));
    }

    /// <summary>
    /// GET /api/v1/payments/promotion-campaigns/{id}
    /// Lấy chi tiết chiến dịch khuyến mãi theo ID (Dành cho Admin/Staff)
    /// </summary>
    [HttpGet("{id:guid}")]
    [Authorize(Roles = "SystemAdmin")]
    [ProducesResponseType(typeof(ApiResponse<PromotionCampaignDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<PromotionCampaignDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _campaignService.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<PromotionCampaignDto>.SuccessResponse(result, "Promotion campaign details retrieved."));
    }

    /// <summary>
    /// POST /api/v1/payments/promotion-campaigns
    /// Tạo mới chiến dịch khuyến mãi (Dành cho Admin)
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "SystemAdmin")]
    [ProducesResponseType(typeof(ApiResponse<PromotionCampaignDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ApiResponse<PromotionCampaignDto>>> Create(
        [FromBody] CreatePromotionCampaignDto request,
        CancellationToken cancellationToken)
    {
        var result = await _campaignService.CreateAsync(request, cancellationToken);
        return StatusCode(
            StatusCodes.Status201Created,
            ApiResponse<PromotionCampaignDto>.SuccessResponse(result, "Promotion campaign created successfully."));
    }

    /// <summary>
    /// PUT /api/v1/payments/promotion-campaigns/{id}
    /// Cập nhật chiến dịch khuyến mãi (Dành cho Admin)
    /// </summary>
    [HttpPut("{id:guid}")]
    [Authorize(Roles = "SystemAdmin")]
    [ProducesResponseType(typeof(ApiResponse<PromotionCampaignDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ApiResponse<PromotionCampaignDto>>> Update(
        Guid id,
        [FromBody] UpdatePromotionCampaignDto request,
        CancellationToken cancellationToken)
    {
        var result = await _campaignService.UpdateAsync(id, request, cancellationToken);
        return Ok(ApiResponse<PromotionCampaignDto>.SuccessResponse(result, "Promotion campaign updated successfully."));
    }

    /// <summary>
    /// DELETE /api/v1/payments/promotion-campaigns/{id}
    /// Xóa mềm/Xóa cứng chiến dịch khuyến mãi (Dành cho Admin)
    /// </summary>
    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "SystemAdmin")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<object>>> Delete(
        Guid id,
        [FromQuery] bool softDelete = true,
        CancellationToken cancellationToken = default)
    {
        await _campaignService.DeleteAsync(id, softDelete, cancellationToken);
        var message = softDelete ? "Promotion campaign soft-deleted successfully." : "Promotion campaign hard-deleted successfully.";
        return Ok(ApiResponse<object>.SuccessResponse(null!, message));
    }
}
