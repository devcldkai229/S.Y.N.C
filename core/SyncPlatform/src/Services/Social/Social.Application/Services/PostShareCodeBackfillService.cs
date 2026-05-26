using Social.Application.DTOs;
using Social.Application.Helpers;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public class PostShareCodeBackfillService : IPostShareCodeBackfillService
{
    private const int BatchSize = 100;

    private readonly IPostRepository _posts;

    public PostShareCodeBackfillService(IPostRepository posts)
    {
        _posts = posts;
    }

    public async Task<ShareCodeBackfillResult> BackfillAllAsync(CancellationToken cancellationToken = default)
    {
        var updated = 0;

        while (!cancellationToken.IsCancellationRequested)
        {
            var batch = await _posts.GetPostsWithoutShareCodeAsync(BatchSize, cancellationToken);
            if (batch.Count == 0)
                break;

            foreach (var post in batch)
            {
                cancellationToken.ThrowIfCancellationRequested();
                await ShareCodeGenerator.AssignUniqueToPostAsync(_posts, post, cancellationToken);
                await _posts.UpdateAsync(post.Id, post, cancellationToken);
                updated++;
            }
        }

        var remaining = (await _posts.GetPostsWithoutShareCodeAsync(1, cancellationToken)).Count;

        return new ShareCodeBackfillResult(
            Updated: updated,
            Remaining: remaining,
            Message: remaining == 0
                ? "All posts now have share codes."
                : "Backfill completed; some posts may still need another run.");
    }
}
