using Iam.Application.Abstractions;
using Iam.Application.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Iam.Application.Services;

/// <summary>
/// Fallback when <c>Email:Smtp:Enabled</c> is false — logs the full verify URL only.
/// </summary>
public class ConsoleEmailSender : IEmailSender
{
    private readonly EmailSettings _settings;
    private readonly ILogger<ConsoleEmailSender> _logger;

    public ConsoleEmailSender(IOptions<EmailSettings> options, ILogger<ConsoleEmailSender> logger)
    {
        _settings = options.Value;
        _logger = logger;
    }

    public Task SendVerificationEmailAsync(string toEmail, string verificationToken, CancellationToken cancellationToken = default)
    {
        var baseUrl = _settings.VerificationBaseUrl.TrimEnd('/');
        var link = $"{baseUrl}/api/v1/auth/verify-email?token={Uri.EscapeDataString(verificationToken)}";
        _logger.LogWarning(
            "[EMAIL DISABLED] SMTP off — verification link for {Email}: {Link}",
            toEmail, link);
        return Task.CompletedTask;
    }
}
