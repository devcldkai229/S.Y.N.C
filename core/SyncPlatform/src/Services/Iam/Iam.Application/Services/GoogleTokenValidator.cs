using Google.Apis.Auth;
using Iam.Application.Abstractions;
using Iam.Application.Exceptions;
using Iam.Application.Options;
using Microsoft.Extensions.Options;

namespace Iam.Application.Services;

public class GoogleTokenValidator : IGoogleTokenValidator
{
    private readonly GoogleAuthSettings _settings;

    public GoogleTokenValidator(IOptions<GoogleAuthSettings> options)
    {
        _settings = options.Value;
    }

    public async Task<GoogleUserInfo> ValidateAsync(string idToken, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(idToken))
            throw new BadRequestException("Google ID token is required.");

        try
        {
            var validationSettings = new GoogleJsonWebSignature.ValidationSettings();
            if (!string.IsNullOrWhiteSpace(_settings.ClientId))
                validationSettings.Audience = new[] { _settings.ClientId };

            var payload = await GoogleJsonWebSignature.ValidateAsync(idToken, validationSettings);

            if (!payload.EmailVerified)
                throw new UnauthorizedException("Google account email is not verified.");

            return new GoogleUserInfo(
                Subject: payload.Subject,
                Email: payload.Email,
                Name: payload.Name ?? payload.Email,
                Picture: payload.Picture);
        }
        catch (InvalidJwtException ex)
        {
            throw new UnauthorizedException($"Invalid Google ID token: {ex.Message}");
        }
    }
}
