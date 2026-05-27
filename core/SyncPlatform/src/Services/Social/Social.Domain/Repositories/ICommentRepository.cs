using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface ICommentRepository
{
    Task<Comment> CreateAsync(Comment comment, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<Comment> Items, int TotalRecords)> GetByPostIdAsync(
        Guid postId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);
}
