using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Order.Application.Ports;
using Order.Application.Services;

namespace Order.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("webhooks/lalamove")]
public class LalamoveWebhookController : ControllerBase
{
    private readonly IDeliveryProvider _deliveryProvider;
    private readonly IDeliveryTrackingService _trackingService;

    public LalamoveWebhookController(
        IDeliveryProvider deliveryProvider,
        IDeliveryTrackingService trackingService)
    {
        _deliveryProvider = deliveryProvider;
        _trackingService = trackingService;
    }

    [HttpPost]
    public async Task<IActionResult> Receive(CancellationToken cancellationToken)
    {
        using var reader = new StreamReader(Request.Body);
        var rawBody = await reader.ReadToEndAsync(cancellationToken);
        Request.Headers.TryGetValue("X-Lalamove-Signature", out var signature);

        var payload = _deliveryProvider.ParseAndVerifyWebhook(rawBody, signature.ToString());
        if (payload == null)
            return Unauthorized();

        await _trackingService.ProcessWebhookAsync(payload, rawBody, cancellationToken);
        return Ok();
    }
}
