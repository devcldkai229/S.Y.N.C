using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Exceptions;
using Payment.Application.Options;
using Payment.Application.Services;

namespace Payment.API.Controllers;

[ApiController]
[Route("api/v1/payments/google-play")]
public class GooglePlayController : ControllerBase
{
    private readonly IGooglePlayBillingService _billing;
    private readonly ICurrentUserContext _currentUser;
    private readonly GooglePlaySettings _settings;

    public GooglePlayController(
        IGooglePlayBillingService billing,
        ICurrentUserContext currentUser,
        IOptions<GooglePlaySettings> settings)
    {
        _billing = billing;
        _currentUser = currentUser;
        _settings = settings.Value;
    }

    /// <summary>
    /// POST /api/v1/payments/google-play/verify
    /// App sends purchaseToken after Play Billing purchase; server verifies + activates Premium.
    /// </summary>
    [HttpPost("verify")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<VerifyGooglePlayPurchaseResponse>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<VerifyGooglePlayPurchaseResponse>>> Verify(
        [FromBody] VerifyGooglePlayPurchaseRequest request,
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var result = await _billing.VerifyPurchaseAsync(userId, request, cancellationToken);
        return Ok(ApiResponse<VerifyGooglePlayPurchaseResponse>.SuccessResponse(result, result.Message));
    }

    /// <summary>
    /// POST /api/v1/payments/google-play/rtdn
    /// Google Play Real-time Developer Notifications via Pub/Sub push. Must stay anonymous.
    /// </summary>
    [HttpPost("rtdn")]
    [AllowAnonymous]
    [Consumes("application/json")]
    [ProducesResponseType(typeof(ApiResponse<GooglePlayRtdnProcessResult>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<GooglePlayRtdnProcessResult>>> Rtdn(
        CancellationToken cancellationToken)
    {
        EnsureRtdnAuthorized();

        string rawBody;
        Request.EnableBuffering();
        Request.Body.Position = 0;
        using (var reader = new StreamReader(Request.Body, leaveOpen: true))
        {
            rawBody = await reader.ReadToEndAsync(cancellationToken);
        }

        if (string.IsNullOrWhiteSpace(rawBody))
            throw new BadRequestException("RTDN body is empty.");

        var result = await _billing.ProcessRtdnAsync(rawBody, cancellationToken);
        return Ok(ApiResponse<GooglePlayRtdnProcessResult>.SuccessResponse(result, result.Message));
    }

    private void EnsureRtdnAuthorized()
    {
        if (string.IsNullOrWhiteSpace(_settings.RtdnSharedSecret))
            return; // open endpoint when secret not configured (dev); set secret in prod

        var header = Request.Headers["X-Google-Play-Rtdn-Secret"].FirstOrDefault();
        var query = Request.Query["token"].FirstOrDefault();
        var provided = !string.IsNullOrEmpty(header) ? header : query;

        if (!string.Equals(provided, _settings.RtdnSharedSecret, StringComparison.Ordinal))
            throw new UnauthorizedException("Invalid RTDN shared secret.");
    }
}
