using System.Text.Json;
using Order.Application.DTOs;
using Order.Application.Ports;
using StackExchange.Redis;

namespace Order.Infrastructure.Redis;

public class RedisPlaceSearchCache : IPlaceSearchCache
{
    private readonly IConnectionMultiplexer _redis;

    public RedisPlaceSearchCache(IConnectionMultiplexer redis) => _redis = redis;

    private static string SearchKey(string cacheKey) => $"place-search:{cacheKey}";

    public async Task<IReadOnlyList<AddressSuggestionDto>?> GetSearchAsync(
        string cacheKey,
        CancellationToken cancellationToken = default)
    {
        var db = _redis.GetDatabase();
        var value = await db.StringGetAsync(SearchKey(cacheKey));
        if (value.IsNullOrEmpty)
            return null;

        return JsonSerializer.Deserialize<List<AddressSuggestionDto>>(value.ToString());
    }

    public async Task SetSearchAsync(
        string cacheKey,
        IReadOnlyList<AddressSuggestionDto> results,
        TimeSpan ttl,
        CancellationToken cancellationToken = default)
    {
        var db = _redis.GetDatabase();
        var json = JsonSerializer.Serialize(results);
        await db.StringSetAsync(SearchKey(cacheKey), json, ttl);
    }
}
