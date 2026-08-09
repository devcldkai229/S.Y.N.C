import { userApi } from "@/services/user-api";
import {
  subscriptionService,
  type ActiveSubscription,
} from "@/services/subscription.service";

interface ProfileSettingsEnvelope {
  success: boolean;
  data?: {
    basic?: { subscriptionTier?: string };
  };
}

/** True when IAM / profile reports a paid digital tier (Premium / Ultra). */
export function isPaidSubscriptionTier(tier?: string | null): boolean {
  const t = (tier ?? "").trim().toLowerCase();
  return t.includes("premium") || t.includes("ultra");
}

export function isActivePaymentSubscription(sub: ActiveSubscription | null): boolean {
  if (!sub) return false;
  const expiry = sub.expiredAt ? new Date(sub.expiredAt) : null;
  if (expiry && expiry <= new Date()) return false;
  return sub.status === "Active" || sub.status === "Cancelled";
}

export async function fetchIamSubscriptionTier(): Promise<string | null> {
  try {
    const profile = await userApi.get<ProfileSettingsEnvelope>(
      "/api/v1/iam/me/profile-settings",
    );
    const tier = profile.data?.basic?.subscriptionTier?.trim();
    return tier || null;
  } catch {
    return null;
  }
}

export type PremiumAccess = {
  hasPremium: boolean;
  activeSub: ActiveSubscription | null;
  subscriptionTier: string;
};

/**
 * Premium if Payment has an in-period Active/Cancelled sub,
 * OR IAM profile tier is Premium/Ultra (covers Play Billing / sync lag).
 */
export async function resolvePremiumAccess(): Promise<PremiumAccess> {
  const [activeSub, tier] = await Promise.all([
    subscriptionService.getActiveSubscription().catch(() => null),
    fetchIamSubscriptionTier(),
  ]);
  const subscriptionTier = tier || "Free";
  const hasPremium =
    isActivePaymentSubscription(activeSub) || isPaidSubscriptionTier(subscriptionTier);
  return { hasPremium, activeSub, subscriptionTier };
}
