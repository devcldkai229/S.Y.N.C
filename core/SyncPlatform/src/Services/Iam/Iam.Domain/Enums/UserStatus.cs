namespace Iam.Domain.Enums;

/// <summary>
/// Vòng đời tài khoản — AI orchestration chỉ auto-execute khi trạng thái là Active.
/// </summary>
public enum UserStatus
{
    Onboarding = 0,
    Active = 1,
    Suspended = 2,
    PendingVerification = 3,
    Deleted = 4
}
