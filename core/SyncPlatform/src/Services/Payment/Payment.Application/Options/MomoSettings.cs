namespace Payment.Application.Options;

public class MomoSettings
{
    public const string SectionName = "Momo";

    public bool Enabled { get; set; }

    public string PartnerCode { get; set; } = string.Empty;

    public string AccessKey { get; set; } = string.Empty;

    public string SecretKey { get; set; } = string.Empty;

    public string Endpoint { get; set; } = "https://test-payment.momo.vn/v2/gateway/api/create";

    public string IpnUrl { get; set; } = string.Empty;

    public string RedirectUrl { get; set; } = string.Empty;
}
