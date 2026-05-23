using Notification.Application.Services;
using Microsoft.Extensions.DependencyInjection;

namespace Notification.Application.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddNotificationApplication(this IServiceCollection services)
    {
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<INotificationTemplateService, NotificationTemplateService>();

        return services;
    }
}
