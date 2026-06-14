using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Order.Application.Ports;
using Order.Application.Services;

namespace Order.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("webhooks/ahamove")]
public class AhamoveWebhookController : ControllerBase
{
    private readonly IDeliveryProvider _deliveryProvider;
    private readonly IDeliveryTrackingService _trackingService;

    public AhamoveWebhookController(
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

        string? authValue = null;
        if (Request.Headers.TryGetValue("apikey", out var apiKey) && !string.IsNullOrWhiteSpace(apiKey))
            authValue = apiKey.ToString();
        else if (Request.Headers.TryGetValue("Authorization", out var authorization))
            authValue = authorization.ToString();

        var payload = _deliveryProvider.ParseAndVerifyWebhook(rawBody, authValue);
        if (payload == null)
            return Unauthorized();

        await _trackingService.ProcessWebhookAsync(payload, rawBody, cancellationToken);
        return Ok();
    }
}
