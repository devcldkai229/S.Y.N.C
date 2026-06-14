namespace Order.Infrastructure.Options;

public sealed class AwsLocationOptions
{
    public const string SectionName = "AwsLocation";

    public string Region { get; set; } = "ap-southeast-1";

    /// <summary>AWS Location Place Index resource name for geocoding.</summary>
    public string PlaceIndexName { get; set; } = string.Empty;

    public string? AccessKeyId { get; set; }

    public string? SecretAccessKey { get; set; }

    public string? Profile { get; set; }

    public bool IsPlacesConfigured => !string.IsNullOrWhiteSpace(PlaceIndexName);
}
