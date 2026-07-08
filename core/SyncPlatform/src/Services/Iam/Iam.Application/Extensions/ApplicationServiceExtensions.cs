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
        // JwtAuthSettings is configured by Libs.Auth.AddSyncJwtAuthentication() at the API layer.
        services.Configure<GoogleAuthSettings>(configuration.GetSection(GoogleAuthSettings.SectionName));
        services.Configure<EmailSettings>(configuration.GetSection(EmailSettings.SectionName));
        services.AddScoped<IBiometricProfileService, BiometricProfileService>();
        services.AddScoped<UserMeService>();
        services.AddScoped<IAchievementService, AchievementService>();
        services.AddScoped<IGamificationService, GamificationService>();
        services.AddScoped<IShopService, ShopService>();
        services.AddScoped<IInternalSmartPushService, InternalSmartPushService>();
        services.AddScoped<IInternalBiometricService, InternalBiometricService>();
        services.AddScoped<IInternalUserService, InternalUserService>();
        services.AddScoped<IInternalAiContextService, InternalAiContextService>();
        services.AddSingleton<IPasswordHasher, BcryptPasswordHasher>();
        services.AddSingleton<IJwtTokenService, JwtTokenService>();
        services.AddSingleton<IGoogleTokenValidator, GoogleTokenValidator>();

        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IPublicProfileService, PublicProfileService>();
        services.AddScoped<IUserSearchService, UserSearchService>();
        services.AddScoped<IAdminUserService, AdminUserService>();
        services.AddScoped<IAdminDashboardService, AdminDashboardService>();
        services.AddScoped<ISubscriptionTierService, SubscriptionTierService>();

        return services;
    }
}
