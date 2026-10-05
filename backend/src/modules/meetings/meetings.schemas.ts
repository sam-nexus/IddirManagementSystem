import { z } from 'zod';

export const createMeetingSchema = z.object({
  title_en: z.string().trim().min(1).max(200),
  title_om: z.string().trim().min(1).max(200),
  agenda_en: z.string().trim().max(5000).optional(),
  agenda_om: z.string().trim().max(5000).optional(),
  location: z.string().trim().max(200).optional(),
  scheduled_at: z.string().datetime({ offset: true }),
});

export const updateMeetingSchema = createMeetingSchema.partial();

export const listMeetingsSchema = z.object({
  upcoming: z.coerce.boolean().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const saveMinutesSchema = z.object({
  content_en: z.string().trim().max(20000).optional(),
  content_om: z.string().trim().max(20000).optional(),
  file_url: z.string().url().max(500).optional(),
  is_published: z.boolean().default(false),
});

export const attendanceSchema = z.object({
  member_ids: z.array(z.string().uuid()).max(500),
});

export const idParamSchema = z.object({
  id: z.string().uuid(),
});

export type CreateMeetingInput = z.infer<typeof createMeetingSchema>;
export type UpdateMeetingInput = z.infer<typeof updateMeetingSchema>;
export type SaveMinutesInput = z.infer<typeof saveMinutesSchema>;
export type ListMeetingsInput = z.infer<typeof listMeetingsSchema>;