using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Exercise.Application.Common;
using Exercise.Application.DTOs;
using Exercise.Application.Exceptions;
using Exercise.Application.Services;
using Exercise.API.Models;
using Libs.Auth.Constants;
using Libs.Shared.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Exercise.API.Controllers;

[ApiController]
[Authorize(Policy = AuthPolicies.AuthenticatedUser)]
[Route("api/v1")]
public class ExerciseMotionAssetController : ControllerBase
{
    private readonly IExerciseMotionAssetService _service;

    public ExerciseMotionAssetController(IExerciseMotionAssetService service)
    {
        _service = service;
    }

    [HttpGet("exercises/{exerciseId:guid}/motion-assets")]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<ExerciseMotionAssetDto>>>> GetByExercise(Guid exerciseId, CancellationToken cancellationToken)
    {
        var result = await _service.GetByExerciseIdAsync(exerciseId, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<ExerciseMotionAssetDto>>.SuccessResponse(result, "Motion assets retrieved successfully."));
    }

    [HttpGet("motion-assets/{id:guid}")]
    public async Task<ActionResult<ApiResponse<ExerciseMotionAssetDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<ExerciseMotionAssetDto>.SuccessResponse(result, "Motion asset retrieved successfully."));
    }

    [HttpPost("exercises/{exerciseId:guid}/motion-assets")]
    [Authorize(Policy = AuthPolicies.AdminOnly)]
    public async Task<ActionResult<ApiResponse<ExerciseMotionAssetDto>>> Create(Guid exerciseId, [FromBody] CreateExerciseMotionAssetDto dto, CancellationToken cancellationToken)
    {
        if (exerciseId != dto.ExerciseId)
        {
            throw new BadRequestException("ExerciseId in route does not match dto.");
        }

        var result = await _service.CreateAsync(dto, cancellationToken);
        var response = ApiResponse<ExerciseMotionAssetDto>.SuccessResponse(result, "Motion asset created successfully.");
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, response);
    }

    [HttpPut("motion-assets/{id:guid}")]
    [Authorize(Policy = AuthPolicies.AdminOnly)]
    public async Task<ActionResult<ApiResponse<object?>>> Update(Guid id, [FromBody] UpdateExerciseMotionAssetDto dto, CancellationToken cancellationToken)
    {
        await _service.UpdateAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Motion asset updated successfully."));
    }

    [HttpDelete("motion-assets/{id:guid}")]
    [Authorize(Policy = AuthPolicies.AdminOnly)]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _service.DeleteAsync(id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Motion asset deleted successfully."));
    }

    [HttpPost("exercises/{exerciseId:guid}/motion-assets/upload")]
    [Authorize(Policy = AuthPolicies.AdminOnly)]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<ApiResponse<ExerciseMotionAssetDto>>> UploadAsset(
        Guid exerciseId,
        [FromForm] ExerciseMotionAssetUploadRequest request,
        CancellationToken cancellationToken)
    {
        if (request.File == null || request.File.Length == 0)
        {
            throw new BadRequestException("File is empty.");
        }

        using var fileStream = request.File.OpenReadStream();
        Stream? thumbnailStream = null;
        if (request.ThumbnailFile != null && request.ThumbnailFile.Length > 0)
        {
            thumbnailStream = request.ThumbnailFile.OpenReadStream();
        }

        try
        {
            var uploadDto = new CreateExerciseMotionAssetUploadDto
            {
                ExerciseId = exerciseId,
                AssetType = request.AssetType,
                FileName = request.File.FileName,
                FileStream = fileStream,
                ContentType = request.File.ContentType,
                FileSize = request.File.Length,
                ThumbnailFileName = request.ThumbnailFile?.FileName,
                ThumbnailStream = thumbnailStream,
                ThumbnailContentType = request.ThumbnailFile?.ContentType,
                ThumbnailSize = request.ThumbnailFile?.Length,
                UnityPrefabId = request.UnityPrefabId,
                UnityAnimationClip = request.UnityAnimationClip,
                AnimationDurationSeconds = request.AnimationDurationSeconds
            };

            var result = await _service.CreateWithUploadAsync(uploadDto, cancellationToken);
            var response = ApiResponse<ExerciseMotionAssetDto>.SuccessResponse(result, "Motion asset uploaded and created successfully.");
            return CreatedAtAction(nameof(GetById), new { id = result.Id }, response);
        }
        finally
        {
            if (thumbnailStream != null)
            {
                await thumbnailStream.DisposeAsync();
            }
        }
    }
}
