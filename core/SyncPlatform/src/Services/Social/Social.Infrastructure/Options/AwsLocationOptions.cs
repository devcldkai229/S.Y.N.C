namespace Social.Infrastructure.Options;

public sealed class AwsLocationOptions
{
    public const string SectionName = "AwsLocation";

    public string Region { get; set; } = "ap-southeast-1";

    public string RouteCalculatorName { get; set; } = string.Empty;

    /// <summary>Optional explicit keys. Leave empty when using <see cref="Profile"/> or the default AWS credential chain.</summary>
    public string? AccessKeyId { get; set; }

    public string? SecretAccessKey { get; set; }

    /// <summary>
    /// Named profile from ~/.aws/credentials or SSO.
    /// When empty, the SDK uses AWS_PROFILE env var or the default profile.
    /// </summary>
    public string? Profile { get; set; }

    /// <summary>Grab supports Motorcycle/Scooter in Southeast Asia; Esri uses Car/Truck/Walking/Bicycle.</summary>
    public string DataProvider { get; set; } = "Esri";

    /// <summary>AWS Location Place Index resource name for geocoding.</summary>
    public string PlaceIndexName { get; set; } = string.Empty;

    /// <summary>Named map resource for MapLibre style descriptor (e.g. sync-map).</summary>
    public string MapName { get; set; } = "sync-map";

    /// <summary>v2 Esri style when MapName is empty: Standard, Hybrid, Satellite, Monochrome.</summary>
    public string MapStyle { get; set; } = "Hybrid";

    /// <summary>
    /// Per-request HTTP timeout for Amazon Location SDK calls (seconds).
    /// Keep modest so a slow Grab/Esri call fails over instead of hanging the API.
    /// </summary>
    public int RequestTimeoutSeconds { get; set; } = 12;

    /// <summary>
    /// Soft timeout per travel-mode attempt when cascading Motorbike fallbacks
    /// (Motorcycle → Bicycle → Car). Shorter than <see cref="RequestTimeoutSeconds"/>
    /// so a hung Grab Motorcycle call does not block the whole request.
    /// </summary>
    public int RouteAttemptTimeoutSeconds { get; set; } = 8;

    public bool IsConfigured => !string.IsNullOrWhiteSpace(RouteCalculatorName);

    public bool IsPlacesConfigured => !string.IsNullOrWhiteSpace(PlaceIndexName);
}
