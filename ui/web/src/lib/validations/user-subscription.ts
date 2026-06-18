import { z } from "zod";

export const userSubscriptionSchema = z.object({
  userId:                 z.string().min(1, "Required"),
  subscriptionPlanId:     z.string().min(1, "Required"),
  status:                 z.string().min(1, "Required"),
  startedAt:              z.string().min(1, "Required"),
  expiredAt:              z.string().optional(),
  autoRenew:              z.boolean().default(false),
  nextBillingAt:          z.string().optional(),
  cancellationReason:     z.string().max(512).optional(),
  managedBy:              z.string().min(1, "Required"),
  externalSubscriptionId: z.string().max(256).optional(),
});

export type UserSubscriptionFormValues = z.infer<typeof userSubscriptionSchema>;
