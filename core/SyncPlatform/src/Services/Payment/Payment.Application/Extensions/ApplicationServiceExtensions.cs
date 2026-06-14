using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Payment.Application.Options;

namespace Payment.Application.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddPaymentApplication(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<PayosSettings>(configuration.GetSection(PayosSettings.SectionName));
        services.Configure<MomoSettings>(configuration.GetSection(MomoSettings.SectionName));
        // JwtAuthSettings is configured by Libs.Auth.AddSyncJwtAuthentication() at the API layer.
        return services;
    }
}
