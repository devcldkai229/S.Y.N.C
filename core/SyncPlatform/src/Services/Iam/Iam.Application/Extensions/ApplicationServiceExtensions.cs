using Iam.Application.Services;
using Microsoft.Extensions.DependencyInjection;

namespace Iam.Application.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddIamApplication(this IServiceCollection services)
    {
        services.AddScoped<IBiometricProfileService, BiometricProfileService>();

        return services;
    }
}
