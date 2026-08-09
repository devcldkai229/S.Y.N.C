import { useQuery } from "@tanstack/react-query";
import { api, type Paged } from "@/services/api";

// ── Enums ────────────────────────────────────────────────────────────────────
export type OrderStatus   = "Pending" | "Confirmed" | "Preparing" | "ReadyForPickup" | "PickedUp" | "Delivering" | "Delivered" | "Completed" | "Cancelled" | "Refunded";
export type PaymentStatus = "Unpaid" | "Paid" | "Refunded" | "Failed";
export type DeliveryStatus = "Pending" | "Assigned" | "HeadingToPickup" | "ArrivedAtPickup" | "PickedUp" | "Delivering" | "Arrived" | "Completed" | "Failed" | "Cancelled";

export const ORDER_STATUS_LABELS: Record<OrderStatus, string> = {
  Pending:        "Chờ xử lý",
  Confirmed:      "Đã xác nhận",
  Preparing:      "Đang chuẩn bị",
  ReadyForPickup: "Sẵn sàng lấy",
  PickedUp:       "Đã lấy",
  Delivering:     "Đang giao",
  Delivered:      "Đã giao",
  Completed:      "Hoàn thành",
  Cancelled:      "Đã hủy",
  Refunded:       "Đã hoàn tiền",
};

export const ORDER_STATUS_COLORS: Record<OrderStatus, string> = {
  Pending:        "bg-yellow-100 text-yellow-800",
  Confirmed:      "bg-blue-100 text-blue-800",
  Preparing:      "bg-orange-100 text-orange-800",
  ReadyForPickup: "bg-purple-100 text-purple-800",
  PickedUp:       "bg-indigo-100 text-indigo-800",
  Delivering:     "bg-cyan-100 text-cyan-800",
  Delivered:      "bg-teal-100 text-teal-800",
  Completed:      "bg-green-100 text-green-800",
  Cancelled:      "bg-red-100 text-red-800",
  Refunded:       "bg-gray-100 text-gray-800",
};

// ── DTOs ─────────────────────────────────────────────────────────────────────
export interface OrderItemDto {
  id:               string;
  foodMenuItemId:   string;
  nameSnapshot:     string;
  imageUrlSnapshot?: string | null;
  unitPrice:        number;
  quantity:         number;
  subtotal:         number;
  notes?:           string | null;
}

export interface DeliveryTrackingDto {
  orderId:              string;
  provider:             string;
  externalDeliveryId?:  string | null;
  shipperName?:         string | null;
  shipperPhone?:        string | null;
  shipperPlateNumber?:  string | null;
  status:               DeliveryStatus;
  lastKnownLat?:        number | null;
  lastKnownLng?:        number | null;
  lastLocationUpdatedAt?: string | null;
  estimatedArrivalAt?:  string | null;
  assignedAt?:          string | null;
  pickedUpAt?:          string | null;
  deliveredAt?:         string | null;
}

export interface OrderDto {
  id:              string;
  userId:          string;
  partnerId:       string;
  orderCode:       string;
  status:          OrderStatus;
  subtotalAmount:  number;
  deliveryFee:     number;
  discountAmount:  number;
  totalAmount:     number;
  currency:        string;
  paymentStatus:   PaymentStatus;
  deliveryAddress?: string | null;
  recipientName?:  string | null;
  recipientPhone?: string | null;
  notes?:          string | null;
  isAiInitiated:   boolean;
  aiReasoningSnapshotJson?: string | null;
  placedAt:        string;
  completedAt?:    string | null;
  deliveryStatus?: DeliveryStatus | null;
  items:           OrderItemDto[];
}

export interface OrderDetailDto extends OrderDto {
  tracking?: DeliveryTrackingDto | null;
}

export interface OrderListRequest {
  status?:     OrderStatus;
  pageNumber?: number;
  pageSize?:   number;
}

// ── Hooks ─────────────────────────────────────────────────────────────────────
/**
 * NOTE: The backend `OrdersController` currently only serves user-scoped orders.
 * An `AdminOrdersController` (AuthPolicies.AdminOnly) needs to be added to expose
 * system-wide listing. For now, we call the existing user endpoint which will
 * still be useful once the admin endpoint is wired up on the same URL pattern.
 */
export function useOrders(params: OrderListRequest = {}) {
  const qs = new URLSearchParams();
  if (params.status) qs.set("status", params.status);
  qs.set("pageNumber", String(params.pageNumber ?? 1));
  qs.set("pageSize",   String(params.pageSize   ?? 50));

  return useQuery({
    queryKey: ["admin", "orders", params],
    queryFn:  (): Promise<Paged<OrderDto>> =>
      api.getPaged<OrderDto>(`/api/v1/order/orders?${qs}`),
  });
}

export function useOrder(id: string) {
  return useQuery({
    queryKey: ["admin", "orders", id],
    queryFn:  () => api.get<OrderDetailDto>(`/api/v1/order/orders/${id}`),
    enabled:  !!id,
  });
}
