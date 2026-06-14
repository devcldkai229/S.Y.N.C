using Order.Application.DTOs;

namespace Order.Application.Services;

public interface ICheckoutSessionService
{
    Task<IReadOnlyList<AddressSuggestionDto>> SearchAddressAsync(
        string query,
        double? lat,
        double? lng,
        CancellationToken cancellationToken = default);

    Task<ReverseGeocodeResultDto> ReverseGeocodeAsync(
        double lat,
        double lng,
        CancellationToken cancellationToken = default);

    Task SaveDeliveryAddressAsync(
        Guid userId,
        SaveDeliveryAddressDto dto,
        CancellationToken cancellationToken = default);

    Task<DeliveryAddressDto?> GetDeliveryAddressAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<CheckoutFeesDto> GetCheckoutFeesAsync(CancellationToken cancellationToken = default);

    Task<CartDto> GetCartAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<CartDto> AddCartItemAsync(
        Guid userId,
        AddCartItemDto dto,
        CancellationToken cancellationToken = default);

    Task<CartDto> UpdateCartItemQuantityAsync(
        Guid userId,
        Guid foodMenuItemId,
        int quantity,
        CancellationToken cancellationToken = default);

    Task DeleteCartAsync(Guid userId, CancellationToken cancellationToken = default);
}
