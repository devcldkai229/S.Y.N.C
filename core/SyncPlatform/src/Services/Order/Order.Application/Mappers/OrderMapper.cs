using Order.Application.DTOs;
using Order.Domain.Models;

namespace Order.Application.Mappers;

public static class OrderMapper
{
    public static OrderDto ToDto(this Domain.Models.Order entity) => new()
    {
        Id = entity.Id,
        UserId = entity.UserId,
        PartnerId = entity.PartnerId,
        OrderCode = entity.OrderCode,
        Status = entity.Status,
        SubtotalAmount = entity.SubtotalAmount,
        DeliveryFee = entity.DeliveryFee,
        DiscountAmount = entity.DiscountAmount,
        TotalAmount = entity.TotalAmount,
        Currency = entity.Currency,
        PaymentStatus = entity.PaymentStatus,
        DeliveryAddress = entity.DeliveryAddress,
        DeliveryLat = entity.DeliveryLat,
        DeliveryLng = entity.DeliveryLng,
        RecipientName = entity.RecipientName,
        RecipientPhone = entity.RecipientPhone,
        Notes = entity.Notes,
        IsAiInitiated = entity.IsAiInitiated,
        PlacedAt = entity.PlacedAt,
        CompletedAt = entity.CompletedAt,
        Items = entity.Items.Select(i => i.ToDto()).ToList(),
    };

    public static OrderItemDto ToDto(this OrderItem item) => new()
    {
        Id = item.Id,
        FoodMenuItemId = item.FoodMenuItemId,
        NameSnapshot = item.NameSnapshot,
        ImageUrlSnapshot = item.ImageUrlSnapshot,
        UnitPrice = item.UnitPrice,
        Quantity = item.Quantity,
        Subtotal = item.Subtotal,
        Notes = item.Notes,
    };

    public static DeliveryTrackingDto ToDto(this DeliveryTracking tracking) => new()
    {
        OrderId = tracking.OrderId,
        Provider = tracking.Provider,
        ExternalDeliveryId = tracking.ExternalDeliveryId,
        ShipperName = tracking.ShipperName,
        ShipperPhone = tracking.ShipperPhone,
        ShipperPlateNumber = tracking.ShipperPlateNumber,
        Status = tracking.Status,
        LastKnownLat = tracking.LastKnownLat,
        LastKnownLng = tracking.LastKnownLng,
        LastLocationUpdatedAt = tracking.LastLocationUpdatedAt,
        EstimatedArrivalAt = tracking.EstimatedArrivalAt,
    };

    public static CommissionRecordDto ToDto(this CommissionRecord record) => new()
    {
        Id = record.Id,
        Source = record.Source,
        OrderId = record.OrderId,
        PartnerId = record.PartnerId,
        RelatedProductId = record.RelatedProductId,
        ClickToken = record.ClickToken,
        ExternalReferenceId = record.ExternalReferenceId,
        GrossAmount = record.GrossAmount,
        CommissionRate = record.CommissionRate,
        CommissionAmount = record.CommissionAmount,
        Status = record.Status,
        ConfirmedAt = record.ConfirmedAt,
        PaidAt = record.PaidAt,
        CreatedAt = record.CreatedAt,
    };
}
