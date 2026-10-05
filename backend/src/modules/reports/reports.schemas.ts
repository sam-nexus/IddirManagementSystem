import { z } from 'zod';

export const publishReportSchema = z.object({
  title_en: z.string().trim().min(1).max(200),
  title_om: z.string().trim().min(1).max(200),
  period_start: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  period_end: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  summary: z.record(z.any()).optional(),
  file_url: z.string().url().max(500).optional(),
});

export const listReportsSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const financialsSchema = z.object({
  period_start: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  period_end: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

export const idParamSchema = z.object({
  id: z.string().uuid(),
});

export type PublishReportInput = z.infer<typeof publishReportSchema>;
export type ListReportsInput = z.infer<typeof listReportsSchema>;
export type FinancialsInput = z.infer<typeof financialsSchema>;