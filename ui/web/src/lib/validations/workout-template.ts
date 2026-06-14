import { z } from "zod";

export const sessionBlockSchema = z.object({
  order:       z.coerce.number().int().min(0),
  exerciseId:  z.string().min(1, "Required"),
  sets:        z.coerce.number().int().min(0),
  minReps:     z.coerce.number().int().min(0),
  maxReps:     z.coerce.number().int().min(0),
  restSeconds: z.coerce.number().int().min(0),
  tempo:       z.string().default(""),
  rir:         z.coerce.number().int().min(0),
  notes:       z.string().optional(),
});

export const workoutTemplateSchema = z.object({
  name:                     z.string().min(1, "Required").max(256),
  goal:                     z.string().min(1, "Required").max(256),
  difficulty:               z.string().min(1, "Required"),
  estimatedDurationMinutes: z.coerce.number().int().min(0),
  estimatedCaloriesBurn:    z.coerce.number().int().min(0),
  aiRecoveryScore:          z.coerce.number().int().min(0).max(100),
  isSystemTemplate:         z.boolean().default(true),
  createdBy:                z.string().min(1).default("system"),
  sessions:                 z.array(sessionBlockSchema).default([]),
});

export type WorkoutTemplateFormValues = z.infer<typeof workoutTemplateSchema>;
