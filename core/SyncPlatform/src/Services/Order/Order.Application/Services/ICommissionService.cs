using Order.Application.Common;
using Order.Application.DTOs;

namespace Order.Application.Services;

public interface ICommissionService
{
    Task CreateFoodDeliveryCommissionAsync(Guid orderId, CancellationToken cancellationToken = default);

    Task<int> ReconcileAffiliateAsync(AffiliateReconcileRequest request, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<CommissionRecordDto> Items, PaginationMetadata Pagination)> ListAsync(
        CommissionListRequest request,
        CancellationToken cancellationToken = default);

    Task<CommissionRevenueSummaryDto> GetRevenueSummaryAsync(
        CommissionListRequest request,
        CancellationToken cancellationToken = default);

    Task<CommissionRecordDto> MarkPaidAsync(Guid id, MarkCommissionPaidDto dto, CancellationToken cancellationToken = default);
}
