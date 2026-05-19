namespace Iam.Domain.Enums;

/// <summary>
/// Vai trò trong nền tảng — agent routing có thể giới hạn tool theo role (ví dụ Partner chỉ storefront).
/// </summary>
public enum UserRole
{
    User = 0,
    Partner = 1,
    SystemAdmin = 2
}
