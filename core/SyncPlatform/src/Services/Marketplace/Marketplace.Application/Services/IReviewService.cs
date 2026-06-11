using Marketplace.Application.Common;
using Marketplace.Application.DTOs;

namespace Marketplace.Application.Services;

public interface IReviewService
{
    Task<ReviewDto> CreateAsync(Guid userId, CreateReviewDto dto, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<ReviewDto> Items, PaginationMetadata Pagination)> ListByTargetAsync(
        ReviewListRequest request,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<ReviewDto> Items, PaginationMetadata Pagination)> ListForPartnerAsync(
        Guid ownerUserId,
        Guid partnerId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<ReviewDto> ReplyAsync(Guid ownerUserId, Guid partnerId, Guid reviewId, PartnerReplyDto dto, CancellationToken cancellationToken = default);
}
