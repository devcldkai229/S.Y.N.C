namespace Order.Infrastructure.Options;

public class OrderSettings
{
    public const string SectionName = "Order";

    public decimal DefaultDeliveryFee { get; set; } = 25000m;

    public int LocationPersistIntervalSeconds { get; set; } = 30;

    public int LocationPollIntervalSeconds { get; set; } = 12;

    /// <summary>Public base URL (ngrok/Gateway) for inbound webhooks, e.g. https://xxx.ngrok-free.dev</summary>
    public string? PublicBaseUrl { get; set; }

    /// <summary>Auto-book delivery and simulate driver progression in Development.</summary>
    public bool SimulateDeliveryProgress { get; set; } = true;

    public int SandboxSimulationIntervalSeconds { get; set; } = 18;

    public string? AhamoveWebhookUrl =>
        string.IsNullOrWhiteSpace(PublicBaseUrl) ? null : $"{PublicBaseUrl.TrimEnd('/')}/webhooks/ahamove";
}
