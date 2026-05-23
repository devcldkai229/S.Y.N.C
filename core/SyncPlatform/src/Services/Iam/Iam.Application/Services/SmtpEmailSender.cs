using Iam.Application.Abstractions;
using Iam.Application.Options;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MimeKit;

namespace Iam.Application.Services;

/// <summary>
/// Sends verification emails via SMTP (Gmail, Mailtrap, etc.).
/// Dev: set <c>Email:Smtp:Enabled=true</c> in appsettings.Development.json.
/// </summary>
public class SmtpEmailSender : IEmailSender
{
    private readonly EmailSettings _settings;
    private readonly ILogger<SmtpEmailSender> _logger;

    public SmtpEmailSender(IOptions<EmailSettings> options, ILogger<SmtpEmailSender> logger)
    {
        _settings = options.Value;
        _logger = logger;
    }

    public async Task SendVerificationEmailAsync(
        string toEmail,
        string verificationToken,
        CancellationToken cancellationToken = default)
    {
        var smtp = _settings.Smtp;
        if (string.IsNullOrWhiteSpace(smtp.Host))
            throw new InvalidOperationException("Email:Smtp:Host is not configured.");

        if (string.IsNullOrWhiteSpace(smtp.FromEmail))
            throw new InvalidOperationException("Email:Smtp:FromEmail is not configured.");

        var verifyUrl = BuildVerifyUrl(verificationToken);
        var htmlBody = VerificationEmailTemplate.BuildHtml(verifyUrl, toEmail);

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(smtp.FromName, smtp.FromEmail));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = "Xác nhận email — Sync Lifestyle";
        message.Body = new BodyBuilder { HtmlBody = htmlBody }.ToMessageBody();

        using var client = new SmtpClient();
        await client.ConnectAsync(
            smtp.Host,
            smtp.Port,
            smtp.UseSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None,
            cancellationToken);

        if (!string.IsNullOrWhiteSpace(smtp.UserName))
            await client.AuthenticateAsync(smtp.UserName, smtp.Password, cancellationToken);

        await client.SendAsync(message, cancellationToken);
        await client.DisconnectAsync(true, cancellationToken);

        _logger.LogInformation("Verification email sent to {Email}", toEmail);
    }

    internal string BuildVerifyUrl(string verificationToken)
    {
        var baseUrl = _settings.VerificationBaseUrl.TrimEnd('/');
        return $"{baseUrl}/api/v1/auth/verify-email?token={Uri.EscapeDataString(verificationToken)}";
    }
}
