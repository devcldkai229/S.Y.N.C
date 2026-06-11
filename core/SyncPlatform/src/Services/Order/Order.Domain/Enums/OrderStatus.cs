namespace Order.Domain.Enums;

public enum OrderStatus
{
    Pending = 0,
    Confirmed = 1,
    Preparing = 2,
    ReadyForPickup = 3,
    PickedUp = 4,
    Delivering = 5,
    Delivered = 6,
    Completed = 7,
    Cancelled = 8,
    Refunded = 9,
}
