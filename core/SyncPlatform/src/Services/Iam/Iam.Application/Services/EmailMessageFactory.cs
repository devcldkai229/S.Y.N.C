using Iam.Application.Options;

namespace Iam.Application.Services;

public sealed record EmailMessageContent(string Subject, string HtmlBody, string TextBody);

public static class EmailMessageFactory
{
    public static string BuildVerifyUrl(EmailSettings settings, string verificationToken)
    {
        var baseUrl = settings.VerificationBaseUrl.TrimEnd('/');
        return $"{baseUrl}/api/v1/auth/verify-email?token={Uri.EscapeDataString(verificationToken)}";
    }

    public static EmailMessageContent CreateVerificationEmail(
        EmailSettings settings,
        string toEmail,
        string verificationToken)
    {
        var verifyUrl = BuildVerifyUrl(settings, verificationToken);
        var html = VerificationEmailTemplate.BuildHtml(verifyUrl, toEmail, verificationToken);
        var text = $"""
            Xin chào,

            Bạn vừa đăng ký tài khoản Sync Lifestyle với email {toEmail}.

            Mã xác minh: {verificationToken}

            Hoặc mở link sau để xác nhận:
            {verifyUrl}

            Nếu bạn không đăng ký, hãy bỏ qua email này.
            """;

        return new EmailMessageContent("Xác nhận email — Sync Lifestyle", html, text);
    }

    public static EmailMessageContent CreatePasswordResetEmail(string toEmail, string resetCode)
    {
        var html = VerificationEmailTemplate.BuildPasswordResetHtml(toEmail, resetCode);
        var text = $"""
            Xin chào,

            Mã đặt lại mật khẩu Sync Lifestyle cho {toEmail}: {resetCode}

            Mã có hiệu lực trong 15 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.
            """;

        return new EmailMessageContent("Đặt lại mật khẩu — Sync Lifestyle", html, text);
    }
}
