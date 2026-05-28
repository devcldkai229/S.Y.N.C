using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Libs.Auth.Context;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Social.Application.Common;
using Social.Application.Configuration;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/posts/media")]
public class PostMediaController : ControllerBase
{
    private readonly IStorageService _storage;
    private readonly MinioOptions _minioOptions;

    public PostMediaController(
        IStorageService storage,
        IOptions<MinioOptions> minioOptions)
    {
        _storage = storage;
        _minioOptions = minioOptions.Value;
    }

    [HttpPost("upload")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<string>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<string>>>> Upload(
        [FromForm] List<IFormFile>? files,
        CancellationToken cancellationToken)
    {
        if (files is null || files.Count == 0)
            return BadRequest(ApiResponse<IReadOnlyList<string>>.FailureResponse("At least one file is required."));

        // Basic pre-validation to fail fast before streaming to MinIO.
        foreach (var f in files)
        {
            if (f.Length <= 0)
                return BadRequest(ApiResponse<IReadOnlyList<string>>.FailureResponse("Empty file is not allowed."));

            var maxBytes = _minioOptions.MaxFileSizeMb * 1024L * 1024L;
            if (f.Length > maxBytes)
                return BadRequest(ApiResponse<IReadOnlyList<string>>.FailureResponse(
                    $"File '{f.FileName}' is too large. Max allowed: {_minioOptions.MaxFileSizeMb}MB."));
        }

        var urls = new List<string>(files.Count);

        foreach (var f in files)
        {
            var ext = Path.GetExtension(f.FileName);
            if (string.IsNullOrWhiteSpace(ext))
                ext = string.IsNullOrWhiteSpace(f.ContentType) ? string.Empty : $".{f.ContentType.Split('/').Last()}";

            // Prevent path traversal / weird characters.
            var safeName = $"{Guid.NewGuid():N}{ext}";
            var contentType = string.IsNullOrWhiteSpace(f.ContentType) ? "application/octet-stream" : f.ContentType!;

            await using var stream = f.OpenReadStream();

            var url = await _storage.UploadFileAsync(
                stream,
                f.Length,
                safeName,
                contentType,
                cancellationToken);

            urls.Add(url);
        }

        return Ok(ApiResponse<IReadOnlyList<string>>.SuccessResponse(urls, "Media uploaded successfully."));
    }
}

