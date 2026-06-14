using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/payments/wallet")]
public class WalletController : ControllerBase
{
    private readonly IOrderPaymentService _orderPaymentService;
    private readonly ICurrentUserContext _currentUser;

    public WalletController(IOrderPaymentService orderPaymentService, ICurrentUserContext currentUser)
    {
        _orderPaymentService = orderPaymentService;
        _currentUser = currentUser;
    }

    [HttpGet("me")]
    public async Task<ActionResult<ApiResponse<WalletBalanceDto>>> GetMyBalance(CancellationToken cancellationToken)
    {
        var balance = await _orderPaymentService.GetWalletBalanceAsync(_currentUser.RequireUserId(), cancellationToken);
        return Ok(ApiResponse<WalletBalanceDto>.SuccessResponse(balance, "Wallet balance retrieved."));
    }
}
