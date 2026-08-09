using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/internal/social/users")]
public class InternalAccountAnonymizationController : ControllerBase
{
    private readonly IAccountAnonymizationService _anonymization;

    public InternalAccountAnonymizationController(IAccountAnonymizationService anonymization)
    {
        _anonymization = anonymization;
    }

    [HttpPost("{userId:guid}/anonymize")]
    public async Task<ActionResult<ApiResponse<object?>>> Anonymize(
        Guid userId,
        CancellationToken cancellationToken)
    {
        await _anonymization.AnonymizeUserContentAsync(userId, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "User content anonymized."));
    }
}
