namespace Iam.Application.Abstractions;

public record GoogleUserInfo(string Subject, string Email, string Name, string? Picture);

public interface IGoogleTokenValidator
{
    /// <summary>Validate a Google ID token and extract user info. Throws if invalid.</summary>
    Task<GoogleUserInfo> ValidateAsync(string idToken, CancellationToken cancellationToken = default);
}
