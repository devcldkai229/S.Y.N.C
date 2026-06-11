using Contract.Events;

namespace Order.Application.Clients;

public interface INutritionEventClient
{
    Task PublishOrderCompletedAsync(OrderCompletedEvent orderEvent, CancellationToken cancellationToken = default);
}
