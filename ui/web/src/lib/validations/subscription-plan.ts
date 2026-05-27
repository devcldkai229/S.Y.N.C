import { z } from "zod";

export const subscriptionPlanSchema = z.object({
  name:                     z.string().min(1, "Required").max(128),
  description:              z.string().max(512).optional(),
  monthlyPrice:             z.coerce.number().min(0),
  yearlyPrice:              z.coerce.number().min(0),
  currency:                 z.string().min(1).max(8).default("VND"),
  features:                 z.array(z.string()).default([]),
  aiUsageLimitPerMonth:     z.coerce.number().int().min(0),
  premiumWorkoutAccess:     z.boolean().default(false),
  premiumMarketplaceAccess: z.boolean().default(false),
  priorityAiResponses:      z.boolean().default(false),
  maxAiAutoOrdersPerMonth:  z.coerce.number().int().min(0),
  isActive:                 z.boolean().default(true),
  googlePlayProductId:      z.string().max(128).optional(),
});

export type SubscriptionPlanFormValues = z.infer<typeof subscriptionPlanSchema>;
