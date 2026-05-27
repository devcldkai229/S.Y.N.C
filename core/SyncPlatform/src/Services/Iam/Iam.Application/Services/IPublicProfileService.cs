using Iam.Application.DTOs;

namespace Iam.Application.Services;

public interface IPublicProfileService
{
    Task<PublicProfileResponse> GetPublicProfileAsync(Guid userId, CancellationToken cancellationToken = default);
}
