using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Order.Infrastructure.Persistence;

namespace Order.API.Hubs;

[Authorize]
public sealed class TrackingHub : Hub
{
    public const string HubPath = "/hubs/tracking";
    public const string LocationUpdatedEvent = "LocationUpdated";
    public const string LocationUpdateEvent = "locationUpdate";
    public const string StatusUpdateEvent = "statusUpdate";

    private readonly IServiceScopeFactory _scopeFactory;

    public TrackingHub(IServiceScopeFactory scopeFactory) => _scopeFactory = scopeFactory;

    public static string OrderGroup(Guid orderId) => $"order:{orderId:D}";

    public async Task JoinOrderGroup(Guid orderId)
    {
        if (!TryGetUserId(out var userId))
            throw new HubException("Unauthorized");

        await using var scope = _scopeFactory.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<OrderDbContext>();
        var ownsOrder = await db.Orders.AsNoTracking()
            .AnyAsync(o => o.Id == orderId && o.UserId == userId);

        if (!ownsOrder)
            throw new HubException("Forbidden");

        await Groups.AddToGroupAsync(Context.ConnectionId, OrderGroup(orderId));
    }

    public Task LeaveOrderGroup(Guid orderId) =>
        Groups.RemoveFromGroupAsync(Context.ConnectionId, OrderGroup(orderId));

    private bool TryGetUserId(out Guid userId)
    {
        userId = default;
        var raw = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? Context.User?.FindFirstValue("sub");
        return !string.IsNullOrWhiteSpace(raw) && Guid.TryParse(raw, out userId);
    }
}
