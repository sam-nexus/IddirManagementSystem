import { z } from 'zod';

export const createRequestSchema = z.object({
  // If omitted, the request is for the member themselves.
  dependent_id: z.string().uuid().optional(),
  type: z.enum(['death', 'illness', 'emergency', 'other']),
  description: z.string().trim().min(3).max(2000),
  amount_requested: z.coerce.number().positive().max(1_000_000).optional(),
  attachment_url: z.string().url().max(500).optional(),
});

export const updateRequestSchema = z.object({
  description: z.string().trim().min(3).max(2000).optional(),
  amount_requested: z.coerce.number().positive().max(1_000_000).nullable().optional(),
  attachment_url: z.string().url().max(500).nullable().optional(),
});

export const listRequestsSchema = z.object({
  status: z.enum(['pending', 'under_review', 'approved', 'rejected', 'paid', 'cancelled']).optional(),
  type: z.enum(['death', 'illness', 'emergency', 'other']).optional(),
  member_id: z.string().uuid().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const idParamSchema = z.object({
  id: z.string().uuid(),
});

export const decideSchema = z.object({
  decision: z.enum(['approve', 'reject']),
  comment: z.string().trim().max(500).optional(),
});

export const payoutSchema = z.object({
  amount: z.coerce.number().positive().max(1_000_000),
  paid_on: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  method: z.enum(['cash', 'bank', 'telebirr']).optional(),
  reference: z.string().trim().max(120).optional(),
});

export const listPayoutsSchema = z.object({
  member_id: z.string().uuid().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export type CreateRequestInput = z.infer<typeof createRequestSchema>;
export type UpdateRequestInput = z.infer<typeof updateRequestSchema>;
export type ListRequestsInput = z.infer<typeof listRequestsSchema>;
export type DecideInput = z.infer<typeof decideSchema>;
export type PayoutInput = z.infer<typeof payoutSchema>;
export type ListPayoutsInput = z.infer<typeof listPayoutsSchema>;