using Social.Domain.Enums;
using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface IBlogRepository
{
    Task<Blog?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<Blog?> GetBySlugAsync(string slug, CancellationToken cancellationToken = default);

    Task<bool> SlugExistsAsync(string slug, Guid? excludeBlogId = null, CancellationToken cancellationToken = default);

    Task CreateAsync(Blog blog, CancellationToken cancellationToken = default);

    Task UpdateAsync(Blog blog, CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<Blog> Items, int TotalRecords)> GetPublishedAsync(
        int pageNumber,
        int pageSize,
        string? tag,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<Blog> Items, int TotalRecords)> GetByAuthorAsync(
        Guid authorId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<bool> IncrementLikeCountAsync(Guid blogId, CancellationToken cancellationToken = default);

    Task<bool> IncrementShareCountAsync(Guid blogId, CancellationToken cancellationToken = default);
}
