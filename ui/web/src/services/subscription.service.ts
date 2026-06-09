import { userApi } from "./user-api";

export interface SubscriptionPlan {
  id: string;
  name: string;
  description?: string;
  monthlyPrice: number;
  currency: string;
  features?: string[];
  aiUsageLimitPerMonth: number;
  premiumWorkoutAccess: boolean;
  priorityAiResponses: boolean;
  isActive: boolean;
}

export interface PaymentLink {
  transactionId: string;
  orderCode: number;
  checkoutUrl: string;
  qrCode: string;
  amount: number;
  currency: string;
}

export interface TransactionStatus {
  id: string;
  orderCode: number;
  status: string;
  amount: number;
  currency: string;
  couponCode?: string;
  processedAt?: string;
}

export interface ActiveSubscription {
  id: string;
  subscriptionPlanId: string;
  subscriptionPlanName: string;
  status: string;
  startedAt: string;
  expiredAt?: string;
  cancellationReason?: string;
}

interface ApiEnvelope<T> { success: boolean; message: string; data: T | null }

export const subscriptionService = {
  async getPlans(): Promise<SubscriptionPlan[]> {
    const res = await userApi.get<ApiEnvelope<SubscriptionPlan[]>>("/api/v1/payment/subscription-plans");
    return res.data ?? [];
  },

  async getActiveSubscription(): Promise<ActiveSubscription | null> {
    try {
      const res = await userApi.get<ApiEnvelope<ActiveSubscription>>(
        "/api/v1/payment/user-subscriptions/me/active"
      );
      return res.data ?? null;
    } catch {
      return null;
    }
  },

  async createPaymentLink(planId: string, couponCode?: string): Promise<PaymentLink> {
    const res = await userApi.post<ApiEnvelope<PaymentLink>>("/api/v1/payment/payos/create-link", {
      planId,
      billingCycle: 0,
      couponCode: couponCode || undefined,
    });
    if (!res.data) throw new Error(res.message || "Không thể tạo link thanh toán.");
    return res.data;
  },

  async getTransactionByOrderCode(orderCode: number): Promise<TransactionStatus | null> {
    try {
      const res = await userApi.get<ApiEnvelope<TransactionStatus>>(
        `/api/v1/payment/transactions/by-order-code/${orderCode}`
      );
      return res.data ?? null;
    } catch {
      return null;
    }
  },

  async cancelSubscription(reason?: string): Promise<void> {
    await userApi.post("/api/v1/payment/user-subscriptions/me/cancel", {
      cancellationReason: reason,
    });
  },
};
