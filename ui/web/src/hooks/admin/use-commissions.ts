import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, type Paged } from "@/services/api";
import { toast } from "sonner";

// ── Enums ────────────────────────────────────────────────────────────────────
export type CommissionSource = "FoodDelivery" | "Affiliate";
export type CommissionStatus = "Pending" | "Confirmed" | "Paid" | "Cancelled";

export const COMMISSION_SOURCE_LABELS: Record<CommissionSource, string> = {
  FoodDelivery: "Giao đồ ăn",
  Affiliate:    "Affiliate",
};

export const COMMISSION_STATUS_LABELS: Record<CommissionStatus, string> = {
  Pending:   "Chờ xử lý",
  Confirmed: "Đã xác nhận",
  Paid:      "Đã thanh toán",
  Cancelled: "Đã hủy",
};

export const COMMISSION_STATUS_COLORS: Record<CommissionStatus, string> = {
  Pending:   "bg-yellow-100 text-yellow-800",
  Confirmed: "bg-blue-100 text-blue-800",
  Paid:      "bg-green-100 text-green-800",
  Cancelled: "bg-red-100 text-red-800",
};

// ── DTOs ─────────────────────────────────────────────────────────────────────
export interface CommissionRecordDto {
  id:                  string;
  source:              CommissionSource;
  orderId?:            string | null;
  partnerId:           string;
  relatedProductId?:   string | null;
  clickToken?:         string | null;
  externalReferenceId?: string | null;
  grossAmount:         number;
  commissionRate:      number;
  commissionAmount:    number;
  status:              CommissionStatus;
  confirmedAt?:        string | null;
  paidAt?:             string | null;
  createdAt:           string;
}

export interface CommissionRevenueSummaryDto {
  totalGross:      number;
  totalCommission: number;
  recordCount:     number;
}

export interface CommissionListRequest {
  source?:     CommissionSource;
  partnerId?:  string;
  status?:     CommissionStatus;
  from?:       string;
  to?:         string;
  pageNumber?: number;
  pageSize?:   number;
}

export interface MarkCommissionPaidDto {
  paidAt?: string;
}

// ── Hooks ─────────────────────────────────────────────────────────────────────
export function useCommissions(params: CommissionListRequest = {}) {
  const qs = new URLSearchParams();
  if (params.source)    qs.set("source",    params.source);
  if (params.partnerId) qs.set("partnerId", params.partnerId);
  if (params.status)    qs.set("status",    params.status);
  if (params.from)      qs.set("from",      params.from);
  if (params.to)        qs.set("to",        params.to);
  qs.set("pageNumber", String(params.pageNumber ?? 1));
  qs.set("pageSize",   String(params.pageSize   ?? 50));

  return useQuery({
    queryKey: ["admin", "commissions", params],
    queryFn:  (): Promise<Paged<CommissionRecordDto>> =>
      api.getPaged<CommissionRecordDto>(`/api/v1/order/commissions?${qs}`),
  });
}

export function useCommissionRevenueSummary(params: Omit<CommissionListRequest, "pageNumber" | "pageSize"> = {}) {
  const qs = new URLSearchParams();
  if (params.source)    qs.set("source",    params.source);
  if (params.partnerId) qs.set("partnerId", params.partnerId);
  if (params.status)    qs.set("status",    params.status);
  if (params.from)      qs.set("from",      params.from);
  if (params.to)        qs.set("to",        params.to);

  return useQuery({
    queryKey: ["admin", "commissions", "revenue-summary", params],
    queryFn:  () => api.get<CommissionRevenueSummaryDto>(`/api/v1/order/commissions/revenue-summary?${qs}`),
  });
}

export function useMarkCommissionPaid() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, paidAt }: { id: string; paidAt?: string }) =>
      api.patch<CommissionRecordDto>(`/api/v1/order/commissions/${id}/mark-paid`, { paidAt }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "commissions"] });
      toast.success("Đã đánh dấu hoa hồng là đã thanh toán");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
