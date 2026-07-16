using Notification.Application.Services;
using Notification.Application.Services.SmartPush;
using Microsoft.Extensions.DependencyInjection;

namespace Notification.Application.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddNotificationApplication(this IServiceCollection services)
    {
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<INotificationTemplateService, NotificationTemplateService>();
        services.AddScoped<ISmartPushDecisionService, SmartPushDecisionService>();
        services.AddScoped<ISmartPushNotificationService, SmartPushNotificationService>();
        services.AddScoped<ISmartPushAiUsagePolicy, SmartPushAiUsagePolicy>();
        services.AddScoped<ISmartPushDeepLinkResolver, SmartPushDeepLinkResolver>();
        services.AddScoped<ISmartPushTemplateService, SmartPushTemplateService>();
        services.AddScoped<ISmartPushScheduleService, SmartPushScheduleService>();
        services.AddSingleton<ISmartPushGenerationCache, SmartPushGenerationCache>();

        return services;
    }
}
