using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Payment.Application.Common;
using Payment.Domain.Enums;
using Payment.Domain.Models;
using Payment.Infrastructure.Persistence;

namespace Payment.API.Controllers;

[ApiController]
[Route("api/v1/payments/transactions")]
[Authorize]
public class TransactionsController : ControllerBase
{
    private readonly PaymentDbContext _db;
    private readonly ICurrentUserContext _currentUser;

    public TransactionsController(PaymentDbContext db, ICurrentUserContext currentUser)
    {
        _db          = db;
        _currentUser = currentUser;
    }

    /// <summary>
    /// GET /api/v1/payments/transactions/{id}
    /// Lấy trạng thái giao dịch theo ID. Chỉ owner xem được.
    /// Client dùng để poll sau khi redirect về từ PayOS.
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<TransactionStatusDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ApiResponse<TransactionStatusDto>>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId      = _currentUser.RequireUserId();
        var transaction = await _db.Transactions
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == id, cancellationToken);

        if (transaction is null)
            return NotFound(ApiResponse<object>.FailureResponse("Transaction not found."));

        if (transaction.UserId != userId)
            return StatusCode(StatusCodes.Status403Forbidden,
                ApiResponse<object>.FailureResponse("Access denied."));

        return Ok(ApiResponse<TransactionStatusDto>.SuccessResponse(
            ToStatusDto(transaction), "Transaction retrieved."));
    }

    /// <summary>
    /// GET /api/v1/payments/transactions/by-order-code/{orderCode}
    /// Tìm giao dịch theo orderCode trả về từ create-link. Chỉ owner xem được.
    /// </summary>
    [HttpGet("by-order-code/{orderCode:long}")]
    [ProducesResponseType(typeof(ApiResponse<TransactionStatusDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ApiResponse<TransactionStatusDto>>> GetByOrderCode(
        long orderCode,
        CancellationToken cancellationToken)
    {
        var userId      = _currentUser.RequireUserId();
        var transaction = await _db.Transactions
            .AsNoTracking()
            .FirstOrDefaultAsync(
                t => t.OrderCode == orderCode && t.Provider == PaymentProvider.PayOS,
                cancellationToken);

        if (transaction is null)
            return NotFound(ApiResponse<object>.FailureResponse("Transaction not found."));

        if (transaction.UserId != userId)
            return StatusCode(StatusCodes.Status403Forbidden,
                ApiResponse<object>.FailureResponse("Access denied."));

        return Ok(ApiResponse<TransactionStatusDto>.SuccessResponse(
            ToStatusDto(transaction), "Transaction retrieved."));
    }

    private static TransactionStatusDto ToStatusDto(Transaction t) => new()
    {
        Id          = t.Id,
        OrderCode   = t.OrderCode,
        Status      = t.Status.ToString(),
        Amount      = t.Amount,
        Currency    = t.Currency,
        CouponCode  = t.CouponCode,
        CreatedAt   = t.CreatedAt,
        ProcessedAt = t.ProcessedAt
    };
}

public class TransactionStatusDto
{
    public Guid Id { get; set; }
    public long OrderCode { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "VND";
    public string? CouponCode { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? ProcessedAt { get; set; }
}
