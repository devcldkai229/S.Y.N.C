using Amazon.SimpleEmailV2;
using Amazon.SimpleEmailV2.Model;
using Iam.Application.Abstractions;
using Iam.Application.Options;
using Iam.Application.Services;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Iam.Infrastructure.Services;

/// <summary>
/// Sends verification emails via AWS SES (Simple Email Service v2).
/// Requires a verified sender identity and IAM permissions for ses:SendEmail.
/// </summary>
public sealed class SesEmailSender : IEmailSender
{
    private readonly IAmazonSimpleEmailServiceV2 _ses;
    private readonly EmailSettings _settings;
    private readonly ILogger<SesEmailSender> _logger;

    public SesEmailSender(
        IAmazonSimpleEmailServiceV2 ses,
        IOptions<EmailSettings> options,
        ILogger<SesEmailSender> logger)
    {
        _ses = ses;
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
        var ses = _settings.Ses;
        if (string.IsNullOrWhiteSpace(ses.FromEmail))
            throw new InvalidOperationException("Email:Ses:FromEmail is not configured.");

        var fromAddress = string.IsNullOrWhiteSpace(ses.FromName)
            ? ses.FromEmail.Trim()
            : $"\"{ses.FromName.Trim()}\" <{ses.FromEmail.Trim()}>";

        var request = new SendEmailRequest
        {
            FromEmailAddress = fromAddress,
            Destination = new Destination
            {
                ToAddresses = [toEmail.Trim()],
            },
            Content = new EmailContent
            {
                Simple = new Message
                {
                    Subject = new Content
                    {
                        Charset = "UTF-8",
                        Data = content.Subject,
                    },
                    Body = new Body
                    {
                        Html = new Content
                        {
                            Charset = "UTF-8",
                            Data = content.HtmlBody,
                        },
                        Text = new Content
                        {
                            Charset = "UTF-8",
                            Data = content.TextBody,
                        },
                    },
                },
            },
        };

        if (!string.IsNullOrWhiteSpace(ses.ConfigurationSetName))
            request.ConfigurationSetName = ses.ConfigurationSetName.Trim();

        var response = await _ses.SendEmailAsync(request, cancellationToken);

        _logger.LogInformation(
            "SES email sent to {Email} (MessageId={MessageId})",
            toEmail,
            response.MessageId);
    }
}
