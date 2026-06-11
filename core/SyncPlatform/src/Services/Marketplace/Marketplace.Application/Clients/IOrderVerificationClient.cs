using Marketplace.Domain.Enums;

namespace Marketplace.Application.Clients;

public class OrderVerificationResult
{
    public bool IsVerified { get; set; }

    public Guid? OrderId { get; set; }
}

public interface IOrderVerificationClient
{
    Task<OrderVerificationResult> VerifyPurchaseAsync(
        Guid userId,
        ReviewTargetType targetType,
        Guid targetId,
        Guid? orderId,
        CancellationToken cancellationToken = default);
}
