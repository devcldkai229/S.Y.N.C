using Microsoft.Extensions.DependencyInjection;

namespace Order.Application.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddOrderApplication(this IServiceCollection services)
    {
        return services;
    }
}
