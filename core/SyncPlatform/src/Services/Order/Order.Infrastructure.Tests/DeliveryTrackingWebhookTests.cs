using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Moq;
using Order.Application.Clients;
using Order.Application.Ports;
using Order.Application.Services;
using Order.Domain.Enums;
using Order.Domain.Models;
using Order.Infrastructure.Options;
using Order.Infrastructure.Persistence;
using Order.Infrastructure.Services;
using Xunit;

namespace Order.Infrastructure.Tests;

public class DeliveryTrackingWebhookTests
{
    [Fact]
    public async Task ProcessWebhook_StatusChange_UpdatesOrder_Notifies_ReplayIsIdempotent()
    {
        var userId = Guid.NewGuid();
        var orderId = Guid.NewGuid();
        const string externalId = "ahm-ext-001";
        const string eventId = "evt-duplicate-test";

        var options = new DbContextOptionsBuilder<OrderDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        await using var db = new OrderDbContext(options);

        db.Orders.Add(new Order.Domain.Models.Order
        {
            Id = orderId,
            UserId = userId,
            PartnerId = Guid.NewGuid(),
            OrderCode = "ORD001",
            Status = OrderStatus.ReadyForPickup,
            SubtotalAmount = 85000m,
            DeliveryFee = 25000m,
            DiscountAmount = 0,
            TotalAmount = 110000m,
            Currency = "VND",
            PaymentStatus = PaymentStatus.Paid,
            PlacedAt = DateTimeOffset.UtcNow,
        });
        db.DeliveryTrackings.Add(new DeliveryTracking
        {
            OrderId = orderId,
            Provider = "Ahamove",
            ExternalDeliveryId = externalId,
            Status = DeliveryStatus.Assigned,
        });
        await db.SaveChangesAsync();

        var deliveryProvider = new Mock<IDeliveryProvider>();
        deliveryProvider.Setup(p => p.ProviderName).Returns("Ahamove");

        var notification = new Mock<INotificationClient>();
        notification.Setup(n => n.SendOrderStatusAsync(
                It.IsAny<Guid>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var service = new DeliveryTrackingService(
            db,
            new Mock<IMarketplaceClient>().Object,
            deliveryProvider.Object,
            new Mock<ITrackingLocationStore>().Object,
            new Mock<ITrackingRealtimePublisher>().Object,
            notification.Object,
            new Mock<ICommissionService>().Object,
            new Mock<INutritionEventClient>().Object,
            Microsoft.Extensions.Options.Options.Create(new OrderSettings()),
            NullLogger<DeliveryTrackingService>.Instance);

        var payload = new DeliveryWebhookPayload
        {
            EventId = eventId,
            EventType = "ORDER_CALLBACK",
            ExternalDeliveryId = externalId,
            Status = "IN PROCESS",
        };

        await service.ProcessWebhookAsync(payload, "{}", CancellationToken.None);
        await service.ProcessWebhookAsync(payload, "{}", CancellationToken.None);

        var order = await db.Orders.AsNoTracking().SingleAsync(x => x.Id == orderId);
        var tracking = await db.DeliveryTrackings.AsNoTracking().SingleAsync(x => x.OrderId == orderId);

        Assert.Equal(OrderStatus.Delivering, order.Status);
        Assert.Equal(DeliveryStatus.Delivering, tracking.Status);
        Assert.Equal(1, await db.DeliveryWebhookEvents.CountAsync(x => x.ExternalEventId == eventId));
        notification.Verify(n => n.SendOrderStatusAsync(
            userId, It.IsAny<string>(), It.IsAny<string>(), orderId, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task ProcessWebhook_WithLocation_PushesLiveLocation()
    {
        var orderId = Guid.NewGuid();
        const string externalId = "ahm-ext-loc";

        var options = new DbContextOptionsBuilder<OrderDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        await using var db = new OrderDbContext(options);

        db.Orders.Add(new Order.Domain.Models.Order
        {
            Id = orderId,
            UserId = Guid.NewGuid(),
            PartnerId = Guid.NewGuid(),
            OrderCode = "ORD002",
            Status = OrderStatus.ReadyForPickup,
            SubtotalAmount = 50000m,
            DeliveryFee = 25000m,
            TotalAmount = 75000m,
            Currency = "VND",
            PaymentStatus = PaymentStatus.Paid,
            PlacedAt = DateTimeOffset.UtcNow,
        });
        db.DeliveryTrackings.Add(new DeliveryTracking
        {
            OrderId = orderId,
            Provider = "Ahamove",
            ExternalDeliveryId = externalId,
            Status = DeliveryStatus.HeadingToPickup,
        });
        await db.SaveChangesAsync();

        var deliveryProvider = new Mock<IDeliveryProvider>();
        deliveryProvider.Setup(p => p.ProviderName).Returns("Ahamove");

        var locationStore = new Mock<ITrackingLocationStore>();
        locationStore.Setup(s => s.SetLiveLocationAsync(
                orderId, It.IsAny<decimal>(), It.IsAny<decimal>(), It.IsAny<TimeSpan>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        locationStore.Setup(s => s.PublishLocationUpdateAsync(It.IsAny<Order.Application.DTOs.TrackingLocationUpdateDto>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var realtime = new Mock<ITrackingRealtimePublisher>();
        realtime.Setup(r => r.PublishLocationAsync(It.IsAny<Order.Application.DTOs.TrackingLocationUpdateDto>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var service = new DeliveryTrackingService(
            db,
            new Mock<IMarketplaceClient>().Object,
            deliveryProvider.Object,
            locationStore.Object,
            realtime.Object,
            new Mock<INotificationClient>().Object,
            new Mock<ICommissionService>().Object,
            new Mock<INutritionEventClient>().Object,
            Microsoft.Extensions.Options.Options.Create(new OrderSettings()),
            NullLogger<DeliveryTrackingService>.Instance);

        var payload = new DeliveryWebhookPayload
        {
            EventId = "evt-loc-1",
            EventType = "ORDER_CALLBACK",
            ExternalDeliveryId = externalId,
            Status = "ACCEPTED",
            Latitude = 10.78m,
            Longitude = 106.70m,
        };

        await service.ProcessWebhookAsync(payload, "{}", CancellationToken.None);

        locationStore.Verify(s => s.SetLiveLocationAsync(
            orderId, 10.78m, 106.70m, It.IsAny<TimeSpan>(), It.IsAny<CancellationToken>()), Times.Once);
        realtime.Verify(r => r.PublishLocationAsync(
            It.Is<Order.Application.DTOs.TrackingLocationUpdateDto>(d => d.OrderId == orderId && d.Latitude == 10.78m),
            It.IsAny<CancellationToken>()), Times.Once);
    }
}
