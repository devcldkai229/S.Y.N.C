using Iam.Application.DTOs;
using Iam.Domain.Repositories;

namespace Iam.Application.Services;

public class InternalUserService : IInternalUserService
{
    private readonly IUserRepository _userRepository;

    public InternalUserService(IUserRepository userRepository)
    {
        _userRepository = userRepository;
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
            AvatarUrl = user.AvatarUrl,
        };
    }
}
