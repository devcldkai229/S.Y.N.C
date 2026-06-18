using Iam.Application.DTOs;
using Iam.Application.Exceptions;
using Iam.Domain.Enums;
using Iam.Domain.Repositories;
using Libs.Storage.Services;

namespace Iam.Application.Services;

public class PublicProfileService : IPublicProfileService
{
    private readonly IUserRepository _users;
    private readonly IMediaUrlResolver _media;

    public PublicProfileService(IUserRepository users, IMediaUrlResolver media)
    {
        _users = users;
        _media = media;
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
            AvatarUrl: _media.ResolveForDisplay(user.AvatarUrl),
            BackgroundImageUrl: _media.ResolveForDisplay(user.BackgroundImageUrl),
            CurrentLevel: gamification?.CurrentLevel ?? 1,
            CurrentXP: gamification?.CurrentXP ?? 0,
            CurrentStreak: gamification?.CurrentStreak ?? 0);
    }
}
