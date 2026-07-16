using Notification.Application.DTOs.SmartPush;

namespace Notification.Application.Services.SmartPush;

public interface ISmartPushDecisionService
{
    Task<SmartPushDecision> DecideAsync(SmartPushContextDto context, CancellationToken ct);
}
