using Order.Application.DTOs;

namespace Order.Application.Ports;

public interface IPlaceSearchCache
{
    Task<IReadOnlyList<AddressSuggestionDto>?> GetSearchAsync(string cacheKey, CancellationToken cancellationToken = default);

    Task SetSearchAsync(string cacheKey, IReadOnlyList<AddressSuggestionDto> results, TimeSpan ttl, CancellationToken cancellationToken = default);
}
