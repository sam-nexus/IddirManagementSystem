import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const schema = z.object({
  // Server
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(4000),
  API_BASE_URL: z.string().url().default('http://localhost:4000'),

  // Database
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),

  // JWT
  JWT_ACCESS_SECRET: z.string().min(32, 'JWT_ACCESS_SECRET must be at least 32 chars'),
  JWT_REFRESH_SECRET: z.string().min(32, 'JWT_REFRESH_SECRET must be at least 32 chars'),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('30d'),

  // OTP
  OTP_LENGTH: z.coerce.number().default(6),
  OTP_TTL_SECONDS: z.coerce.number().default(300),
  OTP_MAX_ATTEMPTS: z.coerce.number().default(5),

  // SMS
  SMS_PROVIDER: z.enum(['console', 'afromessage']).default('console'),
  AFROMESSAGE_TOKEN: z.string().optional().default(''),
  AFROMESSAGE_IDENTIFIER_ID: z.string().optional().default(''),
  AFROMESSAGE_SENDER_NAME: z.string().optional().default('Odaa'),

  // Chapa
  CHAPA_SECRET_KEY: z.string().min(1, 'CHAPA_SECRET_KEY is required'),
  CHAPA_BASE_URL: z.string().url().default('https://api.chapa.co/v1'),
  CHAPA_CALLBACK_URL: z.string().default('odaa://payment/callback'),
  CHAPA_RETURN_URL: z.string().default('https://odaa.app/payment/return'),
  CHAPA_CURRENCY: z.string().default('ETB'),

  // App defaults
  DEFAULT_LANGUAGE: z.enum(['en', 'om']).default('om'),
  SUPPORTED_LANGUAGES: z.string().default('en,om'),
  DEFAULT_MONTHLY_DUES: z.coerce.number().default(100),
  DEFAULT_CURRENCY: z.string().default('ETB'),

  // Supabase Storage
  SUPABASE_URL: z.string().url().optional().or(z.literal('')),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional().default(''),
  SUPABASE_STORAGE_BUCKET: z.string().default('payment-proofs'),

  // Penalties
  PENALTY_ENABLED: z
    .union([z.boolean(), z.string()])
    .transform((v) => (typeof v === 'boolean' ? v : v.toLowerCase() === 'true'))
    .default(false),
  PENALTY_GRACE_DAYS: z.coerce.number().int().min(0).default(15),
  PENALTY_AMOUNT: z.coerce.number().min(0).default(20),
  PENALTY_FREQUENCY_DAYS: z.coerce.number().int().min(1).default(30),
});

const parsed = schema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Invalid environment configuration:');
  for (const issue of parsed.error.issues) {
    console.error(`   - ${issue.path.join('.')}: ${issue.message}`);
  }
  process.exit(1);
}

export const env = parsed.data;

export const isProd = env.NODE_ENV === 'production';
export const isDev = env.NODE_ENV === 'development';

export const supportedLanguages = env.SUPPORTED_LANGUAGES
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean) as Array<'en' | 'om'>;