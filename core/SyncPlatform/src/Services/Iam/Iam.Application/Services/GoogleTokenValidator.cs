using Google.Apis.Auth;
using Iam.Application.Abstractions;
using Iam.Application.Exceptions;
using Iam.Application.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Iam.Application.Services;

public class GoogleTokenValidator : IGoogleTokenValidator
{
    private readonly GoogleAuthSettings _settings;
    private readonly ILogger<GoogleTokenValidator> _logger;

    public GoogleTokenValidator(IOptions<GoogleAuthSettings> options, ILogger<GoogleTokenValidator> logger)
    {
        _settings = options.Value;
        _logger = logger;
    }

    public async Task<GoogleUserInfo> ValidateAsync(string idToken, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(idToken))
            throw new BadRequestException("Google ID token is required.");

        try
        {
            var validationSettings = new GoogleJsonWebSignature.ValidationSettings();
            var allowedClientIds = _settings.GetAllowedClientIds();
            if (allowedClientIds.Count > 0)
                validationSettings.Audience = allowedClientIds;

            var payload = await GoogleJsonWebSignature.ValidateAsync(idToken, validationSettings);

            if (!payload.EmailVerified)
            {
                _logger.LogWarning("Google ID token rejected: email not verified by Google ({Email})", payload.Email);
                throw new UnauthorizedException("Google account email is not verified.");
            }

            _logger.LogDebug(
                "Google ID token validated (email={Email}, aud={Audience})",
                payload.Email,
                payload.Audience);

            return new GoogleUserInfo(
                Subject: payload.Subject,
                Email: payload.Email,
                Name: payload.Name ?? payload.Email,
                Picture: payload.Picture);
        }
        catch (InvalidJwtException ex)
        {
            _logger.LogWarning(ex, "Google ID token JWT validation failed");
            throw new UnauthorizedException($"Invalid Google ID token: {ex.Message}");
        }
    }
}
