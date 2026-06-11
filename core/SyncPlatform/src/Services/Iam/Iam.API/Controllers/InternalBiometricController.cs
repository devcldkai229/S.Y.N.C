using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

[ApiController]
[Route("api/internal/biometrics")]
[AllowAnonymous]
public class InternalBiometricController : ControllerBase
{
    private readonly IInternalBiometricService _service;

    public InternalBiometricController(IInternalBiometricService service)
    {
        _service = service;
    }

    [HttpGet("{userId:guid}/nutrition-targets")]
    public async Task<ActionResult<ApiResponse<InternalNutritionTargetsDto>>> GetNutritionTargets(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetNutritionTargetsAsync(userId, cancellationToken);
        if (result == null)
        {
            return NotFound(ApiResponse<InternalNutritionTargetsDto>.FailureResponse(
                $"Nutrition targets not found for user {userId}."));
        }

        return Ok(ApiResponse<InternalNutritionTargetsDto>.SuccessResponse(
            result,
            "Nutrition targets retrieved successfully."));
    }
}
