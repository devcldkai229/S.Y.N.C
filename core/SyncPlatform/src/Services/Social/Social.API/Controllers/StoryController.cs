using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Social.Application.Common;
using Social.Application.Configuration;
using Social.Application.DTOs;
using Social.Application.Services;
using Social.Domain.Enums;

namespace Social.API.Controllers;

[ApiController]
[Route("api/v1/social/stories")]
public class StoryController : ControllerBase
{
    private readonly IStoryService _stories;
    private readonly ICurrentUserContext _currentUser;
    private readonly MinioOptions _minioOptions;

    public StoryController(
        IStoryService stories,
        ICurrentUserContext currentUser,
        IOptions<MinioOptions> minioOptions)
    {
        _stories = stories;
        _currentUser = currentUser;
        _minioOptions = minioOptions.Value;
    }

    /// <summary>Upload media to MinIO and create a story (24h expiry).</summary>
    [HttpPost]
    [Authorize]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<ApiResponse<StoryDto>>> Create(
        [FromForm] IFormFile? file,
        [FromForm] string? caption,
        [FromForm] PrivacyType privacy = PrivacyType.Public,
        [FromForm] string? authorFullName = null,
        [FromForm] string? authorAvatarUrl = null,
        CancellationToken cancellationToken = default)
    {
        if (file is not null)
        {
            if (file.Length <= 0)
                return BadRequest(ApiResponse<StoryDto>.FailureResponse("Empty file is not allowed."));

            var maxBytes = _minioOptions.MaxFileSizeMb * 1024L * 1024L;
            if (file.Length > maxBytes)
                return BadRequest(ApiResponse<StoryDto>.FailureResponse(
                    $"File is too large. Max allowed: {_minioOptions.MaxFileSizeMb}MB."));

            if (!IsAllowedContentType(file.ContentType))
                return BadRequest(ApiResponse<StoryDto>.FailureResponse(
                    $"Content type '{file.ContentType}' is not allowed for stories."));
        }

        var dto = new CreateStoryDto
        {
            Caption = caption,
            Privacy = privacy,
            AuthorSnapshot = new AuthorSnapshotDto
            {
                FullName = authorFullName ?? string.Empty,
                AvatarUrl = authorAvatarUrl,
            },
        };

        Stream? stream = null;
        if (file is not null)
            stream = file.OpenReadStream();

        try
        {
            var story = await _stories.CreateAsync(
                _currentUser.RequireUserId(),
                dto,
                stream,
                file?.Length,
                file?.FileName,
                file?.ContentType,
                cancellationToken);

            return Ok(ApiResponse<StoryDto>.SuccessResponse(story, "Story created successfully."));
        }
        finally
        {
            if (stream is not null)
                await stream.DisposeAsync();
        }
    }

    /// <summary>Active, non-expired stories for a user (privacy-filtered).</summary>
    [HttpGet("user/{userId:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<StoryDto>>>> GetByUser(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var stories = await _stories.GetActiveByUserAsync(
            userId,
            _currentUser.UserId,
            cancellationToken);

        return Ok(ApiResponse<IReadOnlyList<StoryDto>>.SuccessResponse(
            stories,
            "User stories retrieved successfully."));
    }

    /// <summary>Active stories for the authenticated user (for create-story card preview).</summary>
    [HttpGet("me")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<StoryDto>>>> GetMine(
        CancellationToken cancellationToken)
    {
        var userId = _currentUser.RequireUserId();
        var stories = await _stories.GetActiveByUserAsync(userId, userId, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<StoryDto>>.SuccessResponse(
            stories,
            "My stories retrieved successfully."));
    }

    /// <summary>Stories feed from followed users, grouped by author.</summary>
    [HttpGet("feed")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<StoryFeedGroupDto>>>> GetFeed(
        CancellationToken cancellationToken)
    {
        var feed = await _stories.GetFeedAsync(_currentUser.RequireUserId(), cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<StoryFeedGroupDto>>.SuccessResponse(
            feed,
            "Stories feed retrieved successfully."));
    }

    [HttpPost("{storyId:guid}/view")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<StoryViewResultDto>>> View(
        Guid storyId,
        CancellationToken cancellationToken)
    {
        var result = await _stories.ViewAsync(
            _currentUser.RequireUserId(),
            storyId,
            cancellationToken);

        return Ok(ApiResponse<StoryViewResultDto>.SuccessResponse(result, "Story view recorded."));
    }

    [HttpPost("{storyId:guid}/like")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<StoryLikeResultDto>>> Like(
        Guid storyId,
        CancellationToken cancellationToken)
    {
        var result = await _stories.LikeAsync(
            _currentUser.RequireUserId(),
            storyId,
            cancellationToken);

        return Ok(ApiResponse<StoryLikeResultDto>.SuccessResponse(result, "Story liked successfully."));
    }

    [HttpDelete("{storyId:guid}")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(
        Guid storyId,
        CancellationToken cancellationToken)
    {
        await _stories.DeleteAsync(_currentUser.RequireUserId(), storyId, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Story deleted successfully."));
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
