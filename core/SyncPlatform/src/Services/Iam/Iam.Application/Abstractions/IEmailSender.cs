namespace Iam.Application.Abstractions;

public interface IEmailSender
{
    Task SendVerificationEmailAsync(string toEmail, string verificationToken, CancellationToken cancellationToken = default);
}
