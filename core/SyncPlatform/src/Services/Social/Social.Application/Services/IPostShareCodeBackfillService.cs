using Social.Application.DTOs;

namespace Social.Application.Services;

public interface IPostShareCodeBackfillService
{
    /// <summary>
    /// Assigns unique share codes to posts that are missing one. Processes in batches until done or cancelled.
    /// </summary>
    Task<ShareCodeBackfillResult> BackfillAllAsync(CancellationToken cancellationToken = default);
}
