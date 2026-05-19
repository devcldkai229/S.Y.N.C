namespace Payment.Domain.Enums;

public enum SpendingAuthorizationType
{
    ManualApproval = 0,
    AiAutoApproved = 1,
    ThresholdApproved = 2,
    EmergencyBlocked = 3
}
