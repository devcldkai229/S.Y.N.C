using Order.Domain.Enums;

namespace Order.Application.DTOs;

public class PlaceOrderItemDto
{
    public Guid FoodMenuItemId { get; set; }

    public int Quantity { get; set; }

    public string? Notes { get; set; }
}

public enum CheckoutPaymentMethod
{
    Wallet = 0,
    VietQR = 3,
    COD = 2,
}

public class PlaceOrderDto
{
    public Guid PartnerId { get; set; }

    public List<PlaceOrderItemDto> Items { get; set; } = [];

    public CheckoutPaymentMethod PaymentMethod { get; set; } = CheckoutPaymentMethod.Wallet;

    public string? VoucherCode { get; set; }

    public Guid? VoucherId { get; set; }

    public string? DeliveryAddress { get; set; }

    public decimal? DeliveryLat { get; set; }

    public decimal? DeliveryLng { get; set; }

    public string? RecipientName { get; set; }

    public string? RecipientPhone { get; set; }

    public string? Notes { get; set; }

    public bool IsAiInitiated { get; set; }

    public string? AIReasoningSnapshotJson { get; set; }

    public string? ClientRequestKey { get; set; }

    public string? IdempotencyKey { get; set; }
}

public class PlaceOrderResultDto
{
    public OrderDto Order { get; set; } = null!;

    public string? PayUrl { get; set; }

    public string? Deeplink { get; set; }

    public string? CheckoutUrl { get; set; }

    public string? QrCode { get; set; }

    public long? PayOsOrderCode { get; set; }

    public bool RequiresExternalPayment { get; set; }
}

public class ActiveOrderCountDto
{
    public int Count { get; set; }
}

public class OrderItemDto
{
    public Guid Id { get; set; }

    public Guid FoodMenuItemId { get; set; }

    public string NameSnapshot { get; set; } = string.Empty;

    public string? ImageUrlSnapshot { get; set; }

    public decimal UnitPrice { get; set; }

    public int Quantity { get; set; }

    public decimal Subtotal { get; set; }

    public string? Notes { get; set; }
}

public class OrderDto
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public Guid PartnerId { get; set; }

    public string OrderCode { get; set; } = string.Empty;

    public OrderStatus Status { get; set; }

    public decimal SubtotalAmount { get; set; }

    public decimal DeliveryFee { get; set; }

    public decimal DiscountAmount { get; set; }

    public decimal TotalAmount { get; set; }

    public string Currency { get; set; } = string.Empty;

    public PaymentStatus PaymentStatus { get; set; }

    public string? DeliveryAddress { get; set; }

    public decimal? DeliveryLat { get; set; }

    public decimal? DeliveryLng { get; set; }

    public string? RecipientName { get; set; }

    public string? RecipientPhone { get; set; }

    public string? Notes { get; set; }

    public bool IsAiInitiated { get; set; }

    public DateTimeOffset PlacedAt { get; set; }

    public DateTimeOffset? CompletedAt { get; set; }

    public DeliveryStatus? DeliveryStatus { get; set; }

    public IReadOnlyList<OrderItemDto> Items { get; set; } = [];
}

public class OrderDetailDto : OrderDto
{
    public DeliveryTrackingDto? Tracking { get; set; }
}

public class CancelOrderDto
{
    public string? Reason { get; set; }
}

public class UpdateOrderStatusDto
{
    public OrderStatus Status { get; set; }

    public string? Note { get; set; }
}

public class OrderListRequest
{
    public OrderStatus? Status { get; set; }

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}
