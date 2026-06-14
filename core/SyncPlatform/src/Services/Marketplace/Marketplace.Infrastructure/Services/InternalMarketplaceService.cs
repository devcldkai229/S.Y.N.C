using Marketplace.Application.DTOs;
using Marketplace.Application.Services;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Helpers;
using Marketplace.Domain.Repositories;

namespace Marketplace.Infrastructure.Services;

public class InternalMarketplaceService : IInternalMarketplaceService
{
    private readonly IPartnerRepository _partnerRepository;
    private readonly IFoodMenuItemRepository _foodMenuItemRepository;

    public InternalMarketplaceService(
        IPartnerRepository partnerRepository,
        IFoodMenuItemRepository foodMenuItemRepository)
    {
        _partnerRepository = partnerRepository;
        _foodMenuItemRepository = foodMenuItemRepository;
    }

    public async Task<ValidateOrderItemsResultDto> ValidateOrderItemsAsync(
        ValidateOrderItemsRequestDto request,
        CancellationToken cancellationToken = default)
    {
        var partner = await _partnerRepository.GetByIdAsync(request.PartnerId, cancellationToken);
        if (partner == null || partner.Status != PartnerStatus.Active)
        {
            return new ValidateOrderItemsResultDto
            {
                IsValid = false,
                ErrorMessage = "Partner is not active.",
            };
        }

        if (request.FoodMenuItemIds.Count == 0)
        {
            return new ValidateOrderItemsResultDto
            {
                IsValid = false,
                ErrorMessage = "No menu items provided.",
            };
        }

        var items = new List<ValidatedMenuItemDto>();
        foreach (var itemId in request.FoodMenuItemIds.Distinct())
        {
            var menu = await _foodMenuItemRepository.GetByIdAsync(itemId, cancellationToken);
            if (menu == null || menu.PartnerId != request.PartnerId)
            {
                return new ValidateOrderItemsResultDto
                {
                    IsValid = false,
                    ErrorMessage = $"Food menu item {itemId} is invalid for this partner.",
                };
            }

            if (menu.Availability != AvailabilityStatus.Available)
            {
                return new ValidateOrderItemsResultDto
                {
                    IsValid = false,
                    ErrorMessage = $"Food menu item {menu.NameVi} is not available.",
                };
            }

            items.Add(new ValidatedMenuItemDto
            {
                FoodMenuItemId = menu.Id,
                PartnerId = menu.PartnerId,
                NameVi = menu.NameVi,
                ImageUrl = menu.ImageUrls.FirstOrDefault(),
                Price = menu.Price,
                Currency = menu.Currency,
                Calories = menu.Nutrition.Calories,
                ProteinGram = menu.Nutrition.ProteinGram,
                CarbGram = menu.Nutrition.CarbGram,
                FatGram = menu.Nutrition.FatGram,
                IsAvailable = true,
            });
        }

        return new ValidateOrderItemsResultDto
        {
            IsValid = true,
            PartnerCommissionRate = partner.CommissionRate,
            Items = items,
        };
    }

    public async Task<PartnerInternalDto?> GetPartnerInternalAsync(
        Guid partnerId,
        CancellationToken cancellationToken = default)
    {
        var partner = await _partnerRepository.GetByIdAsync(partnerId, cancellationToken);
        if (partner == null)
            return null;

        var coords = GeoLocationMapping.FromGeoJsonPoint(partner.Location);
        return new PartnerInternalDto
        {
            Id = partner.Id,
            OwnerUserId = partner.OwnerUserId,
            Name = partner.Name,
            Status = partner.Status.ToString(),
            CommissionRate = partner.CommissionRate,
            Address = partner.Address,
            Latitude = coords?.Latitude,
            Longitude = coords?.Longitude,
        };
    }
}
