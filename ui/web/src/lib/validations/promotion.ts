import { z } from "zod";

export const promotionSchema = z.object({
  name:                   z.string().min(1, "Required").max(256),
  promotionType:          z.string().min(1, "Required"),
  value:                  z.coerce.number().min(0),
  couponCode:             z.string().max(64).optional(),
  applicableProductTypes: z.array(z.string()).default([]),
  minimumSpend:           z.coerce.number().min(0).default(0),
  usageLimit:             z.coerce.number().int().min(0).default(0),
  startsAt:               z.string().min(1, "Required"),
  endsAt:                 z.string().min(1, "Required"),
  isActive:               z.boolean().default(true),
}).refine((d) => new Date(d.endsAt) > new Date(d.startsAt), {
  message: "End date must be after start date",
  path: ["endsAt"],
});

export type PromotionFormValues = z.infer<typeof promotionSchema>;
