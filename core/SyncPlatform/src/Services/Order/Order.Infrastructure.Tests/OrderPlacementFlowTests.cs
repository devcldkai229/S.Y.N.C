using Moq;
using Order.Application.Clients;
using Order.Application.DTOs;
using Order.Application.Exceptions;
using Order.Domain.Enums;
using Order.Infrastructure.Tests.TestDoubles;
using Xunit;

namespace Order.Infrastructure.Tests;

public class OrderPlacementFlowTests
{
    [Fact]
    public async Task PlaceOrder_Wallet_ChargesPayment_ClearsCart_SendsNotification()
    {
        using var fx = new OrderServiceTestFactory();
        await fx.SeedCartAsync();

        var txId = Guid.NewGuid();
        fx.Payment.Setup(p => p.ChargeMealOrderAsync(It.IsAny<ChargeMealOrderRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ChargeMealOrderResult { Success = true, TransactionId = txId });

        var result = await fx.Service.PlaceOrderAsync(fx.UserId, fx.BasePlaceOrderDto(CheckoutPaymentMethod.Wallet));

        Assert.Equal(OrderStatus.Confirmed, result.Order.Status);
        Assert.Equal(PaymentStatus.Paid, result.Order.PaymentStatus);
        Assert.False(result.RequiresExternalPayment);
        Assert.Equal(110000m, result.Order.TotalAmount); // 85000 + 25000
        Assert.False(fx.CartStore.HasCart(fx.UserId));

        fx.Payment.Verify(p => p.ChargeMealOrderAsync(
            It.Is<ChargeMealOrderRequest>(r => r.UserId == fx.UserId && r.Amount == 110000m),
            It.IsAny<CancellationToken>()), Times.Once);
        fx.Notification.Verify(n => n.SendOrderStatusAsync(
            fx.UserId, It.IsAny<string>(), It.IsAny<string>(), result.Order.Id, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task PlaceOrder_COD_CreatesUnpaidOrder_ClearsCart()
    {
        using var fx = new OrderServiceTestFactory();
        await fx.SeedCartAsync();

        fx.Payment.Setup(p => p.CreateCodTransactionAsync(It.IsAny<CreateCodPaymentRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new CreateCodPaymentResult { Success = true, TransactionId = Guid.NewGuid() });

        var result = await fx.Service.PlaceOrderAsync(fx.UserId, fx.BasePlaceOrderDto(CheckoutPaymentMethod.COD));

        Assert.Equal(OrderStatus.Confirmed, result.Order.Status);
        Assert.Equal(PaymentStatus.Unpaid, result.Order.PaymentStatus);
        Assert.False(fx.CartStore.HasCart(fx.UserId));
        fx.Payment.Verify(p => p.ChargeMealOrderAsync(It.IsAny<ChargeMealOrderRequest>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task PlaceOrder_VietQr_Pending_KeepsCart_UntilConfirmPayment()
    {
        using var fx = new OrderServiceTestFactory();
        await fx.SeedCartAsync();

        fx.Payment.Setup(p => p.CreateVietQrPaymentAsync(It.IsAny<CreateVietQrPaymentRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new CreateVietQrPaymentResult
            {
                Success = true,
                TransactionId = Guid.NewGuid(),
                CheckoutUrl = "https://pay.payos.vn/web/test",
                QrCode = "qr-data",
                PayOsOrderCode = 123456789,
            });

        var result = await fx.Service.PlaceOrderAsync(fx.UserId, fx.BasePlaceOrderDto(CheckoutPaymentMethod.VietQR));

        Assert.Equal(OrderStatus.Pending, result.Order.Status);
        Assert.Equal(PaymentStatus.Unpaid, result.Order.PaymentStatus);
        Assert.True(result.RequiresExternalPayment);
        Assert.True(fx.CartStore.HasCart(fx.UserId));

        await fx.Service.ConfirmOrderPaymentAsync(result.Order.Id, Guid.NewGuid());

        Assert.False(fx.CartStore.HasCart(fx.UserId));
        fx.Notification.Verify(n => n.SendOrderStatusAsync(
            fx.UserId, It.IsAny<string>(), It.IsAny<string>(), result.Order.Id, It.IsAny<CancellationToken>()), Times.AtLeastOnce);
    }

    [Fact]
    public async Task PlaceOrder_InsufficientWallet_Returns402_DoesNotCreateOrder()
    {
        using var fx = new OrderServiceTestFactory();
        await fx.SeedCartAsync();

        fx.Payment.Setup(p => p.ChargeMealOrderAsync(It.IsAny<ChargeMealOrderRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ChargeMealOrderResult
            {
                Success = false,
                InsufficientBalance = true,
                FailureReason = "Insufficient wallet balance.",
            });

        await Assert.ThrowsAsync<PaymentRequiredException>(() =>
            fx.Service.PlaceOrderAsync(fx.UserId, fx.BasePlaceOrderDto(CheckoutPaymentMethod.Wallet)));

        Assert.Equal(0, fx.Db.Orders.Count());
        Assert.True(fx.CartStore.HasCart(fx.UserId));
    }

    [Fact]
    public async Task PlaceOrder_WithVoucher_AppliesDiscountAndMarksUsed()
    {
        using var fx = new OrderServiceTestFactory();
        await fx.SeedCartAsync();

        fx.Payment.Setup(p => p.ValidateVoucherAsync(It.IsAny<ValidateVoucherRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ValidateVoucherResult
            {
                Valid = true,
                DiscountAmount = 10000m,
                CampaignId = Guid.NewGuid(),
            });

        fx.Payment.Setup(p => p.ChargeMealOrderAsync(It.IsAny<ChargeMealOrderRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ChargeMealOrderResult { Success = true, TransactionId = Guid.NewGuid() });

        var dto = fx.BasePlaceOrderDto(CheckoutPaymentMethod.Wallet);
        dto.VoucherCode = "SYNC10";

        var result = await fx.Service.PlaceOrderAsync(fx.UserId, dto);

        Assert.Equal(10000m, result.Order.DiscountAmount);
        Assert.Equal(100000m, result.Order.TotalAmount); // 85000+25000-10000
        fx.Payment.Verify(p => p.MarkVoucherUsedAsync(
            It.Is<MarkVoucherUsedRequest>(r => r.Code == "SYNC10" && r.OrderId == result.Order.Id),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task PlaceOrder_IdempotencyKey_ReturnsExistingOrder()
    {
        using var fx = new OrderServiceTestFactory();
        await fx.SeedCartAsync();

        fx.Payment.Setup(p => p.ChargeMealOrderAsync(It.IsAny<ChargeMealOrderRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ChargeMealOrderResult { Success = true, TransactionId = Guid.NewGuid() });

        var dto = fx.BasePlaceOrderDto(CheckoutPaymentMethod.Wallet);
        var first = await fx.Service.PlaceOrderAsync(fx.UserId, dto);
        var second = await fx.Service.PlaceOrderAsync(fx.UserId, dto);

        Assert.Equal(first.Order.Id, second.Order.Id);
        Assert.Equal(1, fx.Db.Orders.Count());
    }

    [Fact]
    public async Task PlaceOrder_InvalidVoucher_ThrowsBadRequest_KeepsCart()
    {
        using var fx = new OrderServiceTestFactory();
        await fx.SeedCartAsync();

        fx.Payment.Setup(p => p.ValidateVoucherAsync(It.IsAny<ValidateVoucherRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ValidateVoucherResult
            {
                Valid = false,
                Message = "Voucher đã hết hạn.",
            });

        var dto = fx.BasePlaceOrderDto(CheckoutPaymentMethod.Wallet);
        dto.VoucherCode = "EXPIRED";

        await Assert.ThrowsAsync<BadRequestException>(() =>
            fx.Service.PlaceOrderAsync(fx.UserId, dto));

        Assert.Equal(0, fx.Db.Orders.Count());
        Assert.True(fx.CartStore.HasCart(fx.UserId));
        fx.Payment.Verify(p => p.ChargeMealOrderAsync(It.IsAny<ChargeMealOrderRequest>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task GetActiveOrderCount_ExcludesTerminalStatuses()
    {
        using var fx = new OrderServiceTestFactory();

        fx.Db.Orders.Add(new Order.Domain.Models.Order
        {
            Id = Guid.NewGuid(),
            UserId = fx.UserId,
            PartnerId = fx.PartnerId,
            OrderCode = "A1",
            Status = OrderStatus.Confirmed,
            SubtotalAmount = 1,
            DeliveryFee = 0,
            DiscountAmount = 0,
            TotalAmount = 1,
            Currency = "VND",
            PaymentStatus = PaymentStatus.Paid,
            PlacedAt = DateTimeOffset.UtcNow,
        });
        fx.Db.Orders.Add(new Order.Domain.Models.Order
        {
            Id = Guid.NewGuid(),
            UserId = fx.UserId,
            PartnerId = fx.PartnerId,
            OrderCode = "A2",
            Status = OrderStatus.Delivered,
            SubtotalAmount = 1,
            DeliveryFee = 0,
            DiscountAmount = 0,
            TotalAmount = 1,
            Currency = "VND",
            PaymentStatus = PaymentStatus.Paid,
            PlacedAt = DateTimeOffset.UtcNow,
        });
        await fx.Db.SaveChangesAsync();

        var count = await fx.Service.GetActiveOrderCountAsync(fx.UserId);
        Assert.Equal(1, count);
    }
}
