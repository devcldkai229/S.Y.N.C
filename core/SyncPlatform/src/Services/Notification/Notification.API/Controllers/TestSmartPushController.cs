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
    public async Task<IActionResult> TriggerScan([FromQuery] DateTime? utcNow, CancellationToken cancellationToken)
    {
        var targetTime = utcNow ?? DateTime.UtcNow;
        await _smartPushService.ProcessDueUsersAsync(targetTime, cancellationToken);
        return Ok(new { message = $"Smart Push engine triggered for target time: {targetTime:O}" });
    }

    [HttpPost("seed/{userId:guid}")]
    public async Task<IActionResult> SeedSchedule(Guid userId, CancellationToken cancellationToken)
    {
        await _smartPushService.SeedUserScheduleAsync(userId, cancellationToken);
        return Ok(new { message = $"Seeded smart push schedule for user {userId}" });
    }

    [HttpPost("process/{userId:guid}")]
    public async Task<IActionResult> ProcessUser(Guid userId, CancellationToken cancellationToken)
    {
        await _smartPushService.ProcessUserNowAsync(userId, cancellationToken);
        return Ok(new { message = $"Force-processed smart push for user {userId}" });
    }

    [HttpPost("nightly-recompute")]
    public async Task<IActionResult> NightlyRecompute(CancellationToken cancellationToken)
    {
        await _smartPushService.NightlyRecomputeAsync(cancellationToken);
        return Ok(new { message = "Nightly recompute completed." });
    }
}
