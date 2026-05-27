using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Services.SmartPush;

public interface ISmartPushTemplateService
{
    GeneratedPushMessageDto BuildMessage(SmartPushContextDto context, SmartPushDecision decision, string deepLink);
}
