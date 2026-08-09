using Social.Application.Clients;
using Social.Application.DTOs;

namespace Social.Infrastructure.Clients;

/// <summary>Fallback when AWS Location place index is not configured.</summary>
public sealed class NullPlaceIndexClient : IPlaceIndexClient
{
    public Task<IReadOnlyList<AddressSuggestionDto>> SearchAsync(
        string query,
        double? biasLat,
        double? biasLng,
        CancellationToken cancellationToken = default) =>
        Task.FromResult<IReadOnlyList<AddressSuggestionDto>>([]);

    public Task<ReverseGeocodeResultDto> ReverseAsync(
        double lat,
        double lng,
        CancellationToken cancellationToken = default) =>
        Task.FromResult(new ReverseGeocodeResultDto
        {
            Label = $"{lat:F5}, {lng:F5}",
            Lat = lat,
            Lng = lng,
        });
}
