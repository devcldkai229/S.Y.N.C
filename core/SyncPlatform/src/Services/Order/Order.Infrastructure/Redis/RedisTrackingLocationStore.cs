using System.Text.Json;
using Order.Application.DTOs;
using Order.Application.Ports;
using StackExchange.Redis;

namespace Order.Infrastructure.Redis;

public class RedisTrackingLocationStore : ITrackingLocationStore
{
    private const string LocationChannel = "order:tracking:location";
    private readonly IConnectionMultiplexer _redis;

    public RedisTrackingLocationStore(IConnectionMultiplexer redis) => _redis = redis;

    private static string LocationKey(Guid orderId) => $"track:{orderId:D}";

    public async Task SetLiveLocationAsync(
        Guid orderId,
        decimal lat,
        decimal lng,
        TimeSpan ttl,
        CancellationToken cancellationToken = default)
    {
        var db = _redis.GetDatabase();
        var payload = JsonSerializer.Serialize(new { lat, lng, updatedAt = DateTimeOffset.UtcNow });
        await db.StringSetAsync(LocationKey(orderId), payload, ttl);
    }

    public async Task<TrackingLocationUpdateDto?> GetLiveLocationAsync(
        Guid orderId,
        CancellationToken cancellationToken = default)
    {
        var db = _redis.GetDatabase();
        var value = await db.StringGetAsync(LocationKey(orderId));
        if (value.IsNullOrEmpty)
            return null;

        using var doc = JsonDocument.Parse(value.ToString());
        var root = doc.RootElement;
        return new TrackingLocationUpdateDto
        {
            OrderId = orderId,
            Latitude = root.GetProperty("lat").GetDecimal(),
            Longitude = root.GetProperty("lng").GetDecimal(),
            UpdatedAt = root.TryGetProperty("updatedAt", out var ua)
                ? ua.GetDateTimeOffset()
                : DateTimeOffset.UtcNow,
        };
    }

    public async Task PublishLocationUpdateAsync(TrackingLocationUpdateDto update, CancellationToken cancellationToken = default)
    {
        var sub = _redis.GetSubscriber();
        var json = JsonSerializer.Serialize(update);
        await sub.PublishAsync(RedisChannel.Literal(LocationChannel), json);
    }
}
