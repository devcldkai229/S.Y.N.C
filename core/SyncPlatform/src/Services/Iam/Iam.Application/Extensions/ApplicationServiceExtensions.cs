using Iam.Application.Abstractions;
using Iam.Application.Options;
using Iam.Application.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Iam.Application.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddIamApplication(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<JwtSettings>(configuration.GetSection(JwtSettings.SectionName));
        services.Configure<GoogleAuthSettings>(configuration.GetSection(GoogleAuthSettings.SectionName));

        services.AddSingleton<IPasswordHasher, BcryptPasswordHasher>();
        services.AddSingleton<IJwtTokenService, JwtTokenService>();
        services.AddSingleton<IGoogleTokenValidator, GoogleTokenValidator>();
        services.AddSingleton<IEmailSender, ConsoleEmailSender>();

        services.AddScoped<IAuthService, AuthService>();

        return services;
    }
}
