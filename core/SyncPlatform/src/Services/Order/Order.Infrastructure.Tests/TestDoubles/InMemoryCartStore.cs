using Order.Application.DTOs;
using Order.Application.Ports;

namespace Order.Infrastructure.Tests.TestDoubles;

internal sealed class InMemoryCartStore : ICartStore
{
    private readonly Dictionary<Guid, CartDto> _carts = new();

    public Task<CartDto?> GetAsync(Guid userId, CancellationToken cancellationToken = default) =>
        Task.FromResult(_carts.TryGetValue(userId, out var cart) ? cart : null);

    public Task SaveAsync(Guid userId, CartDto cart, CancellationToken cancellationToken = default)
    {
        _carts[userId] = cart;
        return Task.CompletedTask;
    }

    public Task DeleteAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        _carts.Remove(userId);
        return Task.CompletedTask;
    }

    public bool HasCart(Guid userId) => _carts.ContainsKey(userId);
}
