namespace Order.Infrastructure.Options;

public class LalamoveSettings
{
    public const string SectionName = "Lalamove";

    public string ApiKey { get; set; } = string.Empty;

    public string ApiSecret { get; set; } = string.Empty;

    public string BaseUrl { get; set; } = "https://rest.sandbox.lalamove.com";

    public bool Enabled { get; set; }
}
