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
    private readonly ILogger<AhamoveWebhookController> _logger;

    public AhamoveWebhookController(
        IDeliveryProvider deliveryProvider,
        IDeliveryTrackingService trackingService,
        ILogger<AhamoveWebhookController> logger)
    {
        _deliveryProvider = deliveryProvider;
        _trackingService = trackingService;
        _logger = logger;
    }

    [HttpPost]
    public async Task<IActionResult> Receive(CancellationToken cancellationToken)
    {
        using var reader = new StreamReader(Request.Body);
        var rawBody = await reader.ReadToEndAsync(cancellationToken);

        var preview = rawBody.Length <= 2048 ? rawBody : rawBody[..2048] + "…";
        _logger.LogInformation(
            "Ahamove webhook received ({ByteCount} bytes): {BodyPreview}",
            rawBody.Length,
            preview);

        string? authValue = null;
        if (Request.Headers.TryGetValue("apikey", out var apiKey) && !string.IsNullOrWhiteSpace(apiKey))
            authValue = apiKey.ToString();
        else if (Request.Headers.TryGetValue("Authorization", out var authorization))
            authValue = authorization.ToString();

        var payload = _deliveryProvider.ParseAndVerifyWebhook(rawBody, authValue);
        if (payload == null)
        {
            _logger.LogWarning("Ahamove webhook rejected — auth failed or payload invalid.");
            return Unauthorized();
        }

        _logger.LogInformation(
            "Ahamove webhook verified for externalId={ExternalId} status={Status} eventId={EventId}",
            payload.ExternalDeliveryId,
            payload.Status,
            payload.EventId);

        await _trackingService.ProcessWebhookAsync(payload, rawBody, cancellationToken);
        return Ok();
    }
}
