import { z } from "zod";

export const exerciseSchema = z.object({
  exerciseCode:               z.string().min(1, "Required"),
  nameEn:                     z.string().min(1, "Required"),
  nameVi:                     z.string().min(1, "Required"),
  slug:                       z.string().min(1, "Required"),
  category:                   z.string().min(1, "Required"),
  difficulty:                 z.string().min(1, "Required"),
  movementPattern:            z.string().min(1, "Required"),
  bodyRegion:                 z.string().min(1, "Required"),
  estimatedCaloriesPerMinute: z.coerce.number().int().min(0),
  metValue:                   z.coerce.number().min(0),
  recommendedRestSeconds:     z.coerce.number().int().min(0),
  isCompound:                 z.boolean().default(false),
  requiresSpotter:            z.boolean().default(false),
  isActive:                   z.boolean().default(true),
  primaryMuscles:             z.array(z.string()).default([]),
  secondaryMuscles:           z.array(z.string()).default([]),
  equipmentRequired:          z.array(z.string()).default([]),
  contraindications:          z.array(z.string()).default([]),
  recommendedGoals:           z.array(z.string()).default([]),
  movementTags:               z.array(z.string()).default([]),
  aiCoachingCues:             z.array(z.string()).default([]),
  commonMistakes:             z.array(z.string()).default([]),
});

export type ExerciseFormValues = z.infer<typeof exerciseSchema>;
