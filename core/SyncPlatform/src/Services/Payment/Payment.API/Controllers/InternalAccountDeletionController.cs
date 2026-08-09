using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/payment/users")]
public class InternalAccountDeletionController : ControllerBase
{
    private readonly IUserSubscriptionService _subscriptions;

    public InternalAccountDeletionController(IUserSubscriptionService subscriptions)
    {
        _subscriptions = subscriptions;
    }

    [HttpPost("{userId:guid}/expire-subscriptions")]
    public async Task<ActionResult<ApiResponse<object?>>> ExpireSubscriptions(
        Guid userId,
        CancellationToken cancellationToken)
    {
        await _subscriptions.ExpireAllActiveForUserAsync(userId, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Subscriptions expired."));
    }
}
