import { z } from 'zod';

// ---------- Items ----------
export const createItemSchema = z.object({
  name_en: z.string().trim().min(1).max(150),
  name_om: z.string().trim().min(1).max(150),
  description_en: z.string().trim().max(1000).optional(),
  description_om: z.string().trim().max(1000).optional(),
  quantity_total: z.coerce.number().int().min(0).max(100000),
});

export const updateItemSchema = z.object({
  name_en: z.string().trim().min(1).max(150).optional(),
  name_om: z.string().trim().min(1).max(150).optional(),
  description_en: z.string().trim().max(1000).nullable().optional(),
  description_om: z.string().trim().max(1000).nullable().optional(),
  quantity_total: z.coerce.number().int().min(0).max(100000).optional(),
  is_active: z.boolean().optional(),
});

export const listItemsSchema = z.object({
  search: z.string().trim().max(80).optional(),
  include_inactive: z.coerce.boolean().default(false),
  only_available: z.coerce.boolean().default(false),
});

// ---------- Requests ----------
export const createRequestSchema = z.object({
  item_id: z.string().uuid(),
  quantity: z.coerce.number().int().min(1).max(1000),
  purpose: z.string().trim().max(1000).optional(),
  needed_from: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  needed_until: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
}).refine((d) => d.needed_until >= d.needed_from, {
  message: 'needed_until must be on or after needed_from',
  path: ['needed_until'],
});

export const updateRequestSchema = z.object({
  quantity: z.coerce.number().int().min(1).max(1000).optional(),
  purpose: z.string().trim().max(1000).nullable().optional(),
  needed_from: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  needed_until: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
});

export const listRequestsSchema = z.object({
  status: z.enum(['pending', 'approved', 'rejected', 'out', 'returned', 'cancelled', 'overdue']).optional(),
  member_id: z.string().uuid().optional(),
  item_id: z.string().uuid().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const decideSchema = z.object({
  decision: z.enum(['approve', 'reject']),
  note: z.string().trim().max(500).optional(),
});

export const returnSchema = z.object({
  condition: z.enum(['good', 'damaged', 'partial']).default('good'),
  note: z.string().trim().max(500).optional(),
});

export const idParamSchema = z.object({
  id: z.string().uuid(),
});

export type CreateItemInput = z.infer<typeof createItemSchema>;
export type UpdateItemInput = z.infer<typeof updateItemSchema>;
export type ListItemsInput = z.infer<typeof listItemsSchema>;
export type CreateRequestInput = z.infer<typeof createRequestSchema>;
export type UpdateRequestInput = z.infer<typeof updateRequestSchema>;
export type ListRequestsInput = z.infer<typeof listRequestsSchema>;
export type DecideInput = z.infer<typeof decideSchema>;
export type ReturnInput = z.infer<typeof returnSchema>;