using Iam.Application.Abstractions;
using Iam.Application.Common;
using Iam.Application.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

/// <summary>
/// Internal endpoint called by the Payment service after subscription activation or expiry.
/// Protected by InternalApiKeyMiddleware — not exposed through the Gateway.
/// </summary>
[ApiController]
[Route("api/internal/subscriptions")]
public class InternalSubscriptionController : ControllerBase
{
    private readonly ISubscriptionTierService _tierService;

    public InternalSubscriptionController(ISubscriptionTierService tierService)
    {
        _tierService = tierService;
    }

    /// <summary>
    /// Set the subscription tier for a user.
    /// Called by Payment on activation (tier=Premium) and on expiry/cancellation (tier=Free).
    /// </summary>
    [HttpPost("tier")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<object>>> SetTier(
        [FromBody] SetSubscriptionTierRequest request,
        CancellationToken cancellationToken)
    {
        await _tierService.SetTierAsync(request.UserId, request.Tier, cancellationToken);

        return Ok(ApiResponse<object>.SuccessResponse(
            new { request.UserId, Tier = request.Tier.ToString() },
            $"Subscription tier set to {request.Tier} for user {request.UserId}."));
    }
}
