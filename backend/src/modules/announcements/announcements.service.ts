import { query } from '../../config/database';
import { NotFoundError } from '../../utils/errors';
import { writeAudit } from '../../utils/audit';
import { sendSms } from '../../integrations/sms.client';
import type {
  CreateAnnouncementInput,
  ListAnnouncementsInput,
  UpdateAnnouncementInput,
} from './announcements.schemas';

interface Ctx {
  actorId: string;
  ip?: string;
  userAgent?: string;
  lang?: 'en' | 'om';
}

export async function createAnnouncement(input: CreateAnnouncementInput, ctx: Ctx) {
  const rows = await query(
    `INSERT INTO announcements
       (title_en, title_om, body_en, body_om, send_push, send_sms, is_urgent, created_by, published_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
     RETURNING id, title_en, title_om, body_en, body_om, send_push, send_sms, is_urgent, created_by, published_at, created_at`,
    [
      input.title_en,
      input.title_om,
      input.body_en,
      input.body_om,
      input.send_push,
      input.send_sms,
      input.is_urgent,
      ctx.actorId,
    ]
  );
  const announcement = rows.rows[0];

  await writeAudit(
    {
      action: 'ANNOUNCEMENT_CREATED',
      entity: 'announcements',
      entityId: announcement.id,
      details: { is_urgent: input.is_urgent, send_sms: input.send_sms },
    },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  // SMS blast (best-effort, doesn't block)
  if (input.send_sms) {
    broadcastSms(
      `Odaa: ${input.title_en}\n${input.body_en.slice(0, 120)}`,
      `Odaa: ${input.title_om}\n${input.body_om.slice(0, 120)}`
    ).catch(() => {});
  }

  // (Push notifications via Firebase will be wired in Batch 10)

  return announcement;
}

export async function listAnnouncements(input: ListAnnouncementsInput) {
  const where = input.only_published ? `WHERE published_at IS NOT NULL` : '';
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM announcements ${where}`
  );

  const rows = await query(
    `SELECT a.id, a.title_en, a.title_om, a.body_en, a.body_om,
            a.send_push, a.send_sms, a.is_urgent, a.published_at, a.created_at,
            m.first_name AS author_first_name, m.last_name AS author_last_name
     FROM announcements a
     LEFT JOIN members m ON m.id = a.created_by
     ${where}
     ORDER BY a.published_at DESC NULLS LAST, a.created_at DESC
     LIMIT $1 OFFSET $2`,
    [input.limit, offset]
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

export async function getAnnouncement(id: string) {
  const rows = await query(
    `SELECT a.*, m.first_name AS author_first_name, m.last_name AS author_last_name
     FROM announcements a
     LEFT JOIN members m ON m.id = a.created_by
     WHERE a.id = $1`,
    [id]
  );
  if (!rows.rows[0]) throw new NotFoundError('Announcement not found');
  return rows.rows[0];
}

export async function updateAnnouncement(id: string, input: UpdateAnnouncementInput, ctx: Ctx) {
  const fields: string[] = [];
  const values: unknown[] = [];
  let i = 1;

  for (const k of ['title_en', 'title_om', 'body_en', 'body_om', 'send_push', 'send_sms', 'is_urgent'] as const) {
    if ((input as any)[k] !== undefined) {
      fields.push(`${k} = $${i}`);
      values.push((input as any)[k]);
      i++;
    }
  }
  if (fields.length === 0) return getAnnouncement(id);

  values.push(id);
  const rows = await query(
    `UPDATE announcements SET ${fields.join(', ')} WHERE id = $${i}
     RETURNING id, title_en, title_om, body_en, body_om, send_push, send_sms, is_urgent, published_at, created_at`,
    values
  );
  if (!rows.rows[0]) throw new NotFoundError('Announcement not found');

  await writeAudit(
    { action: 'ANNOUNCEMENT_UPDATED', entity: 'announcements', entityId: id, details: input },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );
  return rows.rows[0];
}

export async function deleteAnnouncement(id: string, ctx: Ctx) {
  const rows = await query(`DELETE FROM announcements WHERE id = $1 RETURNING id`, [id]);
  if (!rows.rows[0]) throw new NotFoundError('Announcement not found');

  await writeAudit(
    { action: 'ANNOUNCEMENT_DELETED', entity: 'announcements', entityId: id },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );
}

async function broadcastSms(en: string, om: string) {
  const members = await query<{ phone: string; language: 'en' | 'om' }>(
    `SELECT phone, language FROM members WHERE status = 'active'`
  );
  for (const m of members.rows) {
    sendSms(m.phone, m.language === 'om' ? om : en).catch(() => {});
  }
}