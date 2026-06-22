using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Services.SmartPush;

public interface ISmartPushDecisionService
{
    SmartPushDecision Decide(SmartPushContextDto context, string topic);
}
