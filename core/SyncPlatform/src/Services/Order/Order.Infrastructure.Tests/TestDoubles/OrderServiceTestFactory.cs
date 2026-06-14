using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using OptionsFactory = Microsoft.Extensions.Options.Options;
using Moq;
using Order.Application.Clients;
using Order.Application.DTOs;
using Order.Application.Ports;
using Order.Application.Services;
using Order.Domain.Enums;
using Order.Infrastructure.Options;
using Order.Infrastructure.Persistence;
using Order.Infrastructure.Services;

namespace Order.Infrastructure.Tests.TestDoubles;

internal sealed class OrderServiceTestFactory : IDisposable
{
    public Guid UserId { get; } = Guid.NewGuid();
    public Guid PartnerId { get; } = Guid.NewGuid();
    public Guid FoodMenuItemId { get; } = Guid.NewGuid();
    public decimal ItemPrice { get; } = 85000m;

    public InMemoryCartStore CartStore { get; } = new();
    public Mock<IPaymentClient> Payment { get; } = new();
    public Mock<INotificationClient> Notification { get; } = new();
    public Mock<IMarketplaceClient> Marketplace { get; } = new();
    public Mock<INutritionEventClient> Nutrition { get; } = new();
    public Mock<ICommissionService> Commission { get; } = new();
    public Mock<IDeliveryTrackingService> DeliveryTracking { get; } = new();
    public Mock<IDeliveryAddressStore> AddressStore { get; } = new();

    public OrderDbContext Db { get; }
    public OrderService Service { get; }

    public OrderServiceTestFactory()
    {
        var options = new DbContextOptionsBuilder<OrderDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        Db = new OrderDbContext(options);

        Marketplace.Setup(m => m.ValidateOrderItemsAsync(It.IsAny<ValidateOrderItemsRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ValidateOrderItemsResult
            {
                IsValid = true,
                Items =
                [
                    new ValidatedMenuItem
                    {
                        FoodMenuItemId = FoodMenuItemId,
                        PartnerId = PartnerId,
                        NameVi = "Phở bò",
                        Price = ItemPrice,
                        IsAvailable = true,
                    },
                ],
            });

        Notification.Setup(n => n.SendOrderStatusAsync(
                It.IsAny<Guid>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        Payment.Setup(p => p.MarkVoucherUsedAsync(It.IsAny<MarkVoucherUsedRequest>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        Service = new OrderService(
            Db,
            Marketplace.Object,
            Payment.Object,
            Notification.Object,
            Nutrition.Object,
            Commission.Object,
            DeliveryTracking.Object,
            CartStore,
            AddressStore.Object,
            OptionsFactory.Create(new OrderSettings { DefaultDeliveryFee = 25000m }),
            NullLogger<OrderService>.Instance);
    }

    public async Task SeedCartAsync()
    {
        await CartStore.SaveAsync(UserId, new CartDto
        {
            PartnerId = PartnerId,
            PartnerName = "Bếp demo",
            Subtotal = ItemPrice,
            Items =
            [
                new CartItemDto
                {
                    FoodMenuItemId = FoodMenuItemId,
                    NameSnapshot = "Phở bò",
                    UnitPrice = ItemPrice,
                    Quantity = 1,
                },
            ],
        });
    }

    public PlaceOrderDto BasePlaceOrderDto(CheckoutPaymentMethod method) => new()
    {
        PartnerId = PartnerId,
        PaymentMethod = method,
        DeliveryAddress = "123 Nguyễn Huệ, Q1",
        DeliveryLat = 10.7769m,
        DeliveryLng = 106.7009m,
        RecipientName = "Tester",
        RecipientPhone = "0900000000",
        IdempotencyKey = Guid.NewGuid().ToString("N"),
    };

    public void Dispose() => Db.Dispose();
}
