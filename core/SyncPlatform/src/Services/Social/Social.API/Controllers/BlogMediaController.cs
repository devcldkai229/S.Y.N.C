using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Social.Application.Common;
using Social.Application.Configuration;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/social/blogs/media")]
public class BlogMediaController : ControllerBase
{
    private readonly IStorageService _storage;
    private readonly MinioOptions _minioOptions;

    public BlogMediaController(IStorageService storage, IOptions<MinioOptions> minioOptions)
    {
        _storage = storage;
        _minioOptions = minioOptions.Value;
    }

    /// <summary>Upload cover image or inline media to MinIO; returns URLs for the client to attach.</summary>
    [HttpPost("upload")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<string>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<string>>>> Upload(
        [FromForm] List<IFormFile>? files,
        CancellationToken cancellationToken)
    {
        if (files is null || files.Count == 0)
            return BadRequest(ApiResponse<IReadOnlyList<string>>.FailureResponse("At least one file is required."));

        foreach (var file in files)
        {
            if (file.Length <= 0)
                return BadRequest(ApiResponse<IReadOnlyList<string>>.FailureResponse("Empty file is not allowed."));

            var maxBytes = _minioOptions.MaxFileSizeMb * 1024L * 1024L;
            if (file.Length > maxBytes)
            {
                return BadRequest(ApiResponse<IReadOnlyList<string>>.FailureResponse(
                    $"File '{file.FileName}' is too large. Max allowed: {_minioOptions.MaxFileSizeMb}MB."));
            }

            if (!IsAllowedContentType(file.ContentType))
            {
                return BadRequest(ApiResponse<IReadOnlyList<string>>.FailureResponse(
                    $"Content type '{file.ContentType}' is not allowed for blog media."));
            }
        }

        var urls = new List<string>(files.Count);

        foreach (var file in files)
        {
            var ext = Path.GetExtension(file.FileName);
            if (string.IsNullOrWhiteSpace(ext) && !string.IsNullOrWhiteSpace(file.ContentType))
                ext = $".{file.ContentType.Split('/').Last()}";

            var objectName = $"blogs/{Guid.NewGuid():N}{ext}";
            var contentType = string.IsNullOrWhiteSpace(file.ContentType)
                ? "application/octet-stream"
                : file.ContentType;

            await using var stream = file.OpenReadStream();
            var url = await _storage.UploadFileAsync(stream, file.Length, objectName, contentType, cancellationToken);
            urls.Add(url);
        }

        return Ok(ApiResponse<IReadOnlyList<string>>.SuccessResponse(urls, "Blog media uploaded successfully."));
    }

    private bool IsAllowedContentType(string? contentType)
    {
        if (string.IsNullOrWhiteSpace(contentType))
            return false;

        if (_minioOptions.AllowedImageContentTypes.Contains(contentType, StringComparer.OrdinalIgnoreCase))
            return true;

        return _minioOptions.AllowedVideoContentTypes.Contains(contentType, StringComparer.OrdinalIgnoreCase);
    }
}
