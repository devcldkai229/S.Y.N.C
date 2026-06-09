namespace Iam.Application.Services;

public static class VerificationEmailTemplate
{
    public static string BuildHtml(string verifyUrl, string recipientEmail, string verificationCode)
    {
        var encodedUrl = System.Net.WebUtility.HtmlEncode(verifyUrl);
        var encodedEmail = System.Net.WebUtility.HtmlEncode(recipientEmail);
        var encodedCode = System.Net.WebUtility.HtmlEncode(verificationCode);

        return $"""
            <!DOCTYPE html>
            <html lang="vi">
            <head>
              <meta charset="utf-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1" />
              <title>Xác nhận email</title>
            </head>
            <body style="margin:0;padding:0;background:#f4f6f8;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f6f8;padding:32px 16px;">
                <tr>
                  <td align="center">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:520px;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
                      <tr>
                        <td style="background:linear-gradient(135deg,#2563eb,#7c3aed);padding:28px 32px;">
                          <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:600;">Sync Lifestyle</h1>
                          <p style="margin:8px 0 0;color:#e0e7ff;font-size:14px;">Xác nhận địa chỉ email của bạn</p>
                        </td>
                      </tr>
                      <tr>
                        <td style="padding:32px;">
                          <p style="margin:0 0 16px;color:#334155;font-size:15px;line-height:1.6;">
                            Xin chào,<br />
                            Bạn vừa đăng ký tài khoản với email <strong>{encodedEmail}</strong>.
                            Nhập mã xác minh bên dưới vào ứng dụng để kích hoạt tài khoản.
                          </p>
                          <div style="margin:16px 0 20px;padding:16px;border:1px dashed #94a3b8;border-radius:10px;background:#f8fafc;text-align:center;">
                            <div style="font-size:12px;color:#64748b;margin-bottom:6px;">MÃ XÁC MINH</div>
                            <div style="font-size:30px;letter-spacing:8px;font-weight:700;color:#0f172a;">{encodedCode}</div>
                          </div>
                          <table role="presentation" cellspacing="0" cellpadding="0" style="margin:24px 0;">
                            <tr>
                              <td style="border-radius:8px;background:#2563eb;">
                                <a href="{encodedUrl}"
                                   style="display:inline-block;padding:14px 28px;color:#ffffff;text-decoration:none;font-size:16px;font-weight:600;">
                                  Hoặc xác nhận qua link
                                </a>
                              </td>
                            </tr>
                          </table>
                          <p style="margin:0 0 8px;color:#64748b;font-size:13px;line-height:1.5;">
                            Nếu nút không hoạt động, copy link sau vào trình duyệt:
                          </p>
                          <p style="margin:0;word-break:break-all;">
                            <a href="{encodedUrl}" style="color:#2563eb;font-size:12px;">{encodedUrl}</a>
                          </p>
                          <p style="margin:24px 0 0;color:#94a3b8;font-size:12px;line-height:1.5;">
                            Link có hiệu lực một lần. Nếu bạn không đăng ký, hãy bỏ qua email này.
                          </p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </body>
            </html>
            """;
    }

    public static string BuildPasswordResetHtml(string recipientEmail, string resetCode)
    {
        var encodedEmail = System.Net.WebUtility.HtmlEncode(recipientEmail);
        var encodedCode = System.Net.WebUtility.HtmlEncode(resetCode);

        return $"""
            <!DOCTYPE html>
            <html lang="vi">
            <head>
              <meta charset="utf-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1" />
              <title>Đặt lại mật khẩu</title>
            </head>
            <body style="margin:0;padding:0;background:#f4f6f8;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f6f8;padding:32px 16px;">
                <tr>
                  <td align="center">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:520px;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
                      <tr>
                        <td style="background:linear-gradient(135deg,#16a34a,#0f766e);padding:28px 32px;">
                          <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:600;">Sync Lifestyle</h1>
                          <p style="margin:8px 0 0;color:#d1fae5;font-size:14px;">Yêu cầu đặt lại mật khẩu</p>
                        </td>
                      </tr>
                      <tr>
                        <td style="padding:32px;">
                          <p style="margin:0 0 16px;color:#334155;font-size:15px;line-height:1.6;">
                            Xin chào,<br />
                            Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản <strong>{encodedEmail}</strong>.
                            Nhập mã bên dưới vào ứng dụng để tạo mật khẩu mới.
                          </p>
                          <div style="margin:16px 0 20px;padding:16px;border:1px dashed #94a3b8;border-radius:10px;background:#f8fafc;text-align:center;">
                            <div style="font-size:12px;color:#64748b;margin-bottom:6px;">MÃ ĐẶT LẠI MẬT KHẨU</div>
                            <div style="font-size:30px;letter-spacing:8px;font-weight:700;color:#0f172a;">{encodedCode}</div>
                          </div>
                          <p style="margin:24px 0 0;color:#94a3b8;font-size:12px;line-height:1.5;">
                            Mã có hiệu lực trong 15 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này — mật khẩu của bạn vẫn an toàn.
                          </p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </body>
            </html>
            """;
    }

    public static string BuildVerifyResultHtml(bool success, string title, string message)
    {
        var color = success ? "#16a34a" : "#dc2626";
        var icon = success ? "✓" : "✕";
        var encodedTitle = System.Net.WebUtility.HtmlEncode(title);
        var encodedMessage = System.Net.WebUtility.HtmlEncode(message);

        return $"""
            <!DOCTYPE html>
            <html lang="vi">
            <head>
              <meta charset="utf-8" />
              <meta name="viewport" content="width=device-width, initial-scale=1" />
              <title>{encodedTitle}</title>
            </head>
            <body style="margin:0;padding:0;background:#f4f6f8;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="padding:48px 16px;">
                <tr>
                  <td align="center">
                    <table role="presentation" style="max-width:440px;background:#fff;border-radius:12px;padding:40px 32px;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
                      <tr>
                        <td align="center">
                          <div style="width:64px;height:64px;border-radius:50%;background:{color};color:#fff;font-size:32px;line-height:64px;text-align:center;">{icon}</div>
                          <h1 style="margin:24px 0 12px;color:#0f172a;font-size:22px;">{encodedTitle}</h1>
                          <p style="margin:0;color:#64748b;font-size:15px;line-height:1.6;">{encodedMessage}</p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </body>
            </html>
            """;
    }
}
