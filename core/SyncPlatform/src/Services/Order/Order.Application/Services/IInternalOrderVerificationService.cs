using Order.Application.DTOs;

namespace Order.Application.Services;

public interface IInternalOrderVerificationService
{
    Task<OrderVerificationResultDto> VerifyPurchaseAsync(
        Guid userId,
        string targetType,
        Guid targetId,
        Guid? orderId,
        CancellationToken cancellationToken = default);
}
