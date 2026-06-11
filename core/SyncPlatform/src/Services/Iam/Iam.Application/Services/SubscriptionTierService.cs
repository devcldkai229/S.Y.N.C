using Iam.Application.Abstractions;
using Iam.Application.Exceptions;
using Iam.Domain.Enums;
using Iam.Domain.Repositories;

namespace Iam.Application.Services;

public class SubscriptionTierService : ISubscriptionTierService
{
    private readonly IUserRepository _userRepository;

    public SubscriptionTierService(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task SetTierAsync(Guid userId, SubscriptionTier tier, CancellationToken cancellationToken = default)
    {
        var user = await _userRepository.GetByIdAsync(userId, cancellationToken)
            ?? throw new NotFoundException("User", userId);

        user.SubscriptionTier = tier;
        user.UpdatedAt        = DateTimeOffset.UtcNow;

        await _userRepository.UpdateAsync(user, cancellationToken);
        await _userRepository.SaveChangesAsync(cancellationToken);
    }
}
