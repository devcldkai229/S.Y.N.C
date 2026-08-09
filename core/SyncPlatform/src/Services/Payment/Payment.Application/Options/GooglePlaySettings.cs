namespace Payment.Application.Options;

/// <summary>
/// Google Play Billing (Android Publisher API) + RTDN configuration.
/// </summary>
public class GooglePlaySettings
{
    public const string SectionName = "GooglePlay";

    /// <summary>Android applicationId, e.g. com.sync.sync_app.</summary>
    public string PackageName { get; set; } = "com.sync.sync_app";

    /// <summary>
    /// Absolute path to a service-account JSON key with Android Publisher access,
    /// or the raw JSON content itself.
    /// </summary>
    public string ServiceAccountJson { get; set; } = string.Empty;

    /// <summary>
    /// Optional shared secret for RTDN push endpoint
    /// (query <c>?token=</c> or header <c>X-Google-Play-Rtdn-Secret</c>).
    /// </summary>
    public string RtdnSharedSecret { get; set; } = string.Empty;

    /// <summary>
    /// When true (local/dev only), skip Google API and trust the client purchaseToken
    /// to activate Premium for MonthlyDurationDays. Never enable in production.
    /// </summary>
    public bool DevSimulateVerify { get; set; }

    /// <summary>Fallback duration when Google does not return expiry (days).</summary>
    public int MonthlyDurationDays { get; set; } = 30;
}
