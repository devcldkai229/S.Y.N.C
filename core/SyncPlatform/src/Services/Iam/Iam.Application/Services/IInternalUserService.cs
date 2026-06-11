using Iam.Application.DTOs;

namespace Iam.Application.Services;

public interface IInternalUserService
{
    Task<InternalAuthorSnapshotDto?> GetAuthorSnapshotAsync(Guid userId, CancellationToken cancellationToken = default);
}
