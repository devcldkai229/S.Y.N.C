using Contract.Events;

namespace Nutrition.Application.Services;

public interface IOrderCompletedHandler
{
    Task HandleAsync(OrderCompletedEvent orderEvent, CancellationToken cancellationToken = default);
}
