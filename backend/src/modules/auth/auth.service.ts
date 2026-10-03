import bcrypt from 'bcryptjs';
import { PoolClient } from 'pg';
import { pool, query } from '../../config/database';
import { env } from '../../config/env';
import { BadRequestError, ConflictError, ForbiddenError, NotFoundError, UnauthorizedError } from '../../utils/errors';
import { t } from '../../utils/i18n';
import { normalizeEthiopianPhone } from '../../utils/phone';
import { generateOtp, hashOtp, verifyOtp } from '../../utils/otp';
import { sendSms } from '../../integrations/sms.client';
import { writeAudit } from '../../utils/audit';
import {
  generateRefreshToken,
  refreshExpiryDate,
  sha256,
  signAccessToken,
} from './auth.tokens';
import type {
  ChangePinInput,
  LoginInput,
  RefreshInput,
  SendOtpInput,
  UpdateProfileInput,
  VerifyOtpInput,
} from './auth.schemas';

// ---------- Lockout policy ----------
const MAX_FAILED = 5;
const LOCK_MINUTES_FIRST = 15;
const LOCK_MINUTES_ESCALATED = 30;

interface MemberRow {
  id: string;
  member_no: string;
  first_name: string;
  last_name: string;
  phone: string;
  role: 'member' | 'chairperson' | 'secretary' | 'treasurer' | 'auditor';
  status: 'active' | 'suspended' | 'inactive';
  language: 'en' | 'om';
  pin_hash: string;
  must_change_pin: boolean;
  failed_attempts: number;
  lockout_count: number;
  locked_until: Date | null;
}

async function getMemberByPhone(phone: string): Promise<MemberRow | null> {
  const rows = await query<MemberRow>(
    `SELECT id, member_no, first_name, last_name, phone, role, status, language,
            pin_hash, must_change_pin, failed_attempts, lockout_count, locked_until
     FROM members WHERE phone = $1 LIMIT 1`,
    [phone]
  );
  return rows.rows[0] ?? null;
}

// =====================================================================
// LOGIN (phone + PIN)
// =====================================================================
export interface LoginResult {
  access_token: string;
  refresh_token: string;
  member: {
    id: string;
    member_no: string;
    first_name: string;
    last_name: string;
    phone: string;
    role: string;
    language: 'en' | 'om';
    must_change_pin: boolean;
  };
  device_trusted: boolean;
}

export async function login(
  input: LoginInput,
  ctx: { ip?: string; userAgent?: string }
): Promise<LoginResult> {
  const phone = normalizeEthiopianPhone(input.phone);
  if (!phone) throw new BadRequestError(t('member.invalidPhone', 'en'));

  const member = await getMemberByPhone(phone);

  // Log every attempt
  const logAttempt = async (success: boolean, reason: string) => {
    await query(
      `INSERT INTO login_attempts (phone, ip, device_id, success, reason)
       VALUES ($1, $2, $3, $4, $5)`,
      [phone, ctx.ip ?? null, input.device_id, success, reason]
    ).catch(() => {});
  };

  if (!member) {
    await logAttempt(false, 'unknown_phone');
    throw new UnauthorizedError(t('auth.pinInvalid', 'en'));
  }

  if (member.status === 'suspended') {
    await logAttempt(false, 'suspended');
    throw new ForbiddenError(t('auth.accountSuspended', member.language));
  }
  if (member.status === 'inactive') {
    await logAttempt(false, 'inactive');
    throw new ForbiddenError(t('auth.accountInactive', member.language));
  }

  if (member.locked_until && member.locked_until > new Date()) {
    const mins = Math.ceil((member.locked_until.getTime() - Date.now()) / 60_000);
    await logAttempt(false, 'locked');
    throw new ForbiddenError(t('auth.accountLocked', member.language, { minutes: mins }));
  }

  const pinOk = await bcrypt.compare(input.pin, member.pin_hash);

  if (!pinOk) {
    const failed = member.failed_attempts + 1;
    let locked_until: Date | null = null;
    let lockout_count = member.lockout_count;

    if (failed >= MAX_FAILED) {
      lockout_count += 1;
      const minutes = lockout_count === 1 ? LOCK_MINUTES_FIRST : LOCK_MINUTES_ESCALATED;
      locked_until = new Date(Date.now() + minutes * 60_000);
      await query(
        `UPDATE members
         SET failed_attempts = 0, lockout_count = $2, locked_until = $3, last_failed_at = NOW()
         WHERE id = $1`,
        [member.id, lockout_count, locked_until]
      );
    } else {
      await query(
        `UPDATE members SET failed_attempts = $2, last_failed_at = NOW() WHERE id = $1`,
        [member.id, failed]
      );
    }

    await logAttempt(false, 'wrong_pin');

    if (locked_until) {
      const minutes = lockout_count === 1 ? LOCK_MINUTES_FIRST : LOCK_MINUTES_ESCALATED;
      throw new ForbiddenError(t('auth.accountLocked', member.language, { minutes }));
    }
    throw new UnauthorizedError(t('auth.pinInvalid', member.language));
  }

  // Success — reset failures, handle device
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query(
      `UPDATE members
       SET failed_attempts = 0, locked_until = NULL, last_login_at = NOW()
       WHERE id = $1`,
      [member.id]
    );

    const device = await upsertDevice(client, {
      memberId: member.id,
      deviceId: input.device_id,
      deviceName: input.device_name,
      platform: input.platform,
      ip: ctx.ip,
    });

    // If device is new (not trusted), require OTP — but still issue a "pre-auth" token
    // Simplest UX for now: mark device as trusted on first login (change later if needed).
    await client.query(
      `UPDATE devices SET trusted = TRUE WHERE id = $1`,
      [device.id]
    );

    const access = signAccessToken({
      sub: member.id,
      role: member.role,
      status: member.status,
      lang: member.language,
      must_change_pin: member.must_change_pin,
      device_id: input.device_id,
    });

    const { token: refreshToken, hash: refreshHash } = generateRefreshToken();

    await client.query(
      `INSERT INTO refresh_tokens (member_id, device_id, token_hash, expires_at)
       VALUES ($1, $2, $3, $4)`,
      [member.id, device.id, refreshHash, refreshExpiryDate()]
    );

    await client.query('COMMIT');

    await logAttempt(true, 'ok');
    await writeAudit(
      { action: 'LOGIN_SUCCESS', entity: 'members', entityId: member.id, details: { device_id: input.device_id } },
      { actorId: member.id, ip: ctx.ip, userAgent: ctx.userAgent }
    );

    return {
      access_token: access,
      refresh_token: refreshToken,
      member: {
        id: member.id,
        member_no: member.member_no,
        first_name: member.first_name,
        last_name: member.last_name,
        phone: member.phone,
        role: member.role,
        language: member.language,
        must_change_pin: member.must_change_pin,
      },
      device_trusted: true,
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// OTP: send (for new_device or pin_reset)
// =====================================================================
export async function sendOtp(input: SendOtpInput): Promise<{ sent: boolean }> {
  const phone = normalizeEthiopianPhone(input.phone);
  if (!phone) throw new BadRequestError(t('member.invalidPhone', 'en'));

  const member = await getMemberByPhone(phone);
  if (!member) throw new NotFoundError(t('member.notFound', 'en'));

  if (member.status !== 'active') {
    throw new ForbiddenError(t('auth.accountSuspended', member.language));
  }

  const code = generateOtp(env.OTP_LENGTH);
  const hash = await hashOtp(code);
  const expires = new Date(Date.now() + env.OTP_TTL_SECONDS * 1000);

  await query(
    `INSERT INTO otp_codes (member_id, device_id, code_hash, purpose, expires_at)
     VALUES ($1, $2, $3, $4, $5)`,
    [member.id, input.device_id, hash, input.purpose, expires]
  );

  const message = t('auth.otpMessage', member.language, {
    code,
    minutes: Math.round(env.OTP_TTL_SECONDS / 60),
  });
  await sendSms(phone, message);

  return { sent: true };
}

// =====================================================================
// OTP: verify
// =====================================================================
export interface VerifyOtpResult {
  verified: boolean;
  // If purpose was pin_reset, we don't log in; caller must log in with the new PIN.
}

export async function verifyOtpCode(input: VerifyOtpInput): Promise<VerifyOtpResult> {
  const phone = normalizeEthiopianPhone(input.phone);
  if (!phone) throw new BadRequestError(t('member.invalidPhone', 'en'));

  const member = await getMemberByPhone(phone);
  if (!member) throw new NotFoundError(t('member.notFound', 'en'));

  const rows = await query<{
    id: string;
    code_hash: string;
    attempts: number;
    expires_at: Date;
    used_at: Date | null;
  }>(
    `SELECT id, code_hash, attempts, expires_at, used_at
     FROM otp_codes
     WHERE member_id = $1 AND purpose = $2 AND device_id = $3
     ORDER BY created_at DESC
     LIMIT 1`,
    [member.id, input.purpose, input.device_id]
  );
  const otp = rows.rows[0];
  if (!otp) throw new BadRequestError(t('auth.otpInvalid', member.language));
  if (otp.used_at) throw new BadRequestError(t('auth.otpInvalid', member.language));
  if (otp.expires_at < new Date()) throw new BadRequestError(t('auth.otpInvalid', member.language));

  if (otp.attempts >= env.OTP_MAX_ATTEMPTS) {
    throw new BadRequestError(t('auth.otpTooMany', member.language));
  }

  const ok = await verifyOtp(input.code, otp.code_hash);
  if (!ok) {
    await query(`UPDATE otp_codes SET attempts = attempts + 1 WHERE id = $1`, [otp.id]);
    throw new BadRequestError(t('auth.otpInvalid', member.language));
  }

  // Mark used
  await query(`UPDATE otp_codes SET used_at = NOW() WHERE id = $1`, [otp.id]);

  if (input.purpose === 'pin_reset') {
    if (!input.new_pin) throw new BadRequestError('new_pin is required for pin_reset');
    const hash = await bcrypt.hash(input.new_pin, 10);
    await query(
      `UPDATE members SET pin_hash = $2, must_change_pin = FALSE, pin_changed_at = NOW(), failed_attempts = 0, locked_until = NULL WHERE id = $1`,
      [member.id, hash]
    );
    await writeAudit(
      { action: 'PIN_RESET', entity: 'members', entityId: member.id },
      { actorId: member.id }
    );
  } else if (input.purpose === 'new_device') {
    // Trust the device
    await query(
      `UPDATE devices SET trusted = TRUE, last_login_at = NOW()
       WHERE member_id = $1 AND device_id = $2`,
      [member.id, input.device_id]
    );
  }

  return { verified: true };
}

// =====================================================================
// REFRESH (rotation + reuse detection)
// =====================================================================
export async function refresh(input: RefreshInput, ctx: { ip?: string; userAgent?: string }) {
  const hash = sha256(input.refresh_token);

  const rows = await query<{
    id: string;
    member_id: string;
    device_id: string;
    family_id: string;
    expires_at: Date;
    revoked_at: Date | null;
    replaced_by: string | null;
  }>(
    `SELECT id, member_id, device_id, family_id, expires_at, revoked_at, replaced_by
     FROM refresh_tokens WHERE token_hash = $1 LIMIT 1`,
    [hash]
  );
  const tokenRow = rows.rows[0];

  if (!tokenRow) throw new UnauthorizedError(t('auth.tokenExpired', 'en'));

  // Reuse detection — if this token was already rotated, kill the whole family.
  if (tokenRow.revoked_at || tokenRow.replaced_by) {
    await query(
      `UPDATE refresh_tokens SET revoked_at = NOW()
       WHERE family_id = $1 AND revoked_at IS NULL`,
      [tokenRow.family_id]
    );
    await writeAudit(
      { action: 'REFRESH_REUSE_DETECTED', entity: 'refresh_tokens', entityId: tokenRow.id },
      { actorId: tokenRow.member_id, ip: ctx.ip, userAgent: ctx.userAgent }
    );
    throw new UnauthorizedError(t('auth.tokenExpired', 'en'));
  }

  if (tokenRow.expires_at < new Date()) {
    throw new UnauthorizedError(t('auth.tokenExpired', 'en'));
  }

  const member = await query<MemberRow>(
    `SELECT id, member_no, first_name, last_name, phone, role, status, language,
            pin_hash, must_change_pin, failed_attempts, lockout_count, locked_until
     FROM members WHERE id = $1`,
    [tokenRow.member_id]
  ).then((r) => r.rows[0]);

  if (!member) throw new UnauthorizedError(t('auth.tokenExpired', 'en'));

  const { token: newRefresh, hash: newHash } = generateRefreshToken();

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const inserted = await client.query<{ id: string }>(
      `INSERT INTO refresh_tokens (member_id, device_id, token_hash, family_id, expires_at)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id`,
      [member.id, tokenRow.device_id, newHash, tokenRow.family_id, refreshExpiryDate()]
    );

    await client.query(
      `UPDATE refresh_tokens SET revoked_at = NOW(), replaced_by = $2 WHERE id = $1`,
      [tokenRow.id, inserted.rows[0].id]
    );

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  const access = signAccessToken({
    sub: member.id,
    role: member.role,
    status: member.status,
    lang: member.language,
    must_change_pin: member.must_change_pin,
  });

  return { access_token: access, refresh_token: newRefresh };
}

// =====================================================================
// LOGOUT (revoke refresh token(s))
// =====================================================================
export async function logout(memberId: string, refreshToken?: string): Promise<void> {
  if (refreshToken) {
    const hash = sha256(refreshToken);
    await query(
      `UPDATE refresh_tokens SET revoked_at = NOW() WHERE token_hash = $1 AND member_id = $2 AND revoked_at IS NULL`,
      [hash, memberId]
    );
  } else {
    await query(
      `UPDATE refresh_tokens SET revoked_at = NOW() WHERE member_id = $1 AND revoked_at IS NULL`,
      [memberId]
    );
  }
  await writeAudit({ action: 'LOGOUT', entity: 'members', entityId: memberId }, { actorId: memberId });
}

// =====================================================================
// CHANGE PIN
// =====================================================================
export async function changePin(memberId: string, input: ChangePinInput): Promise<void> {
  const rows = await query<MemberRow>(
    `SELECT id, member_no, first_name, last_name, phone, role, status, language,
            pin_hash, must_change_pin, failed_attempts, lockout_count, locked_until
     FROM members WHERE id = $1`,
    [memberId]
  );
  const member = rows.rows[0];
  if (!member) throw new NotFoundError(t('member.notFound', 'en'));

  const ok = await bcrypt.compare(input.current_pin, member.pin_hash);
  if (!ok) throw new UnauthorizedError(t('auth.pinInvalid', member.language));

  const hash = await bcrypt.hash(input.new_pin, 10);
  await query(
    `UPDATE members SET pin_hash = $2, must_change_pin = FALSE, pin_changed_at = NOW() WHERE id = $1`,
    [member.id, hash]
  );

  await writeAudit({ action: 'PIN_CHANGED', entity: 'members', entityId: member.id }, { actorId: member.id });
}

// =====================================================================
// ME (fetch current profile)
// =====================================================================
export async function me(memberId: string) {
  const rows = await query(
    `SELECT id, member_no, first_name, last_name, phone, role, status, language,
            address, joined_at, must_change_pin, contribution_override
     FROM members WHERE id = $1`,
    [memberId]
  );
  const member = rows.rows[0];
  if (!member) throw new NotFoundError(t('member.notFound', 'en'));
  return member;
}

// =====================================================================
// UPDATE PROFILE
// =====================================================================
export async function updateProfile(memberId: string, input: UpdateProfileInput) {
  const fields: string[] = [];
  const values: unknown[] = [];
  let i = 1;

  const mapping: Record<string, string> = {
    first_name: 'first_name',
    last_name: 'last_name',
    language: 'language',
    address: 'address',
  };

  for (const [k, col] of Object.entries(mapping)) {
    if ((input as any)[k] !== undefined) {
      fields.push(`${col} = $${i}`);
      values.push((input as any)[k]);
      i++;
    }
  }

  if (fields.length === 0) return me(memberId);

  values.push(memberId);
  const rows = await query(
    `UPDATE members SET ${fields.join(', ')} WHERE id = $${i}
     RETURNING id, member_no, first_name, last_name, phone, role, status, language, address, joined_at, must_change_pin, contribution_override`,
    values
  );

  await writeAudit(
    { action: 'PROFILE_UPDATED', entity: 'members', entityId: memberId, details: input },
    { actorId: memberId }
  );
  return rows.rows[0];
}

// =====================================================================
// Helpers
// =====================================================================
async function upsertDevice(
  client: PoolClient,
  args: {
    memberId: string;
    deviceId: string;
    deviceName?: string;
    platform?: string;
    ip?: string;
  }
): Promise<{ id: string; trusted: boolean }> {
  const existing = await client.query<{ id: string; trusted: boolean; revoked_at: Date | null }>(
    `SELECT id, trusted, revoked_at FROM devices WHERE member_id = $1 AND device_id = $2`,
    [args.memberId, args.deviceId]
  );

  if (existing.rows[0]) {
    if (existing.rows[0].revoked_at) {
      throw new ConflictError(t('auth.deviceRevoked', 'en'));
    }
    await client.query(
      `UPDATE devices SET device_name = COALESCE($2, device_name),
                          platform = COALESCE($3, platform),
                          last_login_at = NOW(),
                          last_ip = $4
       WHERE id = $1`,
      [existing.rows[0].id, args.deviceName ?? null, args.platform ?? null, args.ip ?? null]
    );
    return { id: existing.rows[0].id, trusted: existing.rows[0].trusted };
  }

  const inserted = await client.query<{ id: string; trusted: boolean }>(
    `INSERT INTO devices (member_id, device_id, device_name, platform, last_login_at, last_ip)
     VALUES ($1, $2, $3, $4, NOW(), $5)
     RETURNING id, trusted`,
    [args.memberId, args.deviceId, args.deviceName ?? null, args.platform ?? null, args.ip ?? null]
  );

  return inserted.rows[0];
}