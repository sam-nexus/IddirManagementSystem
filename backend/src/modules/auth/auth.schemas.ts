import { z } from 'zod';

const phoneSchema = z
  .string()
  .trim()
  .min(9, 'Phone too short')
  .max(20, 'Phone too long');

const pinSchema = z
  .string()
  .regex(/^\d{4,6}$/, 'PIN must be 4-6 digits');

export const loginSchema = z.object({
  phone: phoneSchema,
  pin: pinSchema,
  device_id: z.string().min(8).max(128),
  device_name: z.string().max(120).optional(),
  platform: z.enum(['android', 'ios', 'web']).default('android'),
});

export const sendOtpSchema = z.object({
  phone: phoneSchema,
  device_id: z.string().min(8).max(128),
  purpose: z.enum(['new_device', 'pin_reset']),
});

export const verifyOtpSchema = z.object({
  phone: phoneSchema,
  device_id: z.string().min(8).max(128),
  code: z.string().regex(/^\d{4,8}$/, 'Invalid code'),
  purpose: z.enum(['new_device', 'pin_reset']),
  // required only when purpose = pin_reset
  new_pin: pinSchema.optional(),
});

export const refreshSchema = z.object({
  refresh_token: z.string().min(20),
});

export const logoutSchema = z.object({
  refresh_token: z.string().min(20).optional(),
});

export const changePinSchema = z.object({
  current_pin: pinSchema,
  new_pin: pinSchema,
});

export const updateProfileSchema = z.object({
  first_name: z.string().min(1).max(80).optional(),
  last_name: z.string().min(1).max(80).optional(),
  language: z.enum(['en', 'om']).optional(),
  address: z.string().max(300).optional(),
});

export type LoginInput = z.infer<typeof loginSchema>;
export type SendOtpInput = z.infer<typeof sendOtpSchema>;
export type VerifyOtpInput = z.infer<typeof verifyOtpSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
export type ChangePinInput = z.infer<typeof changePinSchema>;
export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;