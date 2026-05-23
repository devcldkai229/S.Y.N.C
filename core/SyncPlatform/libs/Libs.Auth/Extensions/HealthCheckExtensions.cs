using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;

namespace Libs.Auth.Extensions;

public static class HealthCheckExtensions
{
    public static IServiceCollection AddSyncHealthChecks(this IServiceCollection services)
    {
        services.AddHealthChecks();
        return services;
    }

    public static WebApplication MapSyncHealthChecks(this WebApplication app)
    {
        app.MapHealthChecks("/health").AllowAnonymous();
        return app;
    }
}
