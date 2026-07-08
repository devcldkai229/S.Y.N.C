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

    /// <summary>AWS SES (production). Takes priority over SMTP when enabled.</summary>
    public SesOptions Ses { get; set; } = new();

    public SmtpOptions Smtp { get; set; } = new();
}

public class SesOptions
{
    /// <summary>When true, sends via AWS SES using credentials from the AWS section.</summary>
    public bool Enabled { get; set; }

    /// <summary>Verified sender in SES (domain or email identity).</summary>
    public string FromEmail { get; set; } = string.Empty;

    public string FromName { get; set; } = "Sync Lifestyle";

    /// <summary>Optional SES configuration set for bounce/complaint tracking.</summary>
    public string? ConfigurationSetName { get; set; }
}

public class SmtpOptions
{
    /// <summary>When false, falls back to <see cref="ConsoleEmailSender"/> (log only).</summary>
    public bool Enabled { get; set; }

    public string Host { get; set; } = string.Empty;
    public int Port { get; set; } = 587;
    public string UserName { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string FromEmail { get; set; } = string.Empty;
    public string FromName { get; set; } = "Sync Lifestyle";
    public bool UseSsl { get; set; } = true;
}
