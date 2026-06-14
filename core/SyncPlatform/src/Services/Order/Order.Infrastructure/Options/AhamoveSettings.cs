namespace Order.Infrastructure.Options;

public class AhamoveSettings
{
    public const string SectionName = "Ahamove";

    public bool Enabled { get; set; }

    public string ApiKey { get; set; } = string.Empty;

    /// <summary>Staging: https://partner-apistg.ahamove.com/v3</summary>
    public string BaseUrl { get; set; } = "https://partner-apistg.ahamove.com/v3";

    /// <summary>Partner account mobile (84xxxxxxxxx) used to obtain Bearer token.</summary>
    public string Mobile { get; set; } = string.Empty;

    public string ServiceId { get; set; } = "SGN-BIKE";

    /// <summary>CASH | BALANCE | CASH_BY_RECIPIENT — delivery fee on Ahamove side.</summary>
    public string PaymentMethod { get; set; } = "CASH";

    /// <summary>Optional inbound webhook auth (apikey header). Empty = accept in Development.</summary>
    public string? WebhookApiKey { get; set; }

    /// <summary>Skip real Ahamove API; use sandbox-* IDs with local driver simulation.</summary>
    public bool UseSandboxSimulation { get; set; } = true;
}
