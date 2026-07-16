using Iam.Application.Abstractions;
using Iam.Application.Exceptions;
using Iam.Application.Options;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MimeKit;

namespace Iam.Application.Services;

/// <summary>
/// Sends verification / password-reset emails via Brevo SMTP relay.
/// </summary>
public sealed class BrevoSmtpEmailSender : IEmailSender
{
    private readonly EmailSettings _settings;
    private readonly ILogger<BrevoSmtpEmailSender> _logger;

    public BrevoSmtpEmailSender(
        IOptions<EmailSettings> options,
        ILogger<BrevoSmtpEmailSender> logger)
    {
        _settings = options.Value;
        _logger = logger;
    }

    public Task SendVerificationEmailAsync(
        string toEmail,
        string verificationToken,
        CancellationToken cancellationToken = default)
    {
        var content = EmailMessageFactory.CreateVerificationEmail(_settings, toEmail, verificationToken);
        return SendAsync(toEmail, content, cancellationToken);
    }

    public Task SendPasswordResetEmailAsync(
        string toEmail,
        string resetCode,
        CancellationToken cancellationToken = default)
    {
        var content = EmailMessageFactory.CreatePasswordResetEmail(toEmail, resetCode);
        return SendAsync(toEmail, content, cancellationToken);
    }

    private async Task SendAsync(
        string toEmail,
        EmailMessageContent content,
        CancellationToken cancellationToken)
    {
        var brevo = _settings.Brevo;
        if (string.IsNullOrWhiteSpace(brevo.Host))
            throw new InvalidOperationException("Email:Brevo:Host is not configured.");
        if (string.IsNullOrWhiteSpace(brevo.FromEmail))
            throw new InvalidOperationException("Email:Brevo:FromEmail is not configured.");
        if (string.IsNullOrWhiteSpace(brevo.UserName) || string.IsNullOrWhiteSpace(brevo.Password))
            throw new InvalidOperationException("Email:Brevo:UserName/Password is not configured.");

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(brevo.FromName, brevo.FromEmail.Trim()));
        message.To.Add(MailboxAddress.Parse(toEmail.Trim()));
        message.Subject = content.Subject;
        message.Body = new BodyBuilder
        {
            HtmlBody = content.HtmlBody,
            TextBody = content.TextBody,
        }.ToMessageBody();

        try
        {
            using var client = new SmtpClient();
            await client.ConnectAsync(
                brevo.Host,
                brevo.Port,
                brevo.UseSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None,
                cancellationToken);

            await client.AuthenticateAsync(brevo.UserName, brevo.Password, cancellationToken);
            await client.SendAsync(message, cancellationToken);
            await client.DisconnectAsync(true, cancellationToken);

            _logger.LogInformation("Brevo SMTP email sent to {Email}", toEmail);
        }
        catch (Exception ex) when (ex is not InvalidOperationException and not BadRequestException)
        {
            _logger.LogError(ex, "Brevo SMTP send failed for {Email}", toEmail);
            throw new BadRequestException(
                $"Không gửi được email xác minh qua Brevo: {ex.Message}");
        }
    }
}
