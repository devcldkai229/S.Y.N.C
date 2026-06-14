using Order.Application.DTOs;

namespace Order.Application.Ports;

public interface IPlaceIndexClient
{
    Task<IReadOnlyList<AddressSuggestionDto>> SearchAsync(
        string query,
        double? biasLat,
        double? biasLng,
        CancellationToken cancellationToken = default);

    Task<ReverseGeocodeResultDto> ReverseAsync(
        double lat,
        double lng,
        CancellationToken cancellationToken = default);
}
