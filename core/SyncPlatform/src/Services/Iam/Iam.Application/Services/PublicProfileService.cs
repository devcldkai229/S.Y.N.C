using Iam.Application.DTOs;
using Iam.Application.Exceptions;
using Iam.Domain.Enums;
using Iam.Domain.Repositories;

namespace Iam.Application.Services;

public class PublicProfileService : IPublicProfileService
{
    private readonly IUserRepository _users;

    public PublicProfileService(IUserRepository users)
    {
        _users = users;
    }

    public async Task<PublicProfileResponse> GetPublicProfileAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var user = await _users.GetByIdForPublicProfileAsync(userId, cancellationToken)
            ?? throw new NotFoundException("User not found.");

        if (user.Status is UserStatus.Deleted or UserStatus.Suspended)
            throw new NotFoundException("User not found.");

        var gamification = user.GamificationProfile;

        return new PublicProfileResponse(
            UserId: user.Id,
            FullName: user.FullName,
            AvatarUrl: user.AvatarUrl,
            BackgroundImageUrl: user.BackgroundImageUrl,
            CurrentLevel: gamification?.CurrentLevel ?? 1,
            CurrentXP: gamification?.CurrentXP ?? 0,
            CurrentStreak: gamification?.CurrentStreak ?? 0);
    }
}
