import { z } from 'zod';

export const submitManualSchema = z.object({
  // If omitted, the logged-in member is the payer
  member_id: z.string().uuid().optional(),
  amount: z.coerce.number().positive().max(1_000_000),
  note: z.string().trim().max(500).optional(),
  // Optional: which months this payment covers (default: oldest unpaid)
  periods: z.array(z.string().regex(/^\d{4}-\d{2}-01$/)).max(12).optional(),
  // If true, apply any remaining amount to unpaid penalties
  include_penalties: z
  .union([z.boolean(), z.string()])
  .transform((v) => (typeof v === 'boolean' ? v : v.toLowerCase() === 'true'))
  .default(true),
});

export const listManualSchema = z.object({
  status: z.enum(['pending', 'success', 'failed']).optional(),
  member_id: z.string().uuid().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const rejectManualSchema = z.object({
  reason: z.string().trim().min(3).max(500),
});

export const idParamSchema = z.object({
  id: z.string().uuid(),
});

export type SubmitManualInput = z.infer<typeof submitManualSchema>;
export type ListManualInput = z.infer<typeof listManualSchema>;
export type RejectManualInput = z.infer<typeof rejectManualSchema>;