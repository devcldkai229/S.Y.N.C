using Payment.Application.DTOs;

namespace Payment.Application.Services;

public interface IVoucherService
{
    Task<IReadOnlyList<VoucherAvailableItemDto>> GetAvailableAsync(
        Guid userId,
        decimal orderAmount,
        Guid? partnerId,
        CancellationToken cancellationToken = default);

    Task<ValidateVoucherResponseDto> ValidateAsync(
        Guid userId,
        ValidateVoucherRequestDto request,
        CancellationToken cancellationToken = default);

    Task<ValidateVoucherResponseDto> ValidateInternalAsync(
        Guid userId,
        ValidateVoucherRequestDto request,
        CancellationToken cancellationToken = default);

    Task MarkUsedAsync(
        Guid userId,
        string code,
        Guid orderId,
        CancellationToken cancellationToken = default);
}
