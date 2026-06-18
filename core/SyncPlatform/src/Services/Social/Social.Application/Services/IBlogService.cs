using Social.Application.Common;
using Social.Application.DTOs;

namespace Social.Application.Services;

public interface IBlogService
{
    Task<BlogDto> CreateAsync(Guid authorId, CreateBlogDto dto, CancellationToken cancellationToken = default);

    Task<BlogDto> UpdateAsync(Guid authorId, Guid blogId, UpdateBlogDto dto, CancellationToken cancellationToken = default);

    Task<BlogDto> PublishAsync(Guid authorId, Guid blogId, CancellationToken cancellationToken = default);

    Task<BlogDto> ArchiveAsync(Guid authorId, Guid blogId, CancellationToken cancellationToken = default);

    Task DeleteAsync(Guid userId, string? role, Guid blogId, CancellationToken cancellationToken = default);

    Task<BlogDto> GetByIdAsync(Guid blogId, Guid? viewerId, CancellationToken cancellationToken = default);

    Task<BlogDto> GetBySlugAsync(string slug, Guid? viewerId, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<BlogDto> Items, PaginationMetadata Pagination)> GetPublishedFeedAsync(
        BlogListQuery query,
        Guid? viewerId,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<BlogDto> Items, PaginationMetadata Pagination)> GetByAuthorAsync(
        Guid authorId,
        Guid viewerId,
        BlogListQuery query,
        CancellationToken cancellationToken = default);

    Task<BlogEngagementResultDto> LikeAsync(Guid userId, Guid blogId, CancellationToken cancellationToken = default);

    Task<BlogEngagementResultDto> ShareAsync(Guid userId, Guid blogId, CancellationToken cancellationToken = default);
}
