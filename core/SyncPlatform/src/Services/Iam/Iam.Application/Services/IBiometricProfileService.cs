using Iam.Application.DTOs;

namespace Iam.Application.Services;

public interface IBiometricProfileService
{
    Task<BiometricProfileDto> GetProfileAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<BiometricProfileDto> SaveBasicInfoAsync(Guid userId, OnboardingStep1Dto dto, CancellationToken cancellationToken = default);
    Task<BiometricProfileDto> SaveGoalsAsync(Guid userId, OnboardingStep2Dto dto, CancellationToken cancellationToken = default);
    Task<BiometricProfileDto> SaveCompositionAsync(Guid userId, OnboardingStep3Dto dto, CancellationToken cancellationToken = default);
    Task<BiometricProfileDto> SaveSafeguardsAsync(Guid userId, OnboardingStep4Dto dto, CancellationToken cancellationToken = default);
    Task<OnboardingCompleteResultDto> CompleteOnboardingAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<BiometricProfileDto> LogWeightAsync(Guid userId, UpdateWeightDto dto, CancellationToken cancellationToken = default);
}
