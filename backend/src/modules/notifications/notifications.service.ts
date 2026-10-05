import { query } from '../../config/database';
import { NotFoundError } from '../../utils/errors';
import { sendSms } from '../../integrations/sms.client';
import { sendPush } from './push.client';
import { t, Lang } from '../../utils/i18n';
import type {
  ListNotificationsInput,
  MarkReadInput,
  RegisterDeviceInput,
} from './notifications.schemas';

// =====================================================================
// DEVICE REGISTRATION
// =====================================================================
export async function registerDevice(input: RegisterDeviceInput, memberId: string) {
  // Upsert by (member_id, fcm_token) — avoid duplicate tokens
  await query(
    `INSERT INTO device_tokens (member_id, token, platform, last_seen_at)
     VALUES ($1, $2, $3, NOW())
     ON CONFLICT (token) DO UPDATE
       SET member_id = EXCLUDED.member_id,
           platform = EXCLUDED.platform,
           last_seen_at = NOW()`,
    [memberId, input.fcm_token, input.platform]
  );
  return { registered: true };
}

export async function unregisterDevice(token: string, memberId: string) {
  await query(
    `DELETE FROM device_tokens WHERE token = $1 AND member_id = $2`,
    [token, memberId]
  );
  return { removed: true };
}

// =====================================================================
// INBOX
// =====================================================================
export async function listMyNotifications(memberId: string, input: ListNotificationsInput) {
  const where = input.unread_only ? `AND is_read = FALSE` : '';
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM notifications WHERE member_id = $1 ${where}`,
    [memberId]
  );

  const rows = await query(
    `SELECT id, title, body, data, is_read, channel, sent_at, created_at
     FROM notifications
     WHERE member_id = $1 ${where}
     ORDER BY created_at DESC
     LIMIT $2 OFFSET $3`,
    [memberId, input.limit, offset]
  );

  return {
    items: rows.rows,
    pagination: {
      page: input.page,
      limit: input.limit,
      total: countRes.rows[0].c,
      pages: Math.max(1, Math.ceil(countRes.rows[0].c / input.limit)),
    },
  };
}

export async function markRead(memberId: string, input: MarkReadInput) {
  if (input.ids && input.ids.length > 0) {
    await query(
      `UPDATE notifications SET is_read = TRUE
       WHERE member_id = $1 AND id = ANY($2::uuid[]) AND is_read = FALSE`,
      [memberId, input.ids]
    );
  } else {
    await query(
      `UPDATE notifications SET is_read = TRUE
       WHERE member_id = $1 AND is_read = FALSE`,
      [memberId]
    );
  }
  return { updated: true };
}

export async function unreadCount(memberId: string) {
  const res = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM notifications WHERE member_id = $1 AND is_read = FALSE`,
    [memberId]
  );
  return { unread: res.rows[0].c };
}

// =====================================================================
// SEND (used by announcements, support, payments)
// =====================================================================
export interface NotifyInput {
  memberId: string;
  titleEn: string;
  titleOm: string;
  bodyEn: string;
  bodyOm: string;
  kind?: string;
  refId?: string | null;
  sendSms?: boolean;
  sendPush?: boolean;
}

/**
 * Creates an in-app notification and optionally dispatches SMS + push.
 * Never throws — dispatch failures are logged.
 */
export async function notifyMember(input: NotifyInput): Promise<void> {
  try {
    const member = await query<{ phone: string; language: Lang }>(
      `SELECT phone, language FROM members WHERE id = $1`,
      [input.memberId]
    );
    if (!member.rows[0]) return;

    const lang: Lang = member.rows[0].language === 'om' ? 'om' : 'en';
    const title = lang === 'om' ? input.titleOm : input.titleEn;
    const body = lang === 'om' ? input.bodyOm : input.bodyEn;

    // 1) In-app
    await query(
      `INSERT INTO notifications (member_id, title, body, kind, ref_id, channel, sent_at)
       VALUES ($1, $2, $3, $4, $5, 'in_app', NOW())`,
      [input.memberId, title, body, input.kind ?? 'general', input.refId ?? null]
    );

    // 2) SMS (optional)
    if (input.sendSms) {
      sendSms(member.rows[0].phone, `${title}\n${body}`).catch(() => {});
      await query(
        `INSERT INTO notifications (member_id, title, body, kind, ref_id, channel, sent_at)
         VALUES ($1, $2, $3, $4, $5, 'sms', NOW())`,
        [input.memberId, title, body, input.kind ?? 'general', input.refId ?? null]
      ).catch(() => {});
    }

    // 3) Push (optional) — one push per device
    if (input.sendPush) {
      const tokens = await query<{ token: string }>(
        `SELECT token FROM device_tokens WHERE member_id = $1`,
        [input.memberId]
      );
      for (const t of tokens.rows) {
        sendPush({ token: t.token, title, body, data: { kind: input.kind ?? 'general' } }).catch(() => {});
      }
    }
  } catch (err) {
    console.error('[notify] failed:', (err as Error).message);
  }
}

/**
 * Broadcast to all active members. Uses SMS/push flags.
 */
export async function broadcast(input: Omit<NotifyInput, 'memberId'>): Promise<void> {
  const members = await query<{ id: string }>(
    `SELECT id FROM members WHERE status = 'active'`
  );
  for (const m of members.rows) {
    notifyMember({ ...input, memberId: m.id }).catch(() => {});
  }
}