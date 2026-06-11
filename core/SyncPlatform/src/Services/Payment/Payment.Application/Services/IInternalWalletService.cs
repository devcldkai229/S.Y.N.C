using Payment.Application.DTOs;

namespace Payment.Application.Services;

public interface IInternalWalletService
{
    Task<ChargeMealOrderResponseDto> ChargeMealOrderAsync(
        ChargeMealOrderRequestDto request,
        CancellationToken cancellationToken = default);

    Task<RefundMealOrderResponseDto> RefundMealOrderAsync(
        RefundMealOrderRequestDto request,
        CancellationToken cancellationToken = default);
}
