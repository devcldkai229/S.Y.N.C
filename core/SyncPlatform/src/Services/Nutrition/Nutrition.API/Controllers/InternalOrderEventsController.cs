using Contract.Events;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Nutrition.Application.Common;
using Nutrition.Application.Services;

namespace Nutrition.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/orders")]
public class InternalOrderEventsController : ControllerBase
{
    private readonly IOrderCompletedHandler _handler;

    public InternalOrderEventsController(IOrderCompletedHandler handler)
    {
        _handler = handler;
    }

    [HttpPost("completed")]
    public async Task<ActionResult<ApiResponse<object?>>> OrderCompleted(
        [FromBody] OrderCompletedEvent orderEvent,
        CancellationToken cancellationToken)
    {
        await _handler.HandleAsync(orderEvent, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Order completed event processed."));
    }
}
