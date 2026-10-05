import { z } from 'zod';

export const listPenaltiesSchema = z.object({
  member_id: z.string().uuid().optional(),
  status: z.enum(['unpaid', 'paid', 'waived']).optional(),
  due_id: z.string().uuid().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const manualPenaltySchema = z.object({
  member_id: z.string().uuid(),
  due_id: z.string().uuid().optional(),
  amount: z.coerce.number().positive().max(1_000_000),
  reason: z.string().trim().min(3).max(500),
});

export const waivePenaltySchema = z.object({
  reason: z.string().trim().min(3).max(500),
});

export const idParamSchema = z.object({
  id: z.string().uuid(),
});

export type ListPenaltiesInput = z.infer<typeof listPenaltiesSchema>;
export type ManualPenaltyInput = z.infer<typeof manualPenaltySchema>;
export type WaivePenaltyInput = z.infer<typeof waivePenaltySchema>;