using Payment.Application.DTOs;

namespace Payment.Application.Services;

public interface IOrderPaymentService
{
    Task<WalletBalanceDto> GetWalletBalanceAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<ChargeOrderWalletResponseDto> ChargeOrderWalletAsync(
        ChargeOrderWalletRequestDto request,
        CancellationToken cancellationToken = default);

    Task<CreateCodTransactionResponseDto> CreateCodTransactionAsync(
        CreateCodTransactionRequestDto request,
        CancellationToken cancellationToken = default);

    Task<CreateVietQrPaymentResponseDto> CreateVietQrPaymentAsync(
        CreateVietQrPaymentRequestDto request,
        CancellationToken cancellationToken = default);

    Task<CreateMomoPaymentResponseDto> CreateMomoPaymentAsync(
        CreateMomoPaymentRequestDto request,
        CancellationToken cancellationToken = default);

    Task<MomoIpnResultDto> ProcessMomoIpnAsync(
        MomoIpnPayloadDto payload,
        string rawJson,
        CancellationToken cancellationToken = default);
}
