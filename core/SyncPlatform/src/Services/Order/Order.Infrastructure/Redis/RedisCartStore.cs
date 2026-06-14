using System.Text.Json;
using Order.Application.DTOs;
using Order.Application.Ports;
using StackExchange.Redis;

namespace Order.Infrastructure.Redis;

public class RedisCartStore : ICartStore
{
    private static readonly TimeSpan CartTtl = TimeSpan.FromDays(7);
    private readonly IConnectionMultiplexer _redis;

    public RedisCartStore(IConnectionMultiplexer redis) => _redis = redis;

    private static string CartKey(Guid userId) => $"cart:{userId:D}";

    public async Task<CartDto?> GetAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var db = _redis.GetDatabase();
        var value = await db.StringGetAsync(CartKey(userId));
        if (value.IsNullOrEmpty)
            return null;

        return JsonSerializer.Deserialize<CartDto>(value.ToString());
    }

    public async Task SaveAsync(Guid userId, CartDto cart, CancellationToken cancellationToken = default)
    {
        var db = _redis.GetDatabase();
        var json = JsonSerializer.Serialize(cart);
        await db.StringSetAsync(CartKey(userId), json, CartTtl);
    }

    public async Task DeleteAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var db = _redis.GetDatabase();
        await db.KeyDeleteAsync(CartKey(userId));
    }
}
