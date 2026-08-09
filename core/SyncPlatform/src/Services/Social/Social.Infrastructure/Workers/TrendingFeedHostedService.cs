using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Infrastructure.Workers;

/// <summary>
/// Periodically recomputes trending_posts with Hacker-News-style time-decay score.
/// score = (likes + 2*comments + 3*shares + 1) / pow(ageHours + 2, 1.5)
/// </summary>
public sealed class TrendingFeedHostedService : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(10);
    private const double Gravity = 1.5;
    private const int LookbackDays = 7;
    private const int MaxPosts = 500;

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<TrendingFeedHostedService> _logger;

    public TrendingFeedHostedService(
        IServiceScopeFactory scopeFactory,
        ILogger<TrendingFeedHostedService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Initial delay so API can finish startup
        await Task.Delay(TimeSpan.FromSeconds(15), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RecomputeAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogWarning(ex, "Trending feed recompute failed");
            }

            await Task.Delay(Interval, stoppingToken);
        }
    }

    private async Task RecomputeAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var posts = scope.ServiceProvider.GetRequiredService<IPostRepository>();
        var trending = scope.ServiceProvider.GetRequiredService<ITrendingPostRepository>();

        var since = DateTimeOffset.UtcNow.AddDays(-LookbackDays);
        var recent = await posts.GetRecentPublicPostsAsync(since, MaxPosts, cancellationToken);
        var now = DateTimeOffset.UtcNow;

        var items = recent
            .Select(p =>
            {
                var ageHours = Math.Max(0, (now - p.CreatedAt).TotalHours);
                var engagement = p.Metrics.LikeCount
                    + 2 * p.Metrics.CommentCount
                    + 3 * p.Metrics.ShareCount
                    + 1;
                var score = engagement / Math.Pow(ageHours + 2, Gravity);
                return new TrendingPost
                {
                    PostId = p.Id,
                    Score = score,
                    ComputedAt = now,
                    Snapshot = p,
                };
            })
            .OrderByDescending(x => x.Score)
            .ToList();

        await trending.ReplaceAllAsync(items, cancellationToken);
        _logger.LogInformation("Trending feed recomputed: {Count} posts", items.Count);
    }
}
