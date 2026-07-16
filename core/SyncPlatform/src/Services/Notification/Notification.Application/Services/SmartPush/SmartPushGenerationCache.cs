using System.Collections.Concurrent;
using Microsoft.Extensions.Options;
using Notification.Application.Options;

namespace Notification.Application.Services.SmartPush;

public interface ISmartPushGenerationCache
{
    bool TryGet(string key, out (string Title, string Body) value);
    void Set(string key, string title, string body);
}

public class SmartPushGenerationCache : ISmartPushGenerationCache
{
    private readonly ConcurrentDictionary<string, CacheEntry> _cache = new();
    private readonly SmartPushOptions _options;

    private sealed record CacheEntry(string Title, string Body, DateTimeOffset ExpiresAt);

    public SmartPushGenerationCache(IOptions<SmartPushOptions> options) => _options = options.Value;

    public bool TryGet(string key, out (string Title, string Body) value)
    {
        value = default;
        if (!_cache.TryGetValue(key, out var entry)) return false;
        if (entry.ExpiresAt < DateTimeOffset.UtcNow)
        {
            _cache.TryRemove(key, out _);
            return false;
        }
        value = (entry.Title, entry.Body);
        return true;
    }

    public void Set(string key, string title, string body)
    {
        var ttl = TimeSpan.FromMinutes(Math.Max(1, _options.GenerationCacheTtlMinutes));
        _cache[key] = new CacheEntry(title, body, DateTimeOffset.UtcNow.Add(ttl));
    }
}
