using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Order.API.Hubs;

[Authorize]
public sealed class TrackingHub : Hub
{
    public const string HubPath = "/hubs/tracking";
    public const string LocationUpdatedEvent = "LocationUpdated";

    public static string OrderGroup(Guid orderId) => $"order:{orderId:D}";

    public async Task JoinOrderGroup(Guid orderId)
    {
        if (!TryGetUserId(out _))
            throw new HubException("Unauthorized");

        await Groups.AddToGroupAsync(Context.ConnectionId, OrderGroup(orderId));
    }

    public async Task LeaveOrderGroup(Guid orderId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, OrderGroup(orderId));
    }

    private bool TryGetUserId(out Guid userId)
    {
        userId = default;
        var raw = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? Context.User?.FindFirstValue("sub");
        return !string.IsNullOrWhiteSpace(raw) && Guid.TryParse(raw, out userId);
    }
}
