using Iam.Application.DTOs;

namespace Iam.Application.Services;

public interface IInternalBiometricService
{
    Task<InternalNutritionTargetsDto?> GetNutritionTargetsAsync(Guid userId, CancellationToken cancellationToken = default);
}
