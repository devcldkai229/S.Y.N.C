namespace Payment.Application.Options;

/// <summary>
/// PayOS merchant credentials and URL configuration.
/// Issued from the PayOS merchant dashboard — never log or expose these values.
/// </summary>
public class PayosSettings
{
    public const string SectionName = "PayOS";

    public string ClientId { get; set; } = string.Empty;
    public string ApiKey { get; set; } = string.Empty;
    public string ChecksumKey { get; set; } = string.Empty;

    /// <summary>URL the user is redirected to after a successful payment (Flutter deep link or web page).</summary>
    public string ReturnUrl { get; set; } = string.Empty;

    /// <summary>URL the user is redirected to when they cancel the payment.</summary>
    public string CancelUrl { get; set; } = string.Empty;

    /// <summary>Default duration in days for the Monthly billing cycle.</summary>
    public int MonthlyDurationDays { get; set; } = 30;

    /// <summary>Default duration in days for the Yearly billing cycle.</summary>
    public int YearlyDurationDays { get; set; } = 365;
}
