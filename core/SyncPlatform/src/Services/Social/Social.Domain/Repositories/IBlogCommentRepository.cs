using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface IBlogCommentRepository
{
    Task<BlogComment> CreateAsync(BlogComment comment, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<BlogComment> Items, int TotalRecords)> GetByBlogIdAsync(
        Guid blogId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);
}
