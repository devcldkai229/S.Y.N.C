using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Payment.Application.Common;
using Payment.Application.DTOs;
using Payment.Application.Exceptions;
using Payment.Application.Services;
using Payment.Infrastructure.Persistence.Seed;

namespace Payment.API.Controllers;

/// <summary>Internal PayOS subscription links for AI / service-to-service.</summary>
[ApiController]
[AllowAnonymous]
[Route("api/internal/payments/subscription")]
public class InternalSubscriptionPaymentsController : ControllerBase
{
    private readonly IPayosPaymentService _payosService;
    private readonly ISubscriptionPlanService _planService;

    public InternalSubscriptionPaymentsController(
        IPayosPaymentService payosService,
        ISubscriptionPlanService planService)
    {
        _payosService = payosService;
        _planService = planService;
    }

    /// <summary>
    /// POST /api/internal/payments/subscription/create-link
    /// Create PayOS VietQR checkout for Premium (default) or explicit planId.
    /// </summary>
    [HttpPost("create-link")]
    [ProducesResponseType(typeof(ApiResponse<CreatePaymentLinkResponse>), StatusCodes.Status201Created)]
    public async Task<ActionResult<ApiResponse<CreatePaymentLinkResponse>>> CreateLink(
        [FromBody] InternalCreateSubscriptionLinkRequest request,
        CancellationToken cancellationToken)
    {
        if (request.UserId == Guid.Empty)
            throw new BadRequestException("UserId is required.");

        var planId = request.PlanId ?? PaymentSeedData.PremiumPlanId;
        if (request.PlanId is null && !string.IsNullOrWhiteSpace(request.PlanCode))
        {
            var plans = await _planService.GetActivePlansAsync(cancellationToken);
            var match = plans.FirstOrDefault(p =>
                string.Equals(p.Name, request.PlanCode.Trim(), StringComparison.OrdinalIgnoreCase));
            if (match is not null)
                planId = match.Id;
        }

        var result = await _payosService.CreatePaymentLinkAsync(
            request.UserId,
            new CreatePaymentLinkRequest
            {
                PlanId = planId,
                BillingCycle = request.BillingCycle,
                CouponCode = request.CouponCode,
            },
            cancellationToken);

        return StatusCode(
            StatusCodes.Status201Created,
            ApiResponse<CreatePaymentLinkResponse>.SuccessResponse(result, "Subscription payment link created."));
    }
}

public sealed class InternalCreateSubscriptionLinkRequest
{
    public Guid UserId { get; set; }

    public Guid? PlanId { get; set; }

    /// <summary>Optional plan name lookup, e.g. Premium.</summary>
    public string? PlanCode { get; set; }

    public BillingCycle BillingCycle { get; set; } = BillingCycle.Monthly;

    public string? CouponCode { get; set; }
}
