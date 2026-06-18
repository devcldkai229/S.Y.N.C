using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Services.SmartPush;

public interface ISmartPushAiUsagePolicy
{
    bool ShouldUseAi(SmartPushContextDto context, SmartPushDecision decision);
}
