using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Services.SmartPush;

public interface ISmartPushDeepLinkResolver
{
    string ResolveDeepLink(SmartPushContextDto context, SmartPushDecision decision);
}
