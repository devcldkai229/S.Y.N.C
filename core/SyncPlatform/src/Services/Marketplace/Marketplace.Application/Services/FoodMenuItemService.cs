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

public class FoodMenuItemService : IFoodMenuItemService
{
    private readonly IFoodMenuItemRepository _repository;
    private readonly IPartnerRepository _partnerRepository;

    public FoodMenuItemService(IFoodMenuItemRepository repository, IPartnerRepository partnerRepository)
    {
        _repository = repository;
        _partnerRepository = partnerRepository;
    }

    public async Task<(IReadOnlyList<FoodMenuItemDto> Items, PaginationMetadata Pagination)> SearchAsync(
        FoodMenuItemSearchRequest request,
        CancellationToken cancellationToken = default)
    {
        var pageNumber = Math.Max(1, request.PageNumber);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var criteria = new FoodMenuItemSearchCriteria
        {
            Query = request.Query,
            MinPrice = request.MinPrice,
            MaxPrice = request.MaxPrice,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            RadiusKm = request.RadiusKm,
            PageNumber = pageNumber,
            PageSize = pageSize,
        };

        if (!string.IsNullOrWhiteSpace(request.Category)
            && Enum.TryParse<FoodCategory>(request.Category, true, out var category))
        {
            criteria.Category = category;
        }

        if (request.DietaryTags is { Count: > 0 })
        {
            var tags = ParseDietaryTags(request.DietaryTags);
            if (tags.Count > 0)
                criteria.DietaryTags = tags;
        }

        if (request.Latitude is not null && request.Longitude is not null && request.RadiusKm is > 0)
        {
            var partnerCriteria = new PartnerSearchCriteria
            {
                Status = PartnerStatus.Active,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                RadiusKm = request.RadiusKm,
                PageNumber = 1,
                PageSize = 500,
            };
            var (nearby, _) = await _partnerRepository.SearchPagedAsync(partnerCriteria, cancellationToken);
            criteria.PartnerIds = nearby.Select(x => x.Partner.Id).ToList();
            if (criteria.PartnerIds.Count == 0)
                return ([], new PaginationMetadata(pageNumber, pageSize, 0));
        }

        var (items, total) = await _repository.SearchPagedAsync(criteria, cancellationToken);
        return (items.Select(i => i.ToDto()).ToList(), new PaginationMetadata(pageNumber, pageSize, total));
    }

    public async Task<FoodMenuItemDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken);
        if (entity == null || entity.Availability == AvailabilityStatus.Hidden)
            throw new NotFoundException(nameof(FoodMenuItem), id);
        return entity.ToDto();
    }

    public async Task<IReadOnlyList<FoodMenuItemDto>> GetByPartnerAsync(
        Guid partnerId,
        CancellationToken cancellationToken = default)
    {
        var items = await _repository.GetByPartnerIdAsync(partnerId, null, cancellationToken);
        return items.Select(i => i.ToDto()).ToList();
    }

    public async Task<FoodMenuItemDto> CreateAsync(
        Guid ownerUserId,
        Guid partnerId,
        CreateFoodMenuItemDto dto,
        CancellationToken cancellationToken = default)
    {
        await PartnerService.RequireOwnedPartnerAsync(_partnerRepository, ownerUserId, partnerId, cancellationToken);
        ValidateMenuItem(dto.NameVi, dto.NameEn, dto.Price);

        var name = !string.IsNullOrWhiteSpace(dto.NameVi) ? dto.NameVi : dto.NameEn;
        var entity = new FoodMenuItem
        {
            PartnerId = partnerId,
            NameVi = dto.NameVi.Trim(),
            NameEn = string.IsNullOrWhiteSpace(dto.NameEn) ? dto.NameVi.Trim() : dto.NameEn.Trim(),
            Slug = SlugHelper.FromName(name),
            Description = dto.Description.Trim(),
            ImageUrls = dto.ImageUrls ?? [],
            Category = dto.Category,
            Price = dto.Price,
            Currency = dto.Currency,
            PrepTimeMinutes = dto.PrepTimeMinutes,
            Nutrition = dto.Nutrition.ToValueObject(),
            DietaryTags = dto.DietaryTags ?? [],
            SpiceLevel = dto.SpiceLevel,
            Availability = dto.Availability,
            IsAiRecommended = dto.IsAiRecommended,
        };

        await _repository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<FoodMenuItemDto> UpdateAsync(
        Guid ownerUserId,
        Guid partnerId,
        Guid itemId,
        UpdateFoodMenuItemDto dto,
        CancellationToken cancellationToken = default)
    {
        await PartnerService.RequireOwnedPartnerAsync(_partnerRepository, ownerUserId, partnerId, cancellationToken);
        var entity = await RequirePartnerMenuItemAsync(partnerId, itemId, cancellationToken);

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
        if (dto.PrepTimeMinutes.HasValue)
            entity.PrepTimeMinutes = dto.PrepTimeMinutes.Value;
        if (dto.Nutrition != null)
            entity.Nutrition = dto.Nutrition.ToValueObject();
        if (dto.DietaryTags != null)
            entity.DietaryTags = dto.DietaryTags;
        if (dto.SpiceLevel.HasValue)
            entity.SpiceLevel = dto.SpiceLevel.Value;
        if (dto.Availability.HasValue)
            entity.Availability = dto.Availability.Value;
        if (dto.IsAiRecommended.HasValue)
            entity.IsAiRecommended = dto.IsAiRecommended.Value;

        await _repository.UpdateAsync(itemId, entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task SoftDeleteAsync(
        Guid ownerUserId,
        Guid partnerId,
        Guid itemId,
        CancellationToken cancellationToken = default)
    {
        await PartnerService.RequireOwnedPartnerAsync(_partnerRepository, ownerUserId, partnerId, cancellationToken);
        var entity = await RequirePartnerMenuItemAsync(partnerId, itemId, cancellationToken);
        entity.Availability = AvailabilityStatus.Hidden;
        await _repository.UpdateAsync(itemId, entity, cancellationToken);
    }

    private async Task<FoodMenuItem> RequirePartnerMenuItemAsync(
        Guid partnerId,
        Guid itemId,
        CancellationToken cancellationToken)
    {
        var entity = await _repository.GetByIdAsync(itemId, cancellationToken);
        if (entity == null || entity.PartnerId != partnerId)
            throw new NotFoundException(nameof(FoodMenuItem), itemId);
        return entity;
    }

    private static void ValidateMenuItem(string nameVi, string nameEn, decimal price)
    {
        if (string.IsNullOrWhiteSpace(nameVi) && string.IsNullOrWhiteSpace(nameEn))
            throw new BadRequestException("NameVi or NameEn is required.");
        if (price < 0)
            throw new BadRequestException("Price must be non-negative.");
    }

    private static List<DietaryTag> ParseDietaryTags(IEnumerable<string> tags)
    {
        var result = new List<DietaryTag>();
        foreach (var tag in tags)
        {
            if (Enum.TryParse<DietaryTag>(tag, true, out var parsed))
                result.Add(parsed);
        }

        return result;
    }
}
