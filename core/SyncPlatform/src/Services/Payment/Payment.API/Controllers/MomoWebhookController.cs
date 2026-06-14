using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.DTOs;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("webhooks/momo")]
public class MomoWebhookController : ControllerBase
{
    private readonly IOrderPaymentService _orderPaymentService;

    public MomoWebhookController(IOrderPaymentService orderPaymentService) =>
        _orderPaymentService = orderPaymentService;

    [HttpPost]
    public async Task<IActionResult> Receive(CancellationToken cancellationToken)
    {
        using var reader = new StreamReader(Request.Body);
        var raw = await reader.ReadToEndAsync(cancellationToken);
        var payload = JsonSerializer.Deserialize<MomoIpnPayloadDto>(raw, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
        });

        if (payload == null)
            return BadRequest();

        var result = await _orderPaymentService.ProcessMomoIpnAsync(payload, raw, cancellationToken);
        if (!result.Accepted)
            return BadRequest();

        return Ok(new { resultCode = 0, message = "Success" });
    }
}
