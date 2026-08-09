import { useQuery } from "@tanstack/react-query";
import { api, type Paged } from "@/services/api";

// ── Enums ────────────────────────────────────────────────────────────────────
export type TxStatus     = "Pending" | "Processing" | "Succeeded" | "Failed" | "Refunded" | "Cancelled";
export type TxType       = "MealPurchase" | "SupplementPurchase" | "DigitalAssetPurchase" | "Subscription" | "WalletTopup" | "Refund" | "Reward";
export type PaymentMethod = "Wallet" | "Momo" | "COD" | "VietQR";
export type TxProvider   = "InternalWallet" | "GooglePlay" | "PayOS" | "Momo";

export const TX_STATUS_LABELS: Record<TxStatus, string> = {
  Pending:    "Chờ xử lý",
  Processing: "Đang xử lý",
  Succeeded:  "Thành công",
  Failed:     "Thất bại",
  Refunded:   "Đã hoàn",
  Cancelled:  "Đã hủy",
};

export const TX_STATUS_COLORS: Record<TxStatus, string> = {
  Pending:    "bg-yellow-100 text-yellow-800",
  Processing: "bg-blue-100 text-blue-800",
  Succeeded:  "bg-green-100 text-green-800",
  Failed:     "bg-red-100 text-red-800",
  Refunded:   "bg-indigo-100 text-indigo-800",
  Cancelled:  "bg-gray-100 text-gray-600",
};

export const TX_TYPE_LABELS: Record<TxType, string> = {
  MealPurchase:           "Mua đồ ăn",
  SupplementPurchase:     "Mua supplement",
  DigitalAssetPurchase:   "Mua tài sản số",
  Subscription:           "Gói đăng ký",
  WalletTopup:            "Nạp ví",
  Refund:                 "Hoàn tiền",
  Reward:                 "Phần thưởng",
};

export const PAYMENT_METHOD_LABELS: Record<string, string> = {
  Wallet: "Ví SYNC", Momo: "Momo", COD: "COD", VietQR: "VietQR",
};

export const TX_PROVIDER_LABELS: Record<string, string> = {
  InternalWallet: "Ví nội bộ", GooglePlay: "Google Play", PayOS: "PayOS", Momo: "Momo",
};

// ── DTOs ─────────────────────────────────────────────────────────────────────
export interface TransactionDto {
  id:                    string;
  walletId?:             string | null;
  userId:                string;
  transactionType:       TxType;
  status:                TxStatus;
  paymentMethod:         PaymentMethod;
  amount:                number;
  currency:              string;
  orderCode:             number;
  provider:              TxProvider;
  relatedEntityType?:    string | null;
  relatedEntityId?:      string | null;
  description?:          string | null;
  isAiInitiated:         boolean;
  couponCode?:           string | null;
  createdAt:             string;
  processedAt?:          string | null;
  failedReason?:         string | null;
}

export interface TransactionListRequest {
  status?:      TxStatus;
  type?:        TxType;
  provider?:    TxProvider;
  isAiInitiated?: boolean;
  pageNumber?:  number;
  pageSize?:    number;
}

// ── Hooks ─────────────────────────────────────────────────────────────────────
/**
 * NOTE: The existing TransactionsController only exposes user-scoped lookups.
 * An AdminTransactionsController (AdminOnly policy) returning all transactions
 * with pagination is needed on the backend.
 * Endpoint placeholder: GET /api/v1/payment/admin/transactions
 */
export function useTransactions(params: TransactionListRequest = {}) {
  const qs = new URLSearchParams();
  if (params.status)   qs.set("status",   params.status);
  if (params.type)     qs.set("type",     params.type);
  if (params.provider) qs.set("provider", params.provider);
  if (params.isAiInitiated !== undefined) qs.set("isAiInitiated", String(params.isAiInitiated));
  qs.set("pageNumber", String(params.pageNumber ?? 1));
  qs.set("pageSize",   String(params.pageSize   ?? 50));

  return useQuery({
    queryKey: ["admin", "transactions", params],
    queryFn:  (): Promise<Paged<TransactionDto>> =>
      api.getPaged<TransactionDto>(`/api/v1/payment/admin/transactions?${qs}`),
  });
}

export function useTransaction(id: string) {
  return useQuery({
    queryKey: ["admin", "transactions", id],
    queryFn:  () => api.get<TransactionDto>(`/api/v1/payment/admin/transactions/${id}`),
    enabled:  !!id,
  });
}
