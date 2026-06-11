using Marketplace.Application.DTOs;

namespace Marketplace.Application.Clients;

public interface IIamUserClient
{
    Task<AuthorSnapshotDto?> GetAuthorSnapshotAsync(Guid userId, CancellationToken cancellationToken = default);
}
