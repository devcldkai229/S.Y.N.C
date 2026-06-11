using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Notification.API.Hubs;

[Authorize]
public sealed class NotificationHub : Hub
{
    public const string HubPath = "/hubs/notifications";
    public const string ReceivedEvent = "NotificationReceived";

    public static string UserGroup(Guid userId) => $"user:{userId:D}";

    public override async Task OnConnectedAsync()
    {
        if (TryGetUserId(out var userId))
            await Groups.AddToGroupAsync(Context.ConnectionId, UserGroup(userId));

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        if (TryGetUserId(out var userId))
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, UserGroup(userId));

        await base.OnDisconnectedAsync(exception);
    }

    private bool TryGetUserId(out Guid userId)
    {
        userId = default;
        var raw = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? Context.User?.FindFirstValue("sub");

        return !string.IsNullOrWhiteSpace(raw) && Guid.TryParse(raw, out userId);
    }
}
