namespace Notification.Application.Services.SmartPush;

public class SmartPushDecision
{
    public bool ShouldSend { get; set; }
    public string TriggerType { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;

    public static SmartPushDecision Skip(string reason) => new()
    {
        ShouldSend = false,
        Reason = reason
    };

    public static SmartPushDecision Send(string triggerType, string reason) => new()
    {
        ShouldSend = true,
        TriggerType = triggerType,
        Reason = reason
    };
}
