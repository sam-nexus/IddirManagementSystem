import { z } from 'zod';

const phoneSchema = z.string().trim().min(9).max(20);
const pinSchema = z.string().regex(/^\d{4,6}$/, 'PIN must be 4-6 digits');

export const listMembersSchema = z.object({
  search: z.string().trim().max(80).optional(),
  role: z.enum(['member', 'chairperson', 'secretary', 'treasurer', 'auditor']).optional(),
  status: z.enum(['active', 'suspended', 'inactive']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const createMemberSchema = z.object({
  first_name: z.string().trim().min(1).max(80),
  last_name: z.string().trim().min(1).max(80),
  phone: phoneSchema,
  pin: pinSchema.optional(),
  role: z.enum(['member', 'chairperson', 'secretary', 'treasurer', 'auditor']).default('member'),
  language: z.enum(['en', 'om']).default('en'),
  address: z.string().trim().max(300).optional(),
  contribution_override: z.coerce.number().min(0).max(1_000_000).optional(),
});

export const updateMemberSchema = z.object({
  first_name: z.string().trim().min(1).max(80).optional(),
  last_name: z.string().trim().min(1).max(80).optional(),
  language: z.enum(['en', 'om']).optional(),
  address: z.string().trim().max(300).optional(),
  role: z.enum(['member', 'chairperson', 'secretary', 'treasurer', 'auditor']).optional(),
  contribution_override: z.coerce.number().min(0).max(1_000_000).nullable().optional(),
});

export const suspendMemberSchema = z.object({
  reason: z.string().trim().max(300).optional(),
});

export const memberIdParamSchema = z.object({
  id: z.string().uuid(),
});

// ---------- Dependents ----------
export const createDependentSchema = z.object({
  full_name: z.string().trim().min(1).max(150),
  relationship: z.enum(['spouse', 'child', 'parent', 'sibling', 'other']),
  date_of_birth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format: YYYY-MM-DD').optional(),
});

export const updateDependentSchema = z.object({
  full_name: z.string().trim().min(1).max(150).optional(),
  relationship: z.enum(['spouse', 'child', 'parent', 'sibling', 'other']).optional(),
  date_of_birth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).nullable().optional(),
  is_active: z.boolean().optional(),
});

export const dependentIdParamSchema = z.object({
  id: z.string().uuid(),
  depId: z.string().uuid(),
});

export type ListMembersInput = z.infer<typeof listMembersSchema>;
export type CreateMemberInput = z.infer<typeof createMemberSchema>;
export type UpdateMemberInput = z.infer<typeof updateMemberSchema>;
export type CreateDependentInput = z.infer<typeof createDependentSchema>;
export type UpdateDependentInput = z.infer<typeof updateDependentSchema>;