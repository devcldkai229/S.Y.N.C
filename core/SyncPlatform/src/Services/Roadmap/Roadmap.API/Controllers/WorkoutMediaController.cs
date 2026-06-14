using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Roadmap.API.Configuration;
using Roadmap.API.Services;
using Roadmap.Application.Common;

namespace Roadmap.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/workouts/media")]
public class WorkoutMediaController : ControllerBase
{
    private readonly IWorkoutMediaStorage _storage;
    private readonly MinioOptions _options;

    public WorkoutMediaController(IWorkoutMediaStorage storage, IOptions<MinioOptions> options)
    {
        _storage = storage;
        _options = options.Value;
    }

    [HttpPost("upload")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<string>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<string>>>> Upload(
        [FromForm] List<IFormFile>? files,
        CancellationToken cancellationToken)
    {
        if (files is null || files.Count == 0)
            return BadRequest(ApiResponse<IReadOnlyList<string>>.FailureResponse("At least one file is required."));

        var maxBytes = _options.MaxFileSizeMb * 1024L * 1024L;
        var urls = new List<string>(files.Count);

        foreach (var file in files)
        {
            if (file.Length <= 0)
                return BadRequest(ApiResponse<IReadOnlyList<string>>.FailureResponse("Empty file is not allowed."));
            if (file.Length > maxBytes)
                return BadRequest(ApiResponse<IReadOnlyList<string>>.FailureResponse(
                    $"File '{file.FileName}' is too large. Max: {_options.MaxFileSizeMb}MB."));
            if (!_options.AllowedImageContentTypes.Contains(file.ContentType, StringComparer.OrdinalIgnoreCase))
                return BadRequest(ApiResponse<IReadOnlyList<string>>.FailureResponse(
                    $"Content type '{file.ContentType}' is not allowed."));

            var ext = Path.GetExtension(file.FileName);
            if (string.IsNullOrWhiteSpace(ext) && !string.IsNullOrWhiteSpace(file.ContentType))
                ext = $".{file.ContentType.Split('/').Last()}";

            var objectName = $"workouts/{Guid.NewGuid():N}{ext}";
            await using var stream = file.OpenReadStream();
            var url = await _storage.UploadAsync(
                stream,
                file.Length,
                objectName,
                file.ContentType ?? "application/octet-stream",
                cancellationToken);
            urls.Add(url);
        }

        return Ok(ApiResponse<IReadOnlyList<string>>.SuccessResponse(urls, "Workout cover uploaded."));
    }
}
