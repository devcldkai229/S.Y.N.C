using System.ComponentModel.DataAnnotations;
using Iam.Domain.Enums;

namespace Iam.Application.DTOs;

public class AdminUserListItemDto
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public UserRole Role { get; set; }
    public UserStatus Status { get; set; }
    public SubscriptionTier SubscriptionTier { get; set; }
    public bool EmailVerified { get; set; }
    public DateTimeOffset? LastActiveAt { get; set; }
    public DateTimeOffset? LastLoginAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

public class UpdateUserStatusDto
{
    [Required]
    public UserStatus Status { get; set; }
}

public class UpdateUserRoleDto
{
    [Required]
    public UserRole Role { get; set; }
}
