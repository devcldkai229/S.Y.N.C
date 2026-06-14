using Order.Application.DTOs;

namespace Order.Application.Ports;

public interface ICartStore
{
    Task<CartDto?> GetAsync(Guid userId, CancellationToken cancellationToken = default);

    Task SaveAsync(Guid userId, CartDto cart, CancellationToken cancellationToken = default);

    Task DeleteAsync(Guid userId, CancellationToken cancellationToken = default);
}
