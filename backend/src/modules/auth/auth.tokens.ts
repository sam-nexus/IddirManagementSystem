import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import { AccessTokenPayload } from '../../middleware/auth';

export function signAccessToken(payload: Omit<AccessTokenPayload, 'type'>): string {
  return jwt.sign({ ...payload, type: 'access' }, env.JWT_ACCESS_SECRET, {
    expiresIn: env.JWT_ACCESS_EXPIRES_IN,
  } as jwt.SignOptions);
}

/**
 * Opaque refresh token — random 48 bytes, hex.
 * We store only its SHA-256 hash in the DB.
 */
export function generateRefreshToken(): { token: string; hash: string } {
  const token = crypto.randomBytes(48).toString('hex');
  const hash = sha256(token);
  return { token, hash };
}

export function sha256(input: string): string {
  return crypto.createHash('sha256').update(input).digest('hex');
}

export function refreshExpiryDate(): Date {
  // Parse "30d", "15m", "12h" — enough for our env values
  const raw = env.JWT_REFRESH_EXPIRES_IN;
  const m = /^(\d+)([smhd])$/.exec(raw);
  const now = Date.now();
  if (!m) return new Date(now + 30 * 24 * 3600 * 1000);
  const n = Number(m[1]);
  const unit = m[2];
  const mult = unit === 's' ? 1000 : unit === 'm' ? 60_000 : unit === 'h' ? 3_600_000 : 86_400_000;
  return new Date(now + n * mult);
}