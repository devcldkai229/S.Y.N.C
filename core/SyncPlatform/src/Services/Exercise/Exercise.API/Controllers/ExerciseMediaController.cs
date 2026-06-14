using Exercise.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Exercise.API.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/v1/exercises/media")]
public class ExerciseMediaController : ControllerBase
{
    private readonly IStorageService _storage;

    public ExerciseMediaController(IStorageService storage)
    {
        _storage = storage;
    }

    [HttpGet("{**objectKey}")]
    [ResponseCache(Duration = 3600)]
    public async Task<IActionResult> GetObject(string objectKey, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(objectKey))
            return BadRequest();

        var result = await _storage.TryOpenObjectAsync(objectKey, cancellationToken);
        if (result == null)
            return NotFound();

        return File(result.Value.Stream, result.Value.ContentType);
    }
}
