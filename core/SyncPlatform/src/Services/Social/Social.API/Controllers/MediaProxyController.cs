using Libs.Storage.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Social.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/v1/media")]
public class MediaProxyController : ControllerBase
{
    private readonly S3ObjectStorage _storage;

    public MediaProxyController(S3ObjectStorage storage)
    {
        _storage = storage;
    }

    [HttpGet("{**objectPath}")]
    [ResponseCache(Duration = 3600)]
    public async Task<IActionResult> Get(string objectPath, CancellationToken cancellationToken)
    {
        var result = await _storage.TryGetObjectByPathAsync(objectPath, cancellationToken);
        if (result is null)
            return NotFound();

        return File(result.Value.Stream, result.Value.ContentType);
    }
}
