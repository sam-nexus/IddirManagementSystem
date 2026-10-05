import { z } from 'zod';

export const keyParamSchema = z.object({
  key: z.string().min(1).max(100),
});

export const updateSettingSchema = z.object({
  value: z.union([z.string(), z.number(), z.boolean(), z.record(z.any()), z.array(z.any())]),
});

export type UpdateSettingInput = z.infer<typeof updateSettingSchema>;