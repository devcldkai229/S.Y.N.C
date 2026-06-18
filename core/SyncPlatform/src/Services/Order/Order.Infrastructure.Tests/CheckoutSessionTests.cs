using Microsoft.Extensions.Options;
using Moq;
using Order.Application.Clients;
using Order.Application.DTOs;
using Order.Application.Exceptions;
using Order.Application.Ports;
using Order.Infrastructure.Options;
using Order.Infrastructure.Services;
using Order.Infrastructure.Tests.TestDoubles;
using Xunit;

namespace Order.Infrastructure.Tests;

public class CheckoutSessionTests
{
    private static CheckoutSessionService CreateService(
        ICartStore cartStore,
        Mock<IMarketplaceClient>? marketplace = null)
    {
        marketplace ??= new Mock<IMarketplaceClient>();
        return new CheckoutSessionService(
            new Mock<IPlaceIndexClient>().Object,
            new Mock<IPlaceSearchCache>().Object,
            new Mock<IDeliveryAddressStore>().Object,
            cartStore,
            marketplace.Object,
            Microsoft.Extensions.Options.Options.Create(new OrderSettings { DefaultDeliveryFee = 25000m }));
    }

    [Fact]
    public async Task GetCheckoutFees_ReturnsConfiguredDefaultDeliveryFee()
    {
        var service = CreateService(new InMemoryCartStore());
        var fees = await service.GetCheckoutFeesAsync();
        Assert.Equal(25000m, fees.DefaultDeliveryFee);
        Assert.Equal("VND", fees.Currency);
    }

    [Fact]
    public async Task GetCart_IncludesDeliveryFeeFromSettings()
    {
        var userId = Guid.NewGuid();
        var cartStore = new InMemoryCartStore();
        await cartStore.SaveAsync(userId, new CartDto { Subtotal = 50000m });

        var service = CreateService(cartStore);
        var cart = await service.GetCartAsync(userId);

        Assert.Equal(25000m, cart.DeliveryFee);
    }

    [Fact]
    public async Task AddCartItem_DifferentPartner_ThrowsConflictWithRequiresClear()
    {
        var partnerA = Guid.NewGuid();
        var partnerB = Guid.NewGuid();
        var itemA = Guid.NewGuid();
        var itemB = Guid.NewGuid();
        var userId = Guid.NewGuid();
        var cartStore = new InMemoryCartStore();

        await cartStore.SaveAsync(userId, new CartDto
        {
            PartnerId = partnerA,
            PartnerName = "Bếp A",
            Subtotal = 50000m,
            Items =
            [
                new CartItemDto
                {
                    FoodMenuItemId = itemA,
                    NameSnapshot = "Món A",
                    UnitPrice = 50000m,
                    Quantity = 1,
                },
            ],
        });

        var marketplace = new Mock<IMarketplaceClient>();
        marketplace.Setup(m => m.ValidateOrderItemsAsync(
                It.Is<ValidateOrderItemsRequest>(r => r.PartnerId == partnerB),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ValidateOrderItemsResult
            {
                IsValid = true,
                Items =
                [
                    new ValidatedMenuItem
                    {
                        FoodMenuItemId = itemB,
                        PartnerId = partnerB,
                        NameVi = "Món B",
                        Price = 60000m,
                        IsAvailable = true,
                    },
                ],
            });

        var service = CreateService(cartStore, marketplace);

        var ex = await Assert.ThrowsAsync<ConflictException>(() =>
            service.AddCartItemAsync(userId, new AddCartItemDto
            {
                PartnerId = partnerB,
                FoodMenuItemId = itemB,
                Quantity = 1,
            }));

        Assert.Contains("requiresClear", ex.Details?.ToString() ?? string.Empty, StringComparison.OrdinalIgnoreCase);
        Assert.True(cartStore.HasCart(userId));
    }
}
