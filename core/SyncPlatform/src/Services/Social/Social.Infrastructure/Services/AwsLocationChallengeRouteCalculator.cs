using Amazon;
using Amazon.LocationService;
using Amazon.LocationService.Model;
using Amazon.Runtime;
using Amazon.Runtime.CredentialManagement;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Social.Application.DTOs;
using Social.Application.Helpers;
using Social.Application.Services;
using Social.Infrastructure.Options;

namespace Social.Infrastructure.Services;

/// <summary>
/// Road-network routes via Amazon Location Service Route Calculator.
/// </summary>
public sealed class AwsLocationChallengeRouteCalculator : IChallengeRouteCalculator
{
    private const double CarFallbackSpeedKmh = 40;
    private const double MotorbikeFallbackSpeedKmh = 30;
    private const double WalkingFallbackSpeedKmh = 5;

    private readonly IAmazonLocationService _location;
    private readonly AwsLocationOptions _options;
    private readonly ILogger<AwsLocationChallengeRouteCalculator> _logger;

    public AwsLocationChallengeRouteCalculator(
        IAmazonLocationService location,
        IOptions<AwsLocationOptions> options,
        ILogger<AwsLocationChallengeRouteCalculator> logger)
    {
        _location = location;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<ChallengeRouteDto> CalculateRouteAsync(
        double userLat,
        double userLng,
        double destinationLat,
        double destinationLng,
        ChallengeRouteTravelMode? travelMode = null,
        CancellationToken cancellationToken = default)
    {
        if (!_options.IsConfigured)
        {
            _logger.LogDebug("AwsLocation is not configured; using Haversine fallback.");
            return await new HaversineChallengeRouteCalculator().CalculateRouteAsync(
                userLat, userLng, destinationLat, destinationLng, travelMode, cancellationToken);
        }

        _logger.LogInformation(
            "AWS Location route: {Calculator} ({Provider}), mode={Mode}",
            _options.RouteCalculatorName,
            _options.DataProvider,
            travelMode?.ToString() ?? "all");

        var modes = ResolveModes(travelMode);
        var result = new ChallengeRouteDto();

        foreach (var mode in modes)
        {
            var route = mode switch
            {
                ChallengeRouteTravelMode.Car => await CalculateModeAsync(
                    userLat, userLng, destinationLat, destinationLng, TravelMode.Car, cancellationToken),
                ChallengeRouteTravelMode.Walking => await CalculateModeAsync(
                    userLat, userLng, destinationLat, destinationLng, TravelMode.Walking, cancellationToken),
                _ => await CalculateMotorbikeAsync(
                    userLat, userLng, destinationLat, destinationLng, cancellationToken),
            };

            route = NormalizeRoute(route, userLat, userLng, destinationLat, destinationLng);

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

        return result;
    }

    private static IReadOnlyList<ChallengeRouteTravelMode> ResolveModes(ChallengeRouteTravelMode? travelMode) =>
        travelMode.HasValue
            ? [travelMode.Value]
            :
            [
                ChallengeRouteTravelMode.Car,
                ChallengeRouteTravelMode.Motorbike,
                ChallengeRouteTravelMode.Walking,
            ];

    private async Task<TravelModeRouteDto> CalculateMotorbikeAsync(
        double userLat,
        double userLng,
        double destinationLat,
        double destinationLng,
        CancellationToken cancellationToken)
    {
        if (string.Equals(_options.DataProvider, "Grab", StringComparison.OrdinalIgnoreCase))
        {
            try
            {
                return await CalculateModeAsync(
                    userLat, userLng, destinationLat, destinationLng, TravelMode.Motorcycle, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Grab Motorcycle route failed; trying Bicycle.");
            }
        }

        try
        {
            return await CalculateModeAsync(
                userLat, userLng, destinationLat, destinationLng, TravelMode.Bicycle, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Bicycle route failed for motorbike; trying Car.");
            return await CalculateModeAsync(
                userLat, userLng, destinationLat, destinationLng, TravelMode.Car, cancellationToken);
        }
    }

    private async Task<TravelModeRouteDto> CalculateModeAsync(
        double userLat,
        double userLng,
        double destinationLat,
        double destinationLng,
        TravelMode travelMode,
        CancellationToken cancellationToken)
    {
        var response = await _location.CalculateRouteAsync(new CalculateRouteRequest
        {
            CalculatorName = _options.RouteCalculatorName,
            DeparturePosition = [userLng, userLat],
            DestinationPosition = [destinationLng, destinationLat],
            TravelMode = travelMode,
            DepartNow = true,
            IncludeLegGeometry = true,
            DistanceUnit = DistanceUnit.Kilometers,
        }, cancellationToken);

        var summary = response.Summary
            ?? throw new InvalidOperationException($"AWS Location returned no summary for {travelMode}.");

        var distanceKm = summary.Distance;
        var durationSeconds = summary.DurationSeconds;
        var minutes = durationSeconds > 0
            ? (int)Math.Ceiling(durationSeconds / 60.0)
            : GeoDistanceHelper.EstimateMinutes(distanceKm, FallbackSpeedKmh(travelMode));

        var arrivalAt = durationSeconds > 0
            ? DateTimeOffset.UtcNow.AddSeconds(durationSeconds)
            : DateTimeOffset.UtcNow.AddMinutes(minutes);

        var polyline = ExtractPolyline(response);
        if (polyline.Count < 2)
        {
            throw new InvalidOperationException(
                $"AWS Location returned no route geometry for {travelMode}.");
        }

        return new TravelModeRouteDto
        {
            DistanceKm = Math.Round(distanceKm, 2),
            EstimatedMinutes = minutes,
            EstimatedArrivalAt = arrivalAt,
            Polyline = polyline,
        };
    }

    internal static TravelModeRouteDto NormalizeRoute(
        TravelModeRouteDto route,
        double startLat,
        double startLng,
        double endLat,
        double endLng)
    {
        var points = route.Polyline.ToList();
        if (points.Count == 0)
        {
            return route;
        }

        points = TrimOffRoadConnector(points, startLat, startLng, fromTail: false);
        points = TrimOffRoadConnector(points, endLat, endLng, fromTail: true);

        var last = points[^1];
        var offRoadGapMeters = GeoDistanceHelper.HaversineKm(
            last.Latitude, last.Longitude, endLat, endLng) * 1000;

        return new TravelModeRouteDto
        {
            DistanceKm = route.DistanceKm,
            EstimatedMinutes = route.EstimatedMinutes,
            EstimatedArrivalAt = route.EstimatedArrivalAt,
            Polyline = points,
            OffRoadGapMeters = Math.Round(offRoadGapMeters, 1),
        };
    }

    /// <summary>
    /// Removes straight "bird's eye" connectors that AWS/Grab adds when the
    /// origin or destination is not on the driveable road network.
    /// </summary>
    internal static List<GeoLocationDto> TrimOffRoadConnector(
        List<GeoLocationDto> points,
        double targetLat,
        double targetLng,
        bool fromTail,
        double minConnectorKm = 0.025)
    {
        while (points.Count >= 2)
        {
            var anchorIndex = fromTail ? points.Count - 2 : 1;
            var tipIndex = fromTail ? points.Count - 1 : 0;

            var anchor = points[anchorIndex];
            var tip = points[tipIndex];

            var segmentKm = GeoDistanceHelper.HaversineKm(
                anchor.Latitude, anchor.Longitude, tip.Latitude, tip.Longitude);
            var tipToTargetKm = GeoDistanceHelper.HaversineKm(
                tip.Latitude, tip.Longitude, targetLat, targetLng);
            var anchorToTargetKm = GeoDistanceHelper.HaversineKm(
                anchor.Latitude, anchor.Longitude, targetLat, targetLng);

            var isOffRoadConnector = segmentKm >= minConnectorKm
                && tipToTargetKm < anchorToTargetKm
                && segmentKm >= anchorToTargetKm * 0.45;

            if (!isOffRoadConnector)
            {
                break;
            }

            points.RemoveAt(tipIndex);
        }

        return points;
    }

    private static double FallbackSpeedKmh(TravelMode mode)
    {
        if (mode == TravelMode.Walking) return WalkingFallbackSpeedKmh;
        if (mode == TravelMode.Bicycle) return MotorbikeFallbackSpeedKmh;
        if (mode == TravelMode.Motorcycle) return MotorbikeFallbackSpeedKmh;
        return CarFallbackSpeedKmh;
    }

    private static IReadOnlyList<GeoLocationDto> ExtractPolyline(CalculateRouteResponse response)
    {
        var line = response.Legs?
            .SelectMany(leg => leg.Geometry?.LineString ?? [])
            .ToList();

        if (line is null || line.Count == 0)
            return [];

        return line
            .Where(point => point.Count >= 2)
            .Select(point => new GeoLocationDto
            {
                Longitude = point[0],
                Latitude = point[1],
            })
            .ToList();
    }

    public static IAmazonLocationService CreateClient(AwsLocationOptions options)
    {
        var region = RegionEndpoint.GetBySystemName(options.Region);
        var credentials = ResolveCredentials(options);
        return new AmazonLocationServiceClient(credentials, region);
    }

    private static AWSCredentials ResolveCredentials(AwsLocationOptions options)
    {
        if (!string.IsNullOrWhiteSpace(options.AccessKeyId) &&
            !string.IsNullOrWhiteSpace(options.SecretAccessKey))
        {
            return new BasicAWSCredentials(options.AccessKeyId, options.SecretAccessKey);
        }

        if (!string.IsNullOrWhiteSpace(options.Profile))
        {
            var chain = new CredentialProfileStoreChain();
            if (chain.TryGetAWSCredentials(options.Profile, out var profileCredentials))
                return profileCredentials;

            throw new InvalidOperationException($"AWS profile '{options.Profile}' was not found.");
        }

        return FallbackCredentialsFactory.GetCredentials();
    }
}
