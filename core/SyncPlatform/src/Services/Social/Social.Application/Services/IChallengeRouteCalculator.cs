using Social.Application.DTOs;

namespace Social.Application.Services;

public interface IChallengeRouteCalculator
{
    Task<ChallengeRouteDto> CalculateRouteAsync(
        double userLat,
        double userLng,
        double destinationLat,
        double destinationLng,
        ChallengeRouteTravelMode? travelMode = null,
        CancellationToken cancellationToken = default);
}
