using Nutrition.Application.DTOs;

namespace Nutrition.Application.Clients;

public interface IIamBiometricClient
{
    Task<NutritionTargetsDto?> GetNutritionTargetsAsync(Guid userId, CancellationToken cancellationToken = default);
}
