namespace Iam.Application.Options;

/// <summary>Email delivery settings for verification and password-reset messages.</summary>
public class EmailSettings
{
    public const string SectionName = "Email";

    /// <summary>
    /// Public base URL of IAM API (no trailing slash).
    /// Used to build the verify link: {VerificationBaseUrl}/api/v1/auth/verify-email?token=...
    /// Dev: http://localhost:5288 — Prod: https://api.sync.vn or Gateway URL.
    /// </summary>
    public string VerificationBaseUrl { get; set; } = "http://localhost:5288";

    /// <summary>Brevo SMTP relay — the only email provider.</summary>
    public BrevoOptions Brevo { get; set; } = new();
}

public class BrevoOptions
{
    public bool Enabled { get; set; }

    public string Host { get; set; } = "smtp-relay.brevo.com";

    public int Port { get; set; } = 587;

    /// <summary>Brevo SMTP login (e.g. 96626e001@smtp-brevo.com).</summary>
    public string UserName { get; set; } = string.Empty;

    /// <summary>Brevo SMTP key (xsmtpsib-...).</summary>
    public string Password { get; set; } = string.Empty;

    /// <summary>Verified sender address in Brevo.</summary>
    public string FromEmail { get; set; } = string.Empty;

    public string FromName { get; set; } = "Sync Lifestyle";

    /// <summary>Use STARTTLS on port 587 when true.</summary>
    public bool UseSsl { get; set; } = true;
}
