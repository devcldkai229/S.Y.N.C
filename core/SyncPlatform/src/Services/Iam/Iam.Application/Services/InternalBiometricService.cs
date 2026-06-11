using Iam.Application.DTOs;
using Iam.Domain.Repositories;

namespace Iam.Application.Services;

public class InternalBiometricService : IInternalBiometricService
{
    private readonly IBiometricProfileRepository _biometricRepository;

    public InternalBiometricService(IBiometricProfileRepository biometricRepository)
    {
        _biometricRepository = biometricRepository;
    }

    public async Task<InternalNutritionTargetsDto?> GetNutritionTargetsAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var profile = await _biometricRepository.GetByUserIdAsync(userId, cancellationToken);
        if (profile == null)
            return null;

        return new InternalNutritionTargetsDto
        {
            TargetCalories = profile.BaseTDEE,
            TargetProteinGram = profile.DailyProteinTargetGram,
            TargetCarbGram = profile.DailyCarbTargetGram,
            TargetFatGram = profile.DailyFatTargetGram,
        };
    }
}
