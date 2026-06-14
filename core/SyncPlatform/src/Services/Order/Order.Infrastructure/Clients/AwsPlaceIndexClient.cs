using Amazon;
using Amazon.LocationService;
using Amazon.LocationService.Model;
using Amazon.Runtime;
using Amazon.Runtime.CredentialManagement;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Order.Application.DTOs;
using Order.Application.Ports;
using Order.Infrastructure.Options;

namespace Order.Infrastructure.Clients;

public sealed class AwsPlaceIndexClient : IPlaceIndexClient
{
    private readonly IAmazonLocationService _location;
    private readonly AwsLocationOptions _options;
    private readonly ILogger<AwsPlaceIndexClient> _logger;

    public AwsPlaceIndexClient(
        IAmazonLocationService location,
        IOptions<AwsLocationOptions> options,
        ILogger<AwsPlaceIndexClient> logger)
    {
        _location = location;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<IReadOnlyList<AddressSuggestionDto>> SearchAsync(
        string query,
        double? biasLat,
        double? biasLng,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(query) || !_options.IsPlacesConfigured)
            return [];

        try
        {
            var request = new SearchPlaceIndexForTextRequest
            {
                IndexName = _options.PlaceIndexName,
                Text = query.Trim(),
                MaxResults = 8,
                FilterCountries = ["VNM"],
            };

            if (biasLat.HasValue && biasLng.HasValue)
            {
                request.BiasPosition = [biasLng.Value, biasLat.Value];
            }

            var response = await _location.SearchPlaceIndexForTextAsync(request, cancellationToken);
            return response.Results
                .Select(r =>
                {
                    var point = r.Place?.Geometry?.Point;
                    return new AddressSuggestionDto
                    {
                        Label = r.Place?.Label ?? string.Empty,
                        PlaceId = r.PlaceId,
                        Lng = point is { Count: >= 2 } ? point[0] : 0,
                        Lat = point is { Count: >= 2 } ? point[1] : 0,
                    };
                })
                .Where(x => !string.IsNullOrWhiteSpace(x.Label))
                .ToList();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "AWS place search failed for query {Query}", query);
            return [];
        }
    }

    public async Task<ReverseGeocodeResultDto> ReverseAsync(
        double lat,
        double lng,
        CancellationToken cancellationToken = default)
    {
        if (!_options.IsPlacesConfigured)
        {
            return FallbackReverse(lat, lng);
        }

        try
        {
            var response = await _location.SearchPlaceIndexForPositionAsync(
                new SearchPlaceIndexForPositionRequest
                {
                    IndexName = _options.PlaceIndexName,
                    Position = [lng, lat],
                    MaxResults = 1,
                },
                cancellationToken);

            var place = response.Results.FirstOrDefault();
            if (place?.Place == null)
                return FallbackReverse(lat, lng);

            var p = place.Place;
            var addressLine = p.AddressNumber is not null && p.Street is not null
                ? $"{p.AddressNumber} {p.Street}"
                : p.Street;
            var label = BuildStableLabel(addressLine, p.Neighborhood, p.SubRegion, p.Region)
                ?? p.Label
                ?? addressLine
                ?? $"{lat:F5}, {lng:F5}";
            return new ReverseGeocodeResultDto
            {
                Label = label,
                AddressLine = addressLine,
                Ward = p.Neighborhood,
                District = p.SubRegion,
                City = p.Region,
                Lat = lat,
                Lng = lng,
            };
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "AWS reverse geocode failed for {Lat},{Lng}", lat, lng);
            return FallbackReverse(lat, lng);
        }
    }

    private static string? BuildStableLabel(
        string? addressLine,
        string? ward,
        string? district,
        string? city)
    {
        var parts = new List<string>();
        if (!string.IsNullOrWhiteSpace(addressLine))
            parts.Add(addressLine.Trim());

        foreach (var part in new[] { ward, district, city })
        {
            if (string.IsNullOrWhiteSpace(part)) continue;
            var trimmed = part.Trim();
            if (!parts.Contains(trimmed, StringComparer.OrdinalIgnoreCase))
                parts.Add(trimmed);
        }

        return parts.Count == 0 ? null : string.Join(", ", parts);
    }

    private static ReverseGeocodeResultDto FallbackReverse(double lat, double lng) =>
        new()
        {
            Label = $"{lat:F5}, {lng:F5}",
            Lat = lat,
            Lng = lng,
        };

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
        }

        return FallbackCredentialsFactory.GetCredentials();
    }
}
