using Order.Domain.Enums;

namespace Order.Application.Helpers;

public static class OrderStatusStateMachine
{
    private static readonly Dictionary<OrderStatus, HashSet<OrderStatus>> Transitions = new()
    {
        [OrderStatus.Pending] = [OrderStatus.Confirmed, OrderStatus.Cancelled],
        [OrderStatus.Confirmed] = [OrderStatus.Preparing, OrderStatus.Cancelled],
        [OrderStatus.Preparing] = [OrderStatus.ReadyForPickup, OrderStatus.Cancelled],
        [OrderStatus.ReadyForPickup] = [OrderStatus.PickedUp, OrderStatus.Cancelled],
        [OrderStatus.PickedUp] = [OrderStatus.Delivering],
        [OrderStatus.Delivering] = [OrderStatus.Delivered],
        [OrderStatus.Delivered] = [OrderStatus.Completed],
        [OrderStatus.Cancelled] = [OrderStatus.Refunded],
    };

    private static readonly HashSet<OrderStatus> PartnerTransitions =
    [
        OrderStatus.Confirmed,
        OrderStatus.Preparing,
        OrderStatus.ReadyForPickup,
    ];

    private static readonly HashSet<OrderStatus> SystemTransitions =
    [
        OrderStatus.PickedUp,
        OrderStatus.Delivering,
        OrderStatus.Delivered,
        OrderStatus.Completed,
        OrderStatus.Refunded,
    ];

    public static bool CanTransition(OrderStatus from, OrderStatus to) =>
        Transitions.TryGetValue(from, out var allowed) && allowed.Contains(to);

    public static bool CanPartnerTransition(OrderStatus from, OrderStatus to) =>
        PartnerTransitions.Contains(to) && CanTransition(from, to);

    public static bool CanSystemTransition(OrderStatus from, OrderStatus to) =>
        SystemTransitions.Contains(to) && CanTransition(from, to);

    public static bool CanCancel(OrderStatus status) =>
        status is OrderStatus.Pending or OrderStatus.Confirmed or OrderStatus.Preparing or OrderStatus.ReadyForPickup;
}
