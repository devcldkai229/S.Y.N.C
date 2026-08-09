"use client";

import { useParams, useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Separator } from "@/components/ui/separator";
import {
  ArrowLeft, Bot, MapPin, Phone, User, Package, Truck, CreditCard, ShoppingCart,
  Clock, AlertCircle, CheckCircle2,
} from "lucide-react";
import { format } from "date-fns";
import { useOrder, ORDER_STATUS_LABELS, ORDER_STATUS_COLORS, type OrderStatus } from "@/hooks/admin/use-orders";

const fmt = (n: number) => new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(n);

function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex items-start justify-between py-2 gap-4">
      <span className="text-sm text-muted-foreground shrink-0">{label}</span>
      <span className="text-sm font-medium text-right">{value}</span>
    </div>
  );
}

const DELIVERY_STATUS_LABELS: Record<string, string> = {
  Pending: "Chờ giao", Assigned: "Đã phân công", HeadingToPickup: "Đang đến lấy",
  ArrivedAtPickup: "Đã đến lấy", PickedUp: "Đã lấy hàng", Delivering: "Đang giao",
  Arrived: "Đã đến nơi", Completed: "Hoàn thành", Failed: "Thất bại", Cancelled: "Đã hủy",
};

export default function OrderDetailPage() {
  const params = useParams<{ id: string }>();
  const id = params?.id as string;
  const router  = useRouter();
  const { data: order, isLoading, isError } = useOrder(id);

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-48 rounded-lg" />
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-48 rounded-xl" />)}
        </div>
      </div>
    );
  }

  if (isError || !order) {
    return (
      <div className="flex flex-col items-center justify-center py-20 gap-3 text-muted-foreground">
        <AlertCircle className="w-10 h-10" />
        <p>Không tìm thấy đơn hàng.</p>
        <Button variant="outline" size="sm" onClick={() => router.back()}>Quay lại</Button>
      </div>
    );
  }

  const statusCls = ORDER_STATUS_COLORS[order.status as OrderStatus] ?? "bg-gray-100 text-gray-600";
  const tracking  = order.tracking;

  // Status timeline steps
  const STEPS: OrderStatus[] = ["Pending", "Confirmed", "Preparing", "ReadyForPickup", "Delivering", "Delivered", "Completed"];
  const currentIdx = STEPS.indexOf(order.status as OrderStatus);

  return (
    <div className="space-y-4 max-w-5xl">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => router.back()}>
          <ArrowLeft className="w-4 h-4" />
        </Button>
        <div className="flex-1">
          <div className="flex items-center gap-2 flex-wrap">
            <h1 className="text-lg font-bold font-mono">#{order.orderCode}</h1>
            <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${statusCls}`}>
              {ORDER_STATUS_LABELS[order.status as OrderStatus] ?? order.status}
            </span>
            {order.isAiInitiated && (
              <Badge className="gap-1 text-xs bg-purple-100 text-purple-800 border-purple-200">
                <Bot className="w-3 h-3" /> AI Order
              </Badge>
            )}
          </div>
          <p className="text-xs text-muted-foreground mt-0.5">
            Đặt lúc {format(new Date(order.placedAt), "HH:mm dd/MM/yyyy")}
          </p>
        </div>
      </div>

      {/* Status timeline */}
      {!["Cancelled", "Refunded"].includes(order.status) && (
        <Card className="shadow-none">
          <CardContent className="pt-4 pb-3">
            <div className="flex items-center gap-0">
              {STEPS.map((step, i) => {
                const done    = i <= currentIdx;
                const current = i === currentIdx;
                return (
                  <div key={step} className="flex items-center flex-1 last:flex-none">
                    <div className="flex flex-col items-center gap-1">
                      <div className={`w-7 h-7 rounded-full flex items-center justify-center border-2 transition-colors ${
                        done
                          ? "bg-primary border-primary text-primary-foreground"
                          : "bg-background border-border text-muted-foreground"
                      }`}>
                        {done && !current
                          ? <CheckCircle2 className="w-3.5 h-3.5" />
                          : <Clock className={`w-3.5 h-3.5 ${current ? "" : "opacity-40"}`} />}
                      </div>
                      <span className={`text-xs text-center leading-tight max-w-14 ${done ? "text-primary font-medium" : "text-muted-foreground"}`}>
                        {ORDER_STATUS_LABELS[step]}
                      </span>
                    </div>
                    {i < STEPS.length - 1 && (
                      <div className={`flex-1 h-0.5 mb-5 mx-1 ${i < currentIdx ? "bg-primary" : "bg-border"}`} />
                    )}
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Left col: Order items */}
        <div className="lg:col-span-2 space-y-4">
          <Card className="shadow-none">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-semibold flex items-center gap-2">
                <ShoppingCart className="w-4 h-4" /> Danh sách món ({order.items.length})
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="divide-y divide-border">
                {order.items.map(item => (
                  <div key={item.id} className="flex items-center gap-3 py-3">
                    {item.imageUrlSnapshot ? (
                      <img src={item.imageUrlSnapshot} alt={item.nameSnapshot} className="w-12 h-12 rounded-lg object-cover" />
                    ) : (
                      <div className="w-12 h-12 rounded-lg bg-muted flex items-center justify-center">
                        <Package className="w-5 h-5 text-muted-foreground" />
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium truncate">{item.nameSnapshot}</p>
                      <p className="text-xs text-muted-foreground">x{item.quantity} × {fmt(item.unitPrice)}</p>
                      {item.notes && <p className="text-xs text-muted-foreground italic">"{item.notes}"</p>}
                    </div>
                    <span className="text-sm font-semibold">{fmt(item.subtotal)}</span>
                  </div>
                ))}
              </div>

              <Separator className="my-3" />

              {/* Price breakdown */}
              <div className="space-y-1">
                <div className="flex justify-between text-sm text-muted-foreground">
                  <span>Tạm tính</span><span>{fmt(order.subtotalAmount)}</span>
                </div>
                <div className="flex justify-between text-sm text-muted-foreground">
                  <span>Phí giao hàng</span><span>{fmt(order.deliveryFee)}</span>
                </div>
                {order.discountAmount > 0 && (
                  <div className="flex justify-between text-sm text-green-600">
                    <span>Giảm giá</span><span>-{fmt(order.discountAmount)}</span>
                  </div>
                )}
                <Separator className="my-1" />
                <div className="flex justify-between font-semibold">
                  <span>Tổng cộng</span><span className="text-primary">{fmt(order.totalAmount)}</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* AI Reasoning */}
          {order.isAiInitiated && order.aiReasoningSnapshotJson && (
            <Card className="shadow-none border-purple-200 bg-purple-50/30">
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-semibold flex items-center gap-2 text-purple-700">
                  <Bot className="w-4 h-4" /> AI Reasoning
                </CardTitle>
              </CardHeader>
              <CardContent>
                <pre className="text-xs text-purple-800 font-mono whitespace-pre-wrap break-all">
                  {(() => {
                    try { return JSON.stringify(JSON.parse(order.aiReasoningSnapshotJson!), null, 2); }
                    catch { return order.aiReasoningSnapshotJson; }
                  })()}
                </pre>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Right col: Info cards */}
        <div className="space-y-4">
          {/* Delivery info */}
          <Card className="shadow-none">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-semibold flex items-center gap-2">
                <MapPin className="w-4 h-4" /> Giao hàng
              </CardTitle>
            </CardHeader>
            <CardContent className="divide-y divide-border/50">
              <InfoRow label="Người nhận"   value={order.recipientName || "—"} />
              <InfoRow label="Điện thoại"   value={
                order.recipientPhone ? (
                  <a href={`tel:${order.recipientPhone}`} className="flex items-center gap-1 text-primary hover:underline">
                    <Phone className="w-3 h-3" /> {order.recipientPhone}
                  </a>
                ) : "—"
              } />
              <InfoRow label="Địa chỉ"      value={<span className="text-right break-words max-w-36">{order.deliveryAddress || "—"}</span>} />
              {order.notes && (
                <InfoRow label="Ghi chú"   value={<em className="text-muted-foreground text-right">{order.notes}</em>} />
              )}
            </CardContent>
          </Card>

          {/* Payment */}
          <Card className="shadow-none">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-semibold flex items-center gap-2">
                <CreditCard className="w-4 h-4" /> Thanh toán
              </CardTitle>
            </CardHeader>
            <CardContent className="divide-y divide-border/50">
              <InfoRow label="Trạng thái" value={
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                  order.paymentStatus === "Paid" ? "bg-green-100 text-green-800" :
                  order.paymentStatus === "Unpaid" ? "bg-red-100 text-red-800" :
                  "bg-gray-100 text-gray-600"
                }`}>{order.paymentStatus}</span>
              } />
              <InfoRow label="Tổng thanh toán" value={<span className="font-bold text-primary">{fmt(order.totalAmount)}</span>} />
            </CardContent>
          </Card>

          {/* Delivery tracking */}
          {tracking && (
            <Card className="shadow-none">
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-semibold flex items-center gap-2">
                  <Truck className="w-4 h-4" /> Vận chuyển
                </CardTitle>
              </CardHeader>
              <CardContent className="divide-y divide-border/50">
                <InfoRow label="Provider"     value={tracking.provider} />
                <InfoRow label="Trạng thái"   value={
                  <span className="text-xs font-medium">{DELIVERY_STATUS_LABELS[tracking.status] ?? tracking.status}</span>
                } />
                {tracking.shipperName && (
                  <InfoRow label="Shipper" value={
                    <div className="flex items-center gap-1 text-right">
                      <User className="w-3 h-3" /> {tracking.shipperName}
                    </div>
                  } />
                )}
                {tracking.shipperPhone && (
                  <InfoRow label="SĐT shipper" value={
                    <a href={`tel:${tracking.shipperPhone}`} className="flex items-center gap-1 text-primary hover:underline">
                      <Phone className="w-3 h-3" /> {tracking.shipperPhone}
                    </a>
                  } />
                )}
                {tracking.estimatedArrivalAt && (
                  <InfoRow label="ETA" value={format(new Date(tracking.estimatedArrivalAt), "HH:mm dd/MM")} />
                )}
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
