using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iam.API.Controllers;

[ApiController]
[Route("api/internal/users")]
[AllowAnonymous]
public class InternalUserController : ControllerBase
{
    private readonly IInternalUserService _service;

    public InternalUserController(IInternalUserService service)
    {
        _service = service;
    }

    [HttpGet("{userId:guid}/author-snapshot")]
    public async Task<ActionResult<ApiResponse<InternalAuthorSnapshotDto>>> GetAuthorSnapshot(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetAuthorSnapshotAsync(userId, cancellationToken);
        if (result == null)
        {
            return NotFound(ApiResponse<InternalAuthorSnapshotDto>.FailureResponse(
                $"User {userId} not found."));
        }

        return Ok(ApiResponse<InternalAuthorSnapshotDto>.SuccessResponse(
            result,
            "Author snapshot retrieved successfully."));
    }
}
