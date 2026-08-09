using Iam.Application.DTOs;

namespace Iam.Application.Services;

public interface IInternalSmartPushService
{
    /// <summary>Legacy PreferredReminderTime-based scan — kept for compatibility; schedule engine owns due timing.</summary>
    Task<IReadOnlyList<DueSmartPushUserDto>> GetDueUsersAsync(DateTime utcNow, CancellationToken cancellationToken);

    Task<IReadOnlyList<SmartPushEnabledUserDto>> GetEnabledUsersAsync(CancellationToken cancellationToken);

    Task<IamSmartPushContextDto?> GetSmartPushContextAsync(Guid userId, CancellationToken cancellationToken);

    Task<IReadOnlyList<Guid>> GetPremiumOrUltraUserIdsAsync(CancellationToken cancellationToken);
}
