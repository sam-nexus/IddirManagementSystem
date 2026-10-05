import { z } from 'zod';

export const keyParamSchema = z.object({
  key: z.enum(['mission', 'vision', 'bylaws', 'about', 'contact']),
});

const contactPersonSchema = z.object({
  name: z.string().trim().min(1).max(150),
  role: z.enum(['chairperson', 'secretary', 'treasurer', 'auditor', 'member']),
  phone: z.string().trim().min(7).max(20),
  email: z.string().email().optional(),
});

export const updateOrganizationSchema = z.object({
  title_en: z.string().trim().max(200).optional(),
  title_om: z.string().trim().max(200).optional(),
  content_en: z.string().trim().max(20000).optional(),
  content_om: z.string().trim().max(20000).optional(),
  // Only used when key === 'contact'; array of { name, role, phone, email? }
  metadata: z.array(contactPersonSchema).max(20).optional().nullable(),
});

export type UpdateOrganizationInput = z.infer<typeof updateOrganizationSchema>;