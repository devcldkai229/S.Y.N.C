using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Social.API.Options;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Route("api/v1/posts/maintenance")]
public class PostMaintenanceController : ControllerBase
{
    private readonly IPostShareCodeBackfillService _backfill;
    private readonly IWebHostEnvironment _environment;
    private readonly SocialMaintenanceOptions _options;

    public PostMaintenanceController(
        IPostShareCodeBackfillService backfill,
        IWebHostEnvironment environment,
        IOptions<SocialMaintenanceOptions> options)
    {
        _backfill = backfill;
        _environment = environment;
        _options = options.Value;
    }

    /// <summary>
    /// Assigns share codes to legacy posts. Allowed in Development or when
    /// <c>Social:Maintenance:AllowShareCodeBackfillApi</c> is true.
    /// </summary>
    [HttpPost("backfill-share-codes")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<ShareCodeBackfillResult>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<ShareCodeBackfillResult>>> BackfillShareCodes(
        CancellationToken cancellationToken)
    {
        if (!_environment.IsDevelopment() && !_options.AllowShareCodeBackfillApi)
            return NotFound();

        var result = await _backfill.BackfillAllAsync(cancellationToken);
        return Ok(ApiResponse<ShareCodeBackfillResult>.SuccessResponse(
            result,
            result.Message));
    }
}
