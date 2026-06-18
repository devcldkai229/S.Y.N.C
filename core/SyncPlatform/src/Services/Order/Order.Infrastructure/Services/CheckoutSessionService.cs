using Microsoft.Extensions.Options;
using Order.Application.Clients;
using Order.Application.DTOs;
using Order.Application.Exceptions;
using Order.Application.Ports;
using Order.Application.Services;
using Order.Infrastructure.Options;

namespace Order.Infrastructure.Services;

public class CheckoutSessionService : ICheckoutSessionService
{
    private static readonly TimeSpan SearchCacheTtl = TimeSpan.FromMinutes(10);

    private readonly IPlaceIndexClient _placeIndex;
    private readonly IPlaceSearchCache _searchCache;
    private readonly IDeliveryAddressStore _addressStore;
    private readonly ICartStore _cartStore;
    private readonly IMarketplaceClient _marketplaceClient;
    private readonly OrderSettings _settings;

    public CheckoutSessionService(
        IPlaceIndexClient placeIndex,
        IPlaceSearchCache searchCache,
        IDeliveryAddressStore addressStore,
        ICartStore cartStore,
        IMarketplaceClient marketplaceClient,
        IOptions<OrderSettings> settings)
    {
        _placeIndex = placeIndex;
        _searchCache = searchCache;
        _addressStore = addressStore;
        _cartStore = cartStore;
        _marketplaceClient = marketplaceClient;
        _settings = settings.Value;
    }

    public Task<CheckoutFeesDto> GetCheckoutFeesAsync(CancellationToken cancellationToken = default) =>
        Task.FromResult(new CheckoutFeesDto
        {
            DefaultDeliveryFee = _settings.DefaultDeliveryFee,
            Currency = "VND",
        });

    public async Task<IReadOnlyList<AddressSuggestionDto>> SearchAddressAsync(
        string query,
        double? lat,
        double? lng,
        CancellationToken cancellationToken = default)
    {
        var normalized = query.Trim().ToLowerInvariant();
        if (normalized.Length < 2)
            return [];

        var cacheKey = $"{normalized}|{lat:F3}|{lng:F3}";
        var cached = await _searchCache.GetSearchAsync(cacheKey, cancellationToken);
        if (cached != null)
            return cached;

        var results = await _placeIndex.SearchAsync(query, lat, lng, cancellationToken);
        await _searchCache.SetSearchAsync(cacheKey, results, SearchCacheTtl, cancellationToken);
        return results;
    }

    public Task<ReverseGeocodeResultDto> ReverseGeocodeAsync(
        double lat,
        double lng,
        CancellationToken cancellationToken = default) =>
        _placeIndex.ReverseAsync(lat, lng, cancellationToken);

    public async Task SaveDeliveryAddressAsync(
        Guid userId,
        SaveDeliveryAddressDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Label))
            throw new BadRequestException("Address label is required.");

        await _addressStore.SaveAsync(userId, new DeliveryAddressDto
        {
            Label = dto.Label.Trim(),
            Lat = dto.Lat,
            Lng = dto.Lng,
            SavedAt = DateTimeOffset.UtcNow,
        }, cancellationToken);
    }

    public Task<DeliveryAddressDto?> GetDeliveryAddressAsync(
        Guid userId,
        CancellationToken cancellationToken = default) =>
        _addressStore.GetAsync(userId, cancellationToken);

    public async Task<CartDto> GetCartAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var cart = await _cartStore.GetAsync(userId, cancellationToken);
        return WithDeliveryFee(cart ?? new CartDto());
    }

    public async Task<CartDto> AddCartItemAsync(
        Guid userId,
        AddCartItemDto dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.Quantity <= 0)
            throw new BadRequestException("Quantity must be greater than zero.");

        var validation = await _marketplaceClient.ValidateOrderItemsAsync(new ValidateOrderItemsRequest
        {
            PartnerId = dto.PartnerId,
            FoodMenuItemIds = [dto.FoodMenuItemId],
        }, cancellationToken);

        if (!validation.IsValid)
            throw new BadRequestException(validation.ErrorMessage ?? "Food item is not available.");

        var menu = validation.Items.FirstOrDefault(i => i.FoodMenuItemId == dto.FoodMenuItemId)
            ?? throw new BadRequestException("Food item is not available.");

        if (!menu.IsAvailable)
            throw new BadRequestException("Food item is not available.");

        var cart = await _cartStore.GetAsync(userId, cancellationToken) ?? new CartDto();

        if (cart.Items.Count > 0 && cart.PartnerId.HasValue && cart.PartnerId != dto.PartnerId)
        {
            throw new ConflictException(
                "Cart contains items from another kitchen.",
                new { requiresClear = true });
        }

        var partner = await _marketplaceClient.GetPartnerAsync(dto.PartnerId, cancellationToken);
        cart.PartnerId = dto.PartnerId;
        cart.PartnerName = partner?.Name ?? cart.PartnerName ?? "Kitchen";

        var existing = cart.Items.FirstOrDefault(i => i.FoodMenuItemId == dto.FoodMenuItemId);
        if (existing != null)
        {
            existing.Quantity += dto.Quantity;
            if (!string.IsNullOrWhiteSpace(dto.Notes))
                existing.Notes = dto.Notes;
            existing.UnitPrice = menu.Price;
            existing.NameSnapshot = menu.NameVi;
            existing.ImageUrlSnapshot = menu.ImageUrl;
        }
        else
        {
            cart.Items.Add(new CartItemDto
            {
                FoodMenuItemId = dto.FoodMenuItemId,
                NameSnapshot = menu.NameVi,
                ImageUrlSnapshot = menu.ImageUrl,
                UnitPrice = menu.Price,
                Quantity = dto.Quantity,
                Notes = dto.Notes,
            });
        }

        cart.Subtotal = cart.Items.Sum(i => i.UnitPrice * i.Quantity);
        await _cartStore.SaveAsync(userId, cart, cancellationToken);
        return WithDeliveryFee(cart);
    }

    public async Task<CartDto> UpdateCartItemQuantityAsync(
        Guid userId,
        Guid foodMenuItemId,
        int quantity,
        CancellationToken cancellationToken = default)
    {
        var cart = await _cartStore.GetAsync(userId, cancellationToken);
        if (cart == null || cart.Items.Count == 0)
            return WithDeliveryFee(new CartDto());

        if (quantity <= 0)
        {
            cart.Items.RemoveAll(i => i.FoodMenuItemId == foodMenuItemId);
        }
        else
        {
            var item = cart.Items.FirstOrDefault(i => i.FoodMenuItemId == foodMenuItemId);
            if (item == null)
                throw new NotFoundException("Cart item", foodMenuItemId);

            item.Quantity = quantity;
        }

        if (cart.Items.Count == 0)
        {
            await _cartStore.DeleteAsync(userId, cancellationToken);
            return WithDeliveryFee(new CartDto());
        }

        cart.Subtotal = cart.Items.Sum(i => i.UnitPrice * i.Quantity);
        await _cartStore.SaveAsync(userId, cart, cancellationToken);
        return WithDeliveryFee(cart);
    }

    public Task DeleteCartAsync(Guid userId, CancellationToken cancellationToken = default) =>
        _cartStore.DeleteAsync(userId, cancellationToken);

    private CartDto WithDeliveryFee(CartDto cart)
    {
        cart.DeliveryFee = _settings.DefaultDeliveryFee;
        return cart;
    }
}
