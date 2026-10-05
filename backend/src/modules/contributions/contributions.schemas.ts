import { z } from 'zod';

export const generateDuesSchema = z.object({
  period: z.string().regex(/^\d{4}-\d{2}-01$/, 'Format: YYYY-MM-01'),
});

export const listDuesSchema = z.object({
  member_id: z.string().uuid().optional(),
  period: z.string().regex(/^\d{4}-\d{2}-01$/).optional(),
  status: z.enum(['unpaid', 'partial', 'paid', 'waived']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const myDuesSchema = z.object({
  period: z.string().regex(/^\d{4}-\d{2}-01$/).optional(),
});

export const initPaymentSchema = z.object({
  // If omitted, the logged-in member pays for themselves.
  member_id: z.string().uuid().optional(),
  // How many months to pay (default = oldest unpaid)
  months: z.coerce.number().int().min(1).max(12).default(1),
  email: z.string().email().optional(),
  include_penalties: z.boolean().default(true),
});

export const verifyPaymentSchema = z.object({
  tx_ref: z.string().min(6).max(120),
});

export const cashPaymentSchema = z.object({
  member_id: z.string().uuid(),
  amount: z.coerce.number().positive().max(1_000_000),
  note: z.string().max(300).optional(),
  // Optionally target specific dues; if omitted, allocate to oldest unpaid months
  periods: z.array(z.string().regex(/^\d{4}-\d{2}-01$/)).max(24).optional(),
});

export const listPaymentsSchema = z.object({
  member_id: z.string().uuid().optional(),
  method: z.enum(['chapa', 'cash']).optional(),
  status: z.enum(['pending', 'success', 'failed']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const paymentIdParamSchema = z.object({
  id: z.string().uuid(),
});

export type GenerateDuesInput = z.infer<typeof generateDuesSchema>;
export type ListDuesInput = z.infer<typeof listDuesSchema>;
export type InitPaymentInput = z.infer<typeof initPaymentSchema>;
export type VerifyPaymentInput = z.infer<typeof verifyPaymentSchema>;
export type CashPaymentInput = z.infer<typeof cashPaymentSchema>;
export type ListPaymentsInput = z.infer<typeof listPaymentsSchema>;