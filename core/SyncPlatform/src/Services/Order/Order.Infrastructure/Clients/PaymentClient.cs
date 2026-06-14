using System.Net.Http.Json;
using System.Text.Json;
using Order.Application.Clients;
using Order.Application.Common;

namespace Order.Infrastructure.Clients;

public class PaymentClient : IPaymentClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOpts = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };

    public PaymentClient(HttpClient httpClient) => _httpClient = httpClient;

    public async Task<ChargeMealOrderResult> ChargeMealOrderAsync(
        ChargeMealOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/internal/order-payments/charge-wallet", new
        {
            request.UserId,
            request.OrderId,
            request.Amount,
            request.Currency,
            request.IsAiInitiated,
        }, JsonOpts, cancellationToken);

        if (!response.IsSuccessStatusCode)
            return new ChargeMealOrderResult { Success = false, FailureReason = "Payment service rejected the charge." };

        var api = await response.Content.ReadFromJsonAsync<ApiResponse<ChargeMealOrderResult>>(JsonOpts, cancellationToken);
        return api?.Data ?? new ChargeMealOrderResult { Success = false, FailureReason = "Empty payment response." };
    }

    public async Task<RefundMealOrderResult> RefundMealOrderAsync(
        RefundMealOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/internal/wallet/refund-meal-order", request, JsonOpts, cancellationToken);
        if (!response.IsSuccessStatusCode)
            return new RefundMealOrderResult { Success = false, FailureReason = "Refund failed." };

        var api = await response.Content.ReadFromJsonAsync<ApiResponse<RefundMealOrderResult>>(JsonOpts, cancellationToken);
        return api?.Data ?? new RefundMealOrderResult { Success = false };
    }

    public async Task<ValidateVoucherResult> ValidateVoucherAsync(
        ValidateVoucherRequest request,
        CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/internal/vouchers/validate", request, JsonOpts, cancellationToken);
        if (!response.IsSuccessStatusCode)
            return new ValidateVoucherResult { Valid = false, Message = "Không thể kiểm tra voucher." };

        var api = await response.Content.ReadFromJsonAsync<ApiResponse<ValidateVoucherResult>>(JsonOpts, cancellationToken);
        return api?.Data ?? new ValidateVoucherResult { Valid = false, Message = "Empty voucher response." };
    }

    public async Task MarkVoucherUsedAsync(
        MarkVoucherUsedRequest request,
        CancellationToken cancellationToken = default)
    {
        await _httpClient.PostAsJsonAsync("/api/internal/vouchers/mark-used", request, JsonOpts, cancellationToken);
    }

    public async Task<CreateCodPaymentResult> CreateCodTransactionAsync(
        CreateCodPaymentRequest request,
        CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/internal/order-payments/cod", request, JsonOpts, cancellationToken);
        if (!response.IsSuccessStatusCode)
            return new CreateCodPaymentResult { Success = false };

        var api = await response.Content.ReadFromJsonAsync<ApiResponse<CreateCodPaymentResult>>(JsonOpts, cancellationToken);
        return api?.Data ?? new CreateCodPaymentResult { Success = false };
    }

    public async Task<CreateVietQrPaymentResult> CreateVietQrPaymentAsync(
        CreateVietQrPaymentRequest request,
        CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/internal/order-payments/vietqr/create", new
        {
            request.UserId,
            request.OrderId,
            request.OrderCode,
            request.Amount,
            request.Currency,
        }, JsonOpts, cancellationToken);

        if (!response.IsSuccessStatusCode)
            return new CreateVietQrPaymentResult { Success = false, FailureReason = "VietQR payment failed." };

        var api = await response.Content.ReadFromJsonAsync<ApiResponse<CreateVietQrPaymentResult>>(JsonOpts, cancellationToken);
        return api?.Data ?? new CreateVietQrPaymentResult { Success = false, FailureReason = "Empty VietQR response." };
    }

    public async Task<CreateMomoPaymentResult> CreateMomoPaymentAsync(
        CreateMomoPaymentRequest request,
        CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/internal/order-payments/momo/create", new
        {
            request.UserId,
            request.OrderId,
            request.OrderCode,
            request.Amount,
            request.Currency,
            orderInfo = $"Thanh toan don {request.OrderCode}",
        }, JsonOpts, cancellationToken);

        if (!response.IsSuccessStatusCode)
            return new CreateMomoPaymentResult { Success = false, FailureReason = "MoMo payment failed." };

        var api = await response.Content.ReadFromJsonAsync<ApiResponse<CreateMomoPaymentResult>>(JsonOpts, cancellationToken);
        return api?.Data ?? new CreateMomoPaymentResult { Success = false, FailureReason = "Empty MoMo response." };
    }
}
