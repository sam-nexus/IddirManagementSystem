import { z } from 'zod';

export const registerDeviceSchema = z.object({
  fcm_token: z.string().min(10).max(500),
  platform: z.enum(['android', 'ios', 'web']),
});

export const listNotificationsSchema = z.object({
  unread_only: z.coerce.boolean().default(false),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const markReadSchema = z.object({
  // If omitted, mark all as read.
  ids: z.array(z.string().uuid()).max(500).optional(),
});

export const idParamSchema = z.object({
  id: z.string().uuid(),
});

export type RegisterDeviceInput = z.infer<typeof registerDeviceSchema>;
export type ListNotificationsInput = z.infer<typeof listNotificationsSchema>;
export type MarkReadInput = z.infer<typeof markReadSchema>;