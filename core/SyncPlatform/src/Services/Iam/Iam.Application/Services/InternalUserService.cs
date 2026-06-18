using Iam.Application.DTOs;
using Iam.Domain.Repositories;
using Libs.Storage.Services;

namespace Iam.Application.Services;

public class InternalUserService : IInternalUserService
{
    private readonly IUserRepository _userRepository;
    private readonly IMediaUrlResolver _media;

    public InternalUserService(IUserRepository userRepository, IMediaUrlResolver media)
    {
        _userRepository = userRepository;
        _media = media;
    }

    public async Task<InternalAuthorSnapshotDto?> GetAuthorSnapshotAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.GetByIdAsync(userId, cancellationToken);
        if (user == null)
            return null;

        return new InternalAuthorSnapshotDto
        {
            FullName = user.FullName,
            AvatarUrl = _media.ResolveForDisplay(user.AvatarUrl),
        };
    }
}
