using Notification.Application.Services;
using Microsoft.Extensions.DependencyInjection;

namespace Notification.Application.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddNotificationApplication(this IServiceCollection services)
    {
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<INotificationTemplateService, NotificationTemplateService>();
        services.AddScoped<Notification.Application.Services.SmartPush.ISmartPushDecisionService, Notification.Application.Services.SmartPush.SmartPushDecisionService>();
        services.AddScoped<Notification.Application.Services.SmartPush.ISmartPushNotificationService, Notification.Application.Services.SmartPush.SmartPushNotificationService>();
        services.AddScoped<Notification.Application.Services.SmartPush.ISmartPushAiUsagePolicy, Notification.Application.Services.SmartPush.SmartPushAiUsagePolicy>();
        services.AddScoped<Notification.Application.Services.SmartPush.ISmartPushDeepLinkResolver, Notification.Application.Services.SmartPush.SmartPushDeepLinkResolver>();
        services.AddScoped<Notification.Application.Services.SmartPush.ISmartPushTemplateService, Notification.Application.Services.SmartPush.SmartPushTemplateService>();

        return services;
    }
}
