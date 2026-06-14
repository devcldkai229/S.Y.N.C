using System.Text.Json;
using Order.Application.DTOs;
using Order.Application.Ports;
using StackExchange.Redis;

namespace Order.Infrastructure.Redis;

public class RedisDeliveryAddressStore : IDeliveryAddressStore
{
    private static readonly TimeSpan AddressTtl = TimeSpan.FromHours(24);
    private readonly IConnectionMultiplexer _redis;

    public RedisDeliveryAddressStore(IConnectionMultiplexer redis) => _redis = redis;

    private static string AddressKey(Guid userId) => $"delivery-address:{userId:D}";

    public async Task<DeliveryAddressDto?> GetAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var db = _redis.GetDatabase();
        var value = await db.StringGetAsync(AddressKey(userId));
        if (value.IsNullOrEmpty)
            return null;

        return JsonSerializer.Deserialize<DeliveryAddressDto>(value.ToString());
    }

    public async Task SaveAsync(Guid userId, DeliveryAddressDto address, CancellationToken cancellationToken = default)
    {
        var db = _redis.GetDatabase();
        var json = JsonSerializer.Serialize(address);
        await db.StringSetAsync(AddressKey(userId), json, AddressTtl);
    }

    public async Task DeleteAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var db = _redis.GetDatabase();
        await db.KeyDeleteAsync(AddressKey(userId));
    }
}
