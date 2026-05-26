using Notification.Application.DTOs.SmartPush;
using Notification.Application.Services.SmartPush;

namespace Notification.Application.Clients;

public interface IDeepSeekClient
{
    Task<GeneratedPushMessageDto> GenerateAsync(
        SmartPushContextDto context, 
        SmartPushDecision decision, 
        string deepLink, 
        CancellationToken cancellationToken);
}
