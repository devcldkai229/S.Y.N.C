using Microsoft.AspNetCore.Mvc;
using Notification.Application.Services.SmartPush;

namespace Notification.API.Controllers;

[ApiController]
[Route("api/test/smart-push")]
public class TestSmartPushController : ControllerBase
{
    private readonly ISmartPushNotificationService _smartPushService;

    public TestSmartPushController(ISmartPushNotificationService smartPushService)
    {
        _smartPushService = smartPushService;
    }

    [HttpPost("trigger")]
    public async Task<IActionResult> TriggerScan(
        [FromQuery] DateTime? utcNow,
        [FromQuery] Guid? userId,
        [FromQuery] bool sendImmediately = false,
        CancellationToken cancellationToken = default)
    {
        var targetTime = utcNow ?? DateTime.UtcNow;
        await _smartPushService.ProcessDueUsersAsync(targetTime, userId, sendImmediately, cancellationToken);
        return Ok(new { message = $"Smart Push engine triggered for target time: {targetTime:O}, userId: {userId}, sendImmediately: {sendImmediately}" });
    }
}
