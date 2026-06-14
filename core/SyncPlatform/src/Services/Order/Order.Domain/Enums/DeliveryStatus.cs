namespace Order.Domain.Enums;

public enum DeliveryStatus
{
    Pending = 0,
    Assigned = 1,
    HeadingToPickup = 2,
    ArrivedAtPickup = 3,
    PickedUp = 4,
    Delivering = 5,
    Arrived = 6,
    Completed = 7,
    Failed = 8,
    Cancelled = 9,
}
