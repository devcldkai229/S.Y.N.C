using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface ITrendingPostRepository
{
    Task ReplaceAllAsync(IReadOnlyList<TrendingPost> items, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<TrendingPost>> GetCursorAsync(
        double? scoreCursor,
        Guid? idCursor,
        int limit,
        CancellationToken cancellationToken = default);
}
