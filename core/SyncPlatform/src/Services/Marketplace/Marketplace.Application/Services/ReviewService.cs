using Marketplace.Application.Clients;
using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Exceptions;
using Marketplace.Application.Helpers;
using Marketplace.Application.Mappers;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Models;
using Marketplace.Domain.Repositories;

namespace Marketplace.Application.Services;

public class ReviewService : IReviewService
{
    private readonly IReviewRepository _reviewRepository;
    private readonly IPartnerRepository _partnerRepository;
    private readonly IFoodMenuItemRepository _foodMenuItemRepository;
    private readonly IAffiliateProductRepository _affiliateProductRepository;
    private readonly IIamUserClient _iamUserClient;
    private readonly IOrderVerificationClient _orderVerificationClient;

    public ReviewService(
        IReviewRepository reviewRepository,
        IPartnerRepository partnerRepository,
        IFoodMenuItemRepository foodMenuItemRepository,
        IAffiliateProductRepository affiliateProductRepository,
        IIamUserClient iamUserClient,
        IOrderVerificationClient orderVerificationClient)
    {
        _reviewRepository = reviewRepository;
        _partnerRepository = partnerRepository;
        _foodMenuItemRepository = foodMenuItemRepository;
        _affiliateProductRepository = affiliateProductRepository;
        _iamUserClient = iamUserClient;
        _orderVerificationClient = orderVerificationClient;
    }

    public async Task<ReviewDto> CreateAsync(
        Guid userId,
        CreateReviewDto dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.Rating is < 1 or > 5)
            throw new BadRequestException("Rating must be between 1 and 5.");

        await EnsureTargetExistsAsync(dto.TargetType, dto.TargetId, cancellationToken);

        var verification = dto.TargetType == ReviewTargetType.AffiliateProduct
            ? new OrderVerificationResult()
            : await _orderVerificationClient.VerifyPurchaseAsync(
                userId, dto.TargetType, dto.TargetId, dto.OrderId, cancellationToken);

        var orderId = verification.OrderId ?? dto.OrderId;
        var existing = await _reviewRepository.GetByUserTargetOrderAsync(
            userId, dto.TargetType, dto.TargetId, orderId, cancellationToken);
        if (existing != null)
            throw new ConflictException("You have already reviewed this target for the given order.");

        var author = await _iamUserClient.GetAuthorSnapshotAsync(userId, cancellationToken)
            ?? new AuthorSnapshotDto { FullName = "SYNC User" };

        var review = new Review
        {
            UserId = userId,
            AuthorSnapshot = new AuthorSnapshot
            {
                FullName = author.FullName,
                AvatarUrl = author.AvatarUrl,
            },
            TargetType = dto.TargetType,
            TargetId = dto.TargetId,
            Rating = dto.Rating,
            Comment = dto.Comment?.Trim(),
            ImageUrls = dto.ImageUrls,
            OrderId = orderId,
            IsVerifiedPurchase = verification.IsVerified,
        };

        await _reviewRepository.CreateAsync(review, cancellationToken);
        await UpdateTargetRatingAsync(dto.TargetType, dto.TargetId, dto.Rating, cancellationToken);
        return review.ToDto();
    }

    public async Task<(IReadOnlyList<ReviewDto> Items, PaginationMetadata Pagination)> ListByTargetAsync(
        ReviewListRequest request,
        CancellationToken cancellationToken = default)
    {
        var pageNumber = Math.Max(1, request.PageNumber);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);
        var (items, total) = await _reviewRepository.GetByTargetPagedAsync(
            request.TargetType, request.TargetId, pageNumber, pageSize, cancellationToken);
        return (items.Select(r => r.ToDto()).ToList(), new PaginationMetadata(pageNumber, pageSize, total));
    }

    public async Task<(IReadOnlyList<ReviewDto> Items, PaginationMetadata Pagination)> ListForPartnerAsync(
        Guid ownerUserId,
        Guid partnerId,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        await PartnerService.RequireOwnedPartnerAsync(_partnerRepository, ownerUserId, partnerId, cancellationToken);
        pageNumber = Math.Max(1, pageNumber);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var menuItems = await _foodMenuItemRepository.GetByPartnerIdAsync(partnerId, null, cancellationToken);
        var affiliateProducts = await _affiliateProductRepository.GetByPartnerIdAsync(partnerId, cancellationToken);
        var (items, total) = await _reviewRepository.GetByPartnerScopedAsync(
            partnerId,
            menuItems.Select(x => x.Id).ToList(),
            affiliateProducts.Select(x => x.Id).ToList(),
            pageNumber,
            pageSize,
            cancellationToken);
        return (items.Select(r => r.ToDto()).ToList(), new PaginationMetadata(pageNumber, pageSize, total));
    }

    public async Task<ReviewDto> ReplyAsync(
        Guid ownerUserId,
        Guid partnerId,
        Guid reviewId,
        PartnerReplyDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Reply))
            throw new BadRequestException("Reply is required.");

        await PartnerService.RequireOwnedPartnerAsync(_partnerRepository, ownerUserId, partnerId, cancellationToken);
        var review = await _reviewRepository.GetByIdAsync(reviewId, cancellationToken);
        if (review == null)
            throw new NotFoundException(nameof(Review), reviewId);

        if (!await IsReviewOwnedByPartnerAsync(review, partnerId, cancellationToken))
            throw new ForbiddenException("This review does not belong to your partner profile.");

        review.PartnerReply = dto.Reply.Trim();
        await _reviewRepository.UpdateAsync(reviewId, review, cancellationToken);
        return review.ToDto();
    }

    private async Task EnsureTargetExistsAsync(
        ReviewTargetType targetType,
        Guid targetId,
        CancellationToken cancellationToken)
    {
        switch (targetType)
        {
            case ReviewTargetType.Partner:
                if (await _partnerRepository.GetByIdAsync(targetId, cancellationToken) == null)
                    throw new NotFoundException(nameof(Partner), targetId);
                break;
            case ReviewTargetType.FoodMenuItem:
                if (await _foodMenuItemRepository.GetByIdAsync(targetId, cancellationToken) == null)
                    throw new NotFoundException(nameof(FoodMenuItem), targetId);
                break;
            case ReviewTargetType.AffiliateProduct:
                if (await _affiliateProductRepository.GetByIdAsync(targetId, cancellationToken) == null)
                    throw new NotFoundException(nameof(AffiliateProduct), targetId);
                break;
            default:
                throw new BadRequestException("Invalid review target type.");
        }
    }

    private async Task UpdateTargetRatingAsync(
        ReviewTargetType targetType,
        Guid targetId,
        int rating,
        CancellationToken cancellationToken)
    {
        switch (targetType)
        {
            case ReviewTargetType.Partner:
            {
                var partner = await _partnerRepository.GetByIdAsync(targetId, cancellationToken);
                if (partner == null) return;
                var (avg, count) = RatingCalculator.AddRating(partner.RatingAverage, partner.RatingCount, rating);
                await _partnerRepository.UpdateRatingAsync(targetId, avg, count, cancellationToken);
                break;
            }
            case ReviewTargetType.FoodMenuItem:
            {
                var item = await _foodMenuItemRepository.GetByIdAsync(targetId, cancellationToken);
                if (item == null) return;
                var (avg, count) = RatingCalculator.AddRating(item.RatingAverage, item.RatingCount, rating);
                await _foodMenuItemRepository.UpdateRatingAsync(targetId, avg, count, cancellationToken);
                break;
            }
            case ReviewTargetType.AffiliateProduct:
            {
                var product = await _affiliateProductRepository.GetByIdAsync(targetId, cancellationToken);
                if (product == null) return;
                var (avg, count) = RatingCalculator.AddRating(product.RatingAverage, product.RatingCount, rating);
                await _affiliateProductRepository.UpdateRatingAsync(targetId, avg, count, cancellationToken);
                break;
            }
        }
    }

    private async Task<bool> IsReviewOwnedByPartnerAsync(
        Review review,
        Guid partnerId,
        CancellationToken cancellationToken)
    {
        return review.TargetType switch
        {
            ReviewTargetType.Partner => review.TargetId == partnerId,
            ReviewTargetType.FoodMenuItem => (await _foodMenuItemRepository.GetByIdAsync(review.TargetId, cancellationToken))?.PartnerId == partnerId,
            ReviewTargetType.AffiliateProduct => (await _affiliateProductRepository.GetByIdAsync(review.TargetId, cancellationToken))?.PartnerId == partnerId,
            _ => false,
        };
    }
}
