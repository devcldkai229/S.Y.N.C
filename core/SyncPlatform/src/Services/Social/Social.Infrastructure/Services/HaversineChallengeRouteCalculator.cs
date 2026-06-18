using Social.Application.DTOs;
using Social.Application.Helpers;
using Social.Application.Services;

namespace Social.Infrastructure.Services;

/// <summary>
/// Straight-line fallback when AWS Location is unavailable or not configured.
/// </summary>
public sealed class HaversineChallengeRouteCalculator : IChallengeRouteCalculator
{
    private const double CarSpeedKmh = 40;
    private const double MotorbikeSpeedKmh = 30;
    private const double WalkingSpeedKmh = 5;
    private const int PolylinePointCount = 12;

    public Task<ChallengeRouteDto> CalculateRouteAsync(
        double userLat,
        double userLng,
        double destinationLat,
        double destinationLng,
        ChallengeRouteTravelMode? travelMode = null,
        CancellationToken cancellationToken = default)
    {
        var distanceKm = GeoDistanceHelper.HaversineKm(userLat, userLng, destinationLat, destinationLng);
        var polyline = BuildPolyline(userLat, userLng, destinationLat, destinationLng);

        var result = new ChallengeRouteDto();
        var modes = travelMode.HasValue
            ? new[] { travelMode.Value }
            : new[]
            {
                ChallengeRouteTravelMode.Car,
                ChallengeRouteTravelMode.Motorbike,
                ChallengeRouteTravelMode.Walking,
            };

        foreach (var mode in modes)
        {
            var route = mode switch
            {
                ChallengeRouteTravelMode.Car => BuildRoute(distanceKm, CarSpeedKmh, polyline),
                ChallengeRouteTravelMode.Walking => BuildRoute(distanceKm, WalkingSpeedKmh, polyline),
                _ => BuildRoute(distanceKm, MotorbikeSpeedKmh, polyline),
            };

            switch (mode)
            {
                case ChallengeRouteTravelMode.Car:
                    result.Car = route;
                    break;
                case ChallengeRouteTravelMode.Motorbike:
                    result.Motorbike = route;
                    break;
                case ChallengeRouteTravelMode.Walking:
                    result.Walking = route;
                    break;
            }
        }

        return Task.FromResult(result);
    }

    internal static TravelModeRouteDto BuildRoute(
        double distanceKm,
        double speedKmh,
        IReadOnlyList<GeoLocationDto> polyline)
    {
        var minutes = GeoDistanceHelper.EstimateMinutes(distanceKm, speedKmh);
        return new TravelModeRouteDto
        {
            DistanceKm = Math.Round(distanceKm, 2),
            EstimatedMinutes = minutes,
            EstimatedArrivalAt = DateTimeOffset.UtcNow.AddMinutes(minutes),
            Polyline = polyline,
        };
    }

    internal static IReadOnlyList<GeoLocationDto> BuildPolyline(
        double startLat,
        double startLng,
        double endLat,
        double endLng)
    {
        var points = new List<GeoLocationDto>(PolylinePointCount);

        for (var i = 0; i < PolylinePointCount; i++)
        {
            var t = i / (double)(PolylinePointCount - 1);
            points.Add(new GeoLocationDto
            {
                Latitude = startLat + (endLat - startLat) * t,
                Longitude = startLng + (endLng - startLng) * t,
            });
        }

        return points;
    }
}
