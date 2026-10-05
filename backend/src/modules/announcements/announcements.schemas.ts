import { z } from 'zod';

export const createAnnouncementSchema = z.object({
  title_en: z.string().trim().min(1).max(200),
  title_om: z.string().trim().min(1).max(200),
  body_en: z.string().trim().min(1).max(5000),
  body_om: z.string().trim().min(1).max(5000),
  send_push: z.boolean().default(true),
  send_sms: z.boolean().default(false),
  is_urgent: z.boolean().default(false),
});

export const updateAnnouncementSchema = createAnnouncementSchema.partial();

export const listAnnouncementsSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  only_published: z.coerce.boolean().default(true),
});

export const idParamSchema = z.object({
  id: z.string().uuid(),
});

export type CreateAnnouncementInput = z.infer<typeof createAnnouncementSchema>;
export type UpdateAnnouncementInput = z.infer<typeof updateAnnouncementSchema>;
export type ListAnnouncementsInput = z.infer<typeof listAnnouncementsSchema>;