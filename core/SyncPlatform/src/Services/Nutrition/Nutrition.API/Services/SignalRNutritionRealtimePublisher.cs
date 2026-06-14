using Microsoft.AspNetCore.SignalR;
using Nutrition.API.Hubs;
using Nutrition.Application.Services;

namespace Nutrition.API.Services;

public sealed class SignalRNutritionRealtimePublisher : INutritionRealtimePublisher
{
    private readonly IHubContext<NutritionHub> _hub;

    public SignalRNutritionRealtimePublisher(IHubContext<NutritionHub> hub) => _hub = hub;

    public Task PublishNutritionUpdatedAsync(Guid userId, DateOnly date, CancellationToken cancellationToken = default) =>
        _hub.Clients
            .Group(NutritionHub.UserGroup(userId))
            .SendAsync(
                NutritionHub.UpdatedEvent,
                new { date = date.ToString("yyyy-MM-dd") },
                cancellationToken);
}
