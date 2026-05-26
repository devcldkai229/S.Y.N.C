using Libs.Auth.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Services;

namespace Social.API.Controllers;

[ApiController]
[Route("api/v1/posts")]
public class PostController : ControllerBase
{
    private const int DefaultFeedLimit = 20;
    private const int MaxFeedLimit = 50;

    private readonly IPostService _posts;
    private readonly ICurrentUserContext _currentUser;

    public PostController(IPostService posts, ICurrentUserContext currentUser)
    {
        _posts = posts;
        _currentUser = currentUser;
    }

    /// <summary>
    /// Community feed (cursor pagination). Pass <c>cursor</c> = CreatedAt (ISO-8601) of the last post seen.
    /// </summary>
    [HttpGet("feed")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(CursorApiResponse<IReadOnlyList<PostDto>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<CursorApiResponse<IReadOnlyList<PostDto>>>> GetFeed(
        [FromQuery] DateTimeOffset? cursor,
        [FromQuery] int limit = DefaultFeedLimit,
        CancellationToken cancellationToken = default)
    {
        var clampedLimit = limit < 1 ? DefaultFeedLimit : Math.Min(limit, MaxFeedLimit);

        var result = await _posts.GetPublicFeedCursorAsync(
            new FeedCursorQuery { Cursor = cursor, Limit = clampedLimit },
            cancellationToken);

        return Ok(CursorApiResponse<IReadOnlyList<PostDto>>.SuccessResponse(
            result.Items,
            result.NextCursor,
            "Feed retrieved successfully."));
    }

    /// <summary>
    /// Own profile wall (JWT) — public and private posts. Same cursor params as <c>user/{userId}</c>.
    /// </summary>
    [HttpGet("me/wall")]
    [ProducesResponseType(typeof(CursorApiResponse<IReadOnlyList<PostDto>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<CursorApiResponse<IReadOnlyList<PostDto>>>> GetMyWall(
        [FromQuery] DateTimeOffset? cursor,
        [FromQuery] int limit = DefaultFeedLimit,
        [FromQuery] bool onlyMedia = false,
        CancellationToken cancellationToken = default)
    {
        var clampedLimit = limit < 1 ? DefaultFeedLimit : Math.Min(limit, MaxFeedLimit);
        var ownerId = _currentUser.RequireUserId();

        var result = await _posts.GetMyWallCursorAsync(
            ownerId,
            new UserWallQuery { Cursor = cursor, Limit = clampedLimit, OnlyMedia = onlyMedia },
            cancellationToken);

        return Ok(CursorApiResponse<IReadOnlyList<PostDto>>.SuccessResponse(
            result.Items,
            result.NextCursor,
            "Your wall posts retrieved successfully."));
    }

    /// <summary>
    /// Public profile wall — cursor pagination; set <c>onlyMedia=true</c> for photo gallery tab.
    /// </summary>
    [HttpGet("user/{userId:guid}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(CursorApiResponse<IReadOnlyList<PostDto>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<CursorApiResponse<IReadOnlyList<PostDto>>>> GetUserWall(
        Guid userId,
        [FromQuery] DateTimeOffset? cursor,
        [FromQuery] int limit = DefaultFeedLimit,
        [FromQuery] bool onlyMedia = false,
        CancellationToken cancellationToken = default)
    {
        var clampedLimit = limit < 1 ? DefaultFeedLimit : Math.Min(limit, MaxFeedLimit);

        var result = await _posts.GetUserWallCursorAsync(
            userId,
            new UserWallQuery { Cursor = cursor, Limit = clampedLimit, OnlyMedia = onlyMedia },
            cancellationToken);

        return Ok(CursorApiResponse<IReadOnlyList<PostDto>>.SuccessResponse(
            result.Items,
            result.NextCursor,
            "User posts retrieved successfully."));
    }

    /// <summary>Resolve a post from a deep-link share code (8 alphanumeric characters).</summary>
    [HttpGet("share/{shareCode}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<PostDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ApiResponse<PostDto>>> GetByShareCode(
        string shareCode,
        CancellationToken cancellationToken)
    {
        var post = await _posts.GetByShareCodeAsync(shareCode, cancellationToken);
        return Ok(ApiResponse<PostDto>.SuccessResponse(post, "Post retrieved successfully."));
    }

    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<PostDto>>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var post = await _posts.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<PostDto>.SuccessResponse(post, "Post retrieved successfully."));
    }

    /// <summary>
    /// Deprecated — use <c>GET /api/v1/posts/user/{userId}</c> (cursor pagination).
    /// </summary>
    [HttpGet("authors/{authorId:guid}")]
    [AllowAnonymous]
    [Obsolete("Use GET /api/v1/posts/user/{userId} with cursor and limit query parameters.")]
    [ProducesResponseType(typeof(CursorApiResponse<IReadOnlyList<PostDto>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<CursorApiResponse<IReadOnlyList<PostDto>>>> GetByAuthor(
        Guid authorId,
        [FromQuery] DateTimeOffset? cursor,
        [FromQuery] int limit = DefaultFeedLimit,
        [FromQuery] bool onlyMedia = false,
        CancellationToken cancellationToken = default)
    {
        var clampedLimit = limit < 1 ? DefaultFeedLimit : Math.Min(limit, MaxFeedLimit);

        var result = await _posts.GetUserWallCursorAsync(
            authorId,
            new UserWallQuery { Cursor = cursor, Limit = clampedLimit, OnlyMedia = onlyMedia },
            cancellationToken);

        Response.Headers.Append("Deprecation", "true");
        Response.Headers.Append("Link", "</api/v1/posts/user/{userId}>; rel=\"successor-version\"");

        return Ok(CursorApiResponse<IReadOnlyList<PostDto>>.SuccessResponse(
            result.Items,
            result.NextCursor,
            "Author posts retrieved successfully. This endpoint is deprecated; use GET /api/v1/posts/user/{userId}."));
    }

    [HttpPost("{postId:guid}/like")]
    public async Task<ActionResult<ApiResponse<LikePostResultDto>>> Like(
        Guid postId,
        CancellationToken cancellationToken)
    {
        var result = await _posts.LikePostAsync(_currentUser.RequireUserId(), postId, cancellationToken);
        return Ok(ApiResponse<LikePostResultDto>.SuccessResponse(result, "Post liked successfully."));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<PostDto>>> Create(
        [FromBody] CreatePostDto dto,
        CancellationToken cancellationToken)
    {
        var post = await _posts.CreateAsync(_currentUser.RequireUserId(), dto, cancellationToken);
        return Ok(ApiResponse<PostDto>.SuccessResponse(post, "Post created successfully."));
    }

    [HttpDelete("{id:guid}")]
    public async Task<ActionResult<ApiResponse<object?>>> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _posts.DeleteAsync(_currentUser.RequireUserId(), id, cancellationToken);
        return Ok(ApiResponse<object?>.SuccessResponse(null, "Post deleted successfully."));
    }
}
