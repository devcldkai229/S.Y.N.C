namespace Iam.Application.Abstractions;

/// <summary>
/// Best-effort fan-out to Payment / Social after account soft-delete.
/// </summary>
public interface IAccountDeletionCascadeClient
{
    Task NotifyDeletedAsync(Guid userId, CancellationToken cancellationToken = default);
}
