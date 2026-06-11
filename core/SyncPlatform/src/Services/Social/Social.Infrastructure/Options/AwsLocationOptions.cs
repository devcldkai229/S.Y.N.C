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

    public bool IsConfigured => !string.IsNullOrWhiteSpace(RouteCalculatorName);
}
