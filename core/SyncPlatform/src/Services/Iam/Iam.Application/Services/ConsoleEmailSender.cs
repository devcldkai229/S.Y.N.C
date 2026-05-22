using Iam.Application.Abstractions;
using Microsoft.Extensions.Logging;

namespace Iam.Application.Services;

/// <summary>
/// Stub email sender for development — writes the verification link to the logger.
/// Replace with a real SMTP / SendGrid / SES implementation in production.
/// </summary>
public class ConsoleEmailSender : IEmailSender
{
    private readonly ILogger<ConsoleEmailSender> _logger;

    public ConsoleEmailSender(ILogger<ConsoleEmailSender> logger)
    {
        _logger = logger;
    }

    public Task SendVerificationEmailAsync(string toEmail, string verificationToken, CancellationToken cancellationToken = default)
    {
        var link = $"/api/auth/verify-email?token={verificationToken}";
        _logger.LogInformation(
            "[FAKE EMAIL] To: {Email} | Verify your account: {Link}",
            toEmail, link);
        return Task.CompletedTask;
    }
}
