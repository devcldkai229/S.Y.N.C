namespace Nutrition.Application.Services;

public interface INutritionRealtimePublisher
{
    Task PublishNutritionUpdatedAsync(Guid userId, DateOnly date, CancellationToken cancellationToken = default);
}

public sealed class NoOpNutritionRealtimePublisher : INutritionRealtimePublisher
{
    public Task PublishNutritionUpdatedAsync(Guid userId, DateOnly date, CancellationToken cancellationToken = default) =>
        Task.CompletedTask;
}
