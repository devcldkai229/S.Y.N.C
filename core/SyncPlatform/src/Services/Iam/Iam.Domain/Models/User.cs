using Libs.Shared.Common;
using Iam.Domain.Enums;

namespace Iam.Domain.Models;

public class User : BaseAuditableEntity
{
    public User()
    {
        Devices = new HashSet<UserDevice>();
        Assets = new HashSet<UserAsset>();
        Achievements = new HashSet<UserAchievement>();
        Vouchers = new HashSet<UserVoucher>();
    }

    public string Email { get; set; } = string.Empty;

    public string? PhoneNumber { get; set; }

    public string PasswordHash { get; set; } = string.Empty;

    public string FullName { get; set; } = string.Empty;

    public string? AvatarUrl { get; set; }

    public UserRole Role { get; set; }

    public UserStatus Status { get; set; }

    public SubscriptionTier SubscriptionTier { get; set; }

    public bool EmailVerified { get; set; }

    public string? EmailVerificationToken { get; set; }

    /// <summary>6-digit OTP code for password reset (null when no reset is pending).</summary>
    public string? PasswordResetToken { get; set; }

    /// <summary>Expiry time for <see cref="PasswordResetToken"/> (UTC).</summary>
    public DateTimeOffset? PasswordResetTokenExpiresAt { get; set; }

    public bool PhoneVerified { get; set; }

    public string PreferredLanguage { get; set; } = string.Empty;

    public string TimeZone { get; set; } = string.Empty;

    public DateTimeOffset? LastLoginAt { get; set; }

    public DateTimeOffset? LastActiveAt { get; set; }

    public virtual BiometricProfile? BiometricProfile { get; set; }

    public virtual UserPreference? UserPreference { get; set; }

    public virtual AIContextProfile? AIContextProfile { get; set; }

    public virtual GamificationProfile? GamificationProfile { get; set; }

    public virtual ICollection<UserDevice> Devices { get; set; }

    public virtual ICollection<UserAsset> Assets { get; set; }

    public virtual ICollection<UserAchievement> Achievements { get; set; }

    /// <summary>
    /// Vouchers/coupons owned by this user — inventory asset, not a financial record.
    /// </summary>
    public virtual ICollection<UserVoucher> Vouchers { get; set; }
}
