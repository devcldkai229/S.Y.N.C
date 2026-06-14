using Order.Application.DTOs;

namespace Order.Application.Ports;

public interface IDeliveryAddressStore
{
    Task<DeliveryAddressDto?> GetAsync(Guid userId, CancellationToken cancellationToken = default);

    Task SaveAsync(Guid userId, DeliveryAddressDto address, CancellationToken cancellationToken = default);

    Task DeleteAsync(Guid userId, CancellationToken cancellationToken = default);
}
