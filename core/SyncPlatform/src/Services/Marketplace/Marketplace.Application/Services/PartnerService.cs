using Libs.Shared.Enums;
using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Application.Exceptions;
using Marketplace.Application.Helpers;
using Marketplace.Application.Mappers;
using Marketplace.Domain.Common;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Helpers;
using Marketplace.Domain.Models;
using Marketplace.Domain.Repositories;

namespace Marketplace.Application.Services;

public class PartnerService : IPartnerService
{
    private readonly IPartnerRepository _partnerRepository;
    private readonly IFoodMenuItemRepository _foodMenuItemRepository;

    public PartnerService(IPartnerRepository partnerRepository, IFoodMenuItemRepository foodMenuItemRepository)
    {
        _partnerRepository = partnerRepository;
        _foodMenuItemRepository = foodMenuItemRepository;
    }

    public async Task<(IReadOnlyList<PartnerDto> Items, PaginationMetadata Pagination)> SearchAsync(
        PartnerSearchRequest request,
        CancellationToken cancellationToken = default)
    {
        var pageNumber = Math.Max(1, request.PageNumber);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var criteria = new PartnerSearchCriteria
        {
            Status = PartnerStatus.Active,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            RadiusKm = request.RadiusKm,
            PageNumber = pageNumber,
            PageSize = pageSize,
        };

        if (!string.IsNullOrWhiteSpace(request.Type)
            && Enum.TryParse<PartnerType>(request.Type, true, out var type))
        {
            criteria.Type = type;
        }

        var (items, total) = await _partnerRepository.SearchPagedAsync(criteria, cancellationToken);
        var dtos = items.Select(x => x.Partner.ToDto(x.DistanceKm)).ToList();
        return (dtos, new PaginationMetadata(pageNumber, pageSize, total));
    }

    public async Task<PartnerDetailDto> GetDetailAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var partner = await _partnerRepository.GetByIdAsync(id, cancellationToken);
        if (partner == null || partner.Status != PartnerStatus.Active)
            throw new NotFoundException(nameof(Partner), id);

        var menu = await _foodMenuItemRepository.GetByPartnerIdAsync(
            id, AvailabilityStatus.Available, cancellationToken);

        var dto = partner.ToDto();
        return new PartnerDetailDto
        {
            Id = dto.Id,
            OwnerUserId = dto.OwnerUserId,
            Name = dto.Name,
            Slug = dto.Slug,
            Type = dto.Type,
            Description = dto.Description,
            LogoUrl = dto.LogoUrl,
            CoverImageUrl = dto.CoverImageUrl,
            Email = dto.Email,
            PhoneNumber = dto.PhoneNumber,
            Address = dto.Address,
            Location = dto.Location,
            ServiceRadiusKm = dto.ServiceRadiusKm,
            OperatingHours = dto.OperatingHours,
            CommissionRate = dto.CommissionRate,
            Status = dto.Status,
            RatingAverage = dto.RatingAverage,
            RatingCount = dto.RatingCount,
            IsAiRecommendable = dto.IsAiRecommendable,
            DistanceKm = dto.DistanceKm,
            Menu = menu.Select(m => m.ToDto()).ToList(),
        };
    }

    public async Task<PartnerDto> GetMyPartnerAsync(Guid ownerUserId, CancellationToken cancellationToken = default)
    {
        var partner = await _partnerRepository.GetByOwnerUserIdAsync(ownerUserId, cancellationToken);
        if (partner == null)
            throw new NotFoundException(nameof(Partner), ownerUserId);
        return partner.ToDto();
    }

    public async Task<PartnerDto> RegisterAsync(
        Guid ownerUserId,
        RegisterPartnerDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
            throw new BadRequestException("Partner name is required.");
        if (string.IsNullOrWhiteSpace(dto.Email))
            throw new BadRequestException("Email is required.");

        var existing = await _partnerRepository.GetByOwnerUserIdAsync(ownerUserId, cancellationToken);
        if (existing != null)
            throw new ConflictException("You already have a registered partner profile.");

        var entity = new Partner
        {
            OwnerUserId = ownerUserId,
            Name = dto.Name.Trim(),
            Slug = SlugHelper.FromName(dto.Name),
            Type = dto.Type,
            Description = dto.Description?.Trim(),
            Email = dto.Email.Trim(),
            PhoneNumber = dto.PhoneNumber?.Trim(),
            Address = dto.Address?.Trim(),
            Location = GeoLocationMapping.ToGeoJsonPoint(dto.Location?.Latitude, dto.Location?.Longitude),
            ServiceRadiusKm = dto.ServiceRadiusKm,
            OperatingHours = MapOperatingHours(dto.OperatingHours),
            CommissionRate = dto.CommissionRate,
            Status = PartnerStatus.PendingApproval,
            IsAiRecommendable = false,
        };

        await _partnerRepository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<PartnerDto> UpdateAsync(
        Guid ownerUserId,
        Guid partnerId,
        UpdatePartnerDto dto,
        CancellationToken cancellationToken = default)
    {
        var partner = await RequireOwnedPartnerAsync(ownerUserId, partnerId, cancellationToken);

        if (!string.IsNullOrWhiteSpace(dto.Name))
        {
            partner.Name = dto.Name.Trim();
            partner.Slug = SlugHelper.FromName(dto.Name);
        }

        if (dto.Description != null)
            partner.Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim();
        if (dto.LogoUrl != null)
            partner.LogoUrl = dto.LogoUrl;
        if (dto.CoverImageUrl != null)
            partner.CoverImageUrl = dto.CoverImageUrl;
        if (dto.PhoneNumber != null)
            partner.PhoneNumber = dto.PhoneNumber;
        if (dto.Address != null)
            partner.Address = dto.Address;
        if (dto.Location != null)
            partner.Location = GeoLocationMapping.ToGeoJsonPoint(dto.Location.Latitude, dto.Location.Longitude);
        if (dto.ServiceRadiusKm.HasValue)
            partner.ServiceRadiusKm = dto.ServiceRadiusKm;
        if (dto.OperatingHours != null)
            partner.OperatingHours = MapOperatingHours(dto.OperatingHours);
        if (dto.IsAiRecommendable.HasValue)
            partner.IsAiRecommendable = dto.IsAiRecommendable.Value;

        await _partnerRepository.UpdateAsync(partnerId, partner, cancellationToken);
        return partner.ToDto();
    }

    public async Task<PartnerDto> UpdateStatusAsync(
        Guid partnerId,
        PartnerStatus status,
        CancellationToken cancellationToken = default)
    {
        var partner = await _partnerRepository.GetByIdAsync(partnerId, cancellationToken);
        if (partner == null)
            throw new NotFoundException(nameof(Partner), partnerId);

        await _partnerRepository.UpdateStatusAsync(partnerId, status, cancellationToken);
        partner.Status = status;
        return partner.ToDto();
    }

    internal static async Task<Partner> RequireOwnedPartnerAsync(
        IPartnerRepository repository,
        Guid ownerUserId,
        Guid partnerId,
        CancellationToken cancellationToken)
    {
        var partner = await repository.GetByIdAsync(partnerId, cancellationToken);
        if (partner == null)
            throw new NotFoundException(nameof(Partner), partnerId);
        if (partner.OwnerUserId != ownerUserId)
            throw new ForbiddenException("You do not own this partner profile.");
        return partner;
    }

    private async Task<Partner> RequireOwnedPartnerAsync(
        Guid ownerUserId,
        Guid partnerId,
        CancellationToken cancellationToken) =>
        await RequireOwnedPartnerAsync(_partnerRepository, ownerUserId, partnerId, cancellationToken);

    private static List<Partner.OperatingHour> MapOperatingHours(IReadOnlyList<OperatingHourDto>? hours) =>
        hours?.Select(h => new Partner.OperatingHour
        {
            DayOfWeek = h.DayOfWeek,
            OpenTime = h.OpenTime,
            CloseTime = h.CloseTime,
            IsClosed = h.IsClosed,
        }).ToList() ?? [];
}
