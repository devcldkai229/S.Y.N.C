using Libs.Shared.Enums;
using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Exceptions;
using Marketplace.Application.Helpers;
using Marketplace.Application.Mappers;
using Marketplace.Domain.Common;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Models;
using Marketplace.Domain.Repositories;

namespace Marketplace.Application.Services;

public class AffiliateProductService : IAffiliateProductService
{
    private readonly IAffiliateProductRepository _repository;
    private readonly IPartnerRepository _partnerRepository;

    public AffiliateProductService(IAffiliateProductRepository repository, IPartnerRepository partnerRepository)
    {
        _repository = repository;
        _partnerRepository = partnerRepository;
    }

    public async Task<(IReadOnlyList<AffiliateProductDto> Items, PaginationMetadata Pagination)> SearchAsync(
        AffiliateProductSearchRequest request,
        CancellationToken cancellationToken = default)
    {
        var pageNumber = Math.Max(1, request.PageNumber);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var criteria = new AffiliateProductSearchCriteria
        {
            PageNumber = pageNumber,
            PageSize = pageSize,
        };

        if (!string.IsNullOrWhiteSpace(request.Category)
            && Enum.TryParse<AffiliateCategory>(request.Category, true, out var category))
        {
            criteria.Category = category;
        }

        if (request.DietaryTags is { Count: > 0 })
        {
            var tags = new List<DietaryTag>();
            foreach (var tag in request.DietaryTags)
            {
                if (Enum.TryParse<DietaryTag>(tag, true, out var parsed))
                    tags.Add(parsed);
            }

            if (tags.Count > 0)
                criteria.DietaryTags = tags;
        }

        var (items, total) = await _repository.SearchPagedAsync(criteria, cancellationToken);
        return (items.Select(i => i.ToDto()).ToList(), new PaginationMetadata(pageNumber, pageSize, total));
    }

    public async Task<AffiliateProductDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken);
        if (entity == null || entity.Availability == AvailabilityStatus.Hidden)
            throw new NotFoundException(nameof(AffiliateProduct), id);
        return entity.ToDto();
    }

    public async Task<IReadOnlyList<AffiliateProductDto>> GetByPartnerAsync(
        Guid partnerId,
        CancellationToken cancellationToken = default)
    {
        var items = await _repository.GetByPartnerIdAsync(partnerId, cancellationToken);
        return items.Select(i => i.ToDto()).ToList();
    }

    public async Task<AffiliateProductDto> CreateAsync(
        Guid ownerUserId,
        Guid partnerId,
        CreateAffiliateProductDto dto,
        CancellationToken cancellationToken = default)
    {
        var partner = await PartnerService.RequireOwnedPartnerAsync(
            _partnerRepository, ownerUserId, partnerId, cancellationToken);
        if (partner.Type != PartnerType.AffiliateBrand)
            throw new BadRequestException("Only affiliate brand partners can manage affiliate products.");

        ValidateProduct(dto.NameVi, dto.NameEn, dto.AffiliateUrl, dto.Price);
        var name = !string.IsNullOrWhiteSpace(dto.NameVi) ? dto.NameVi : dto.NameEn;

        var entity = new AffiliateProduct
        {
            PartnerId = partnerId,
            BrandName = string.IsNullOrWhiteSpace(dto.BrandName) ? partner.Name : dto.BrandName.Trim(),
            NameVi = dto.NameVi.Trim(),
            NameEn = string.IsNullOrWhiteSpace(dto.NameEn) ? dto.NameVi.Trim() : dto.NameEn.Trim(),
            Slug = SlugHelper.FromName(name),
            Description = dto.Description.Trim(),
            ImageUrls = dto.ImageUrls ?? [],
            Category = dto.Category,
            Price = dto.Price,
            Currency = dto.Currency,
            AffiliateUrl = dto.AffiliateUrl.Trim(),
            ExternalProductId = dto.ExternalProductId?.Trim(),
            CommissionRate = dto.CommissionRate,
            Nutrition = dto.Nutrition?.ToValueObject(),
            DietaryTags = dto.DietaryTags,
            Availability = dto.Availability,
        };

        await _repository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<AffiliateProductDto> UpdateAsync(
        Guid ownerUserId,
        Guid partnerId,
        Guid productId,
        UpdateAffiliateProductDto dto,
        CancellationToken cancellationToken = default)
    {
        await PartnerService.RequireOwnedPartnerAsync(_partnerRepository, ownerUserId, partnerId, cancellationToken);
        var entity = await RequirePartnerProductAsync(partnerId, productId, cancellationToken);

        if (!string.IsNullOrWhiteSpace(dto.BrandName))
            entity.BrandName = dto.BrandName.Trim();
        if (!string.IsNullOrWhiteSpace(dto.NameVi))
            entity.NameVi = dto.NameVi.Trim();
        if (!string.IsNullOrWhiteSpace(dto.NameEn))
            entity.NameEn = dto.NameEn.Trim();
        if (!string.IsNullOrWhiteSpace(dto.NameVi) || !string.IsNullOrWhiteSpace(dto.NameEn))
            entity.Slug = SlugHelper.FromName(!string.IsNullOrWhiteSpace(entity.NameVi) ? entity.NameVi : entity.NameEn);
        if (dto.Description != null)
            entity.Description = dto.Description;
        if (dto.ImageUrls != null)
            entity.ImageUrls = dto.ImageUrls;
        if (dto.Category.HasValue)
            entity.Category = dto.Category.Value;
        if (dto.Price.HasValue)
            entity.Price = dto.Price.Value;
        if (dto.Currency != null)
            entity.Currency = dto.Currency;
        if (dto.AffiliateUrl != null)
            entity.AffiliateUrl = dto.AffiliateUrl.Trim();
        if (dto.ExternalProductId != null)
            entity.ExternalProductId = dto.ExternalProductId;
        if (dto.CommissionRate.HasValue)
            entity.CommissionRate = dto.CommissionRate.Value;
        if (dto.Nutrition != null)
            entity.Nutrition = dto.Nutrition.ToValueObject();
        if (dto.DietaryTags != null)
            entity.DietaryTags = dto.DietaryTags;
        if (dto.Availability.HasValue)
            entity.Availability = dto.Availability.Value;

        await _repository.UpdateAsync(productId, entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task SoftDeleteAsync(
        Guid ownerUserId,
        Guid partnerId,
        Guid productId,
        CancellationToken cancellationToken = default)
    {
        await PartnerService.RequireOwnedPartnerAsync(_partnerRepository, ownerUserId, partnerId, cancellationToken);
        var entity = await RequirePartnerProductAsync(partnerId, productId, cancellationToken);
        entity.Availability = AvailabilityStatus.Hidden;
        await _repository.UpdateAsync(productId, entity, cancellationToken);
    }

    private async Task<AffiliateProduct> RequirePartnerProductAsync(
        Guid partnerId,
        Guid productId,
        CancellationToken cancellationToken)
    {
        var entity = await _repository.GetByIdAsync(productId, cancellationToken);
        if (entity == null || entity.PartnerId != partnerId)
            throw new NotFoundException(nameof(AffiliateProduct), productId);
        return entity;
    }

    private static void ValidateProduct(string nameVi, string nameEn, string affiliateUrl, decimal price)
    {
        if (string.IsNullOrWhiteSpace(nameVi) && string.IsNullOrWhiteSpace(nameEn))
            throw new BadRequestException("NameVi or NameEn is required.");
        if (string.IsNullOrWhiteSpace(affiliateUrl))
            throw new BadRequestException("AffiliateUrl is required.");
        if (price < 0)
            throw new BadRequestException("Price must be non-negative.");
    }
}
