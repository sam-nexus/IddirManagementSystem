import { pool, query } from '../../config/database';
import { ConflictError, NotFoundError } from '../../utils/errors';
import { writeAudit } from '../../utils/audit';
import type {
  CreateMeetingInput,
  ListMeetingsInput,
  SaveMinutesInput,
  UpdateMeetingInput,
} from './meetings.schemas';

interface Ctx {
  actorId: string;
  ip?: string;
  userAgent?: string;
}

export async function createMeeting(input: CreateMeetingInput, ctx: Ctx) {
  const rows = await query(
    `INSERT INTO meetings
       (title_en, title_om, agenda_en, agenda_om, location, scheduled_at, created_by)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING id, title_en, title_om, agenda_en, agenda_om, location, scheduled_at, created_by, created_at`,
    [
      input.title_en,
      input.title_om,
      input.agenda_en ?? null,
      input.agenda_om ?? null,
      input.location ?? null,
      input.scheduled_at,
      ctx.actorId,
    ]
  );

  await writeAudit(
    { action: 'MEETING_CREATED', entity: 'meetings', entityId: rows.rows[0].id, details: { scheduled_at: input.scheduled_at } },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );
  return rows.rows[0];
}

export async function listMeetings(input: ListMeetingsInput) {
  const where = input.upcoming ? `WHERE m.scheduled_at >= NOW()` : '';
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM meetings m ${where}`
  );

  const rows = await query(
    `SELECT m.id, m.title_en, m.title_om, m.agenda_en, m.agenda_om,
            m.location, m.scheduled_at, m.created_by, m.created_at,
            (mm.id IS NOT NULL) AS has_minutes,
            mm.is_published AS minutes_published
     FROM meetings m
     LEFT JOIN meeting_minutes mm ON mm.meeting_id = m.id
     ${where}
     ORDER BY m.scheduled_at DESC
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

export async function getMeeting(id: string, actor: { id: string; role: string }) {
  const rows = await query(
    `SELECT m.*, mm.id AS minutes_id, mm.content_en AS minutes_en, mm.content_om AS minutes_om,
            mm.file_url AS minutes_file_url, mm.is_published AS minutes_published,
            mm.written_by AS minutes_written_by, mm.created_at AS minutes_created_at
     FROM meetings m
     LEFT JOIN meeting_minutes mm ON mm.meeting_id = m.id
     WHERE m.id = $1`,
    [id]
  );
  const meeting = rows.rows[0];
  if (!meeting) throw new NotFoundError('Meeting not found');

  const attendance = await query(
    `SELECT ma.member_id, ma.attended, mem.first_name, mem.last_name, mem.member_no
     FROM meeting_attendance ma
     JOIN members mem ON mem.id = ma.member_id
     WHERE ma.meeting_id = $1
     ORDER BY mem.member_no ASC`,
    [id]
  );

  const isCommittee = ['chairperson', 'secretary', 'treasurer', 'auditor'].includes(actor.role);
  const canSeeMinutes = isCommittee || meeting.minutes_published === true;

  return {
    ...meeting,
    minutes_en: canSeeMinutes ? meeting.minutes_en : null,
    minutes_om: canSeeMinutes ? meeting.minutes_om : null,
    minutes_file_url: canSeeMinutes ? meeting.minutes_file_url : null,
    attendance: attendance.rows,
  };
}

export async function updateMeeting(id: string, input: UpdateMeetingInput, ctx: Ctx) {
  const fields: string[] = [];
  const values: unknown[] = [];
  let i = 1;

  for (const k of ['title_en', 'title_om', 'agenda_en', 'agenda_om', 'location', 'scheduled_at'] as const) {
    if ((input as any)[k] !== undefined) {
      fields.push(`${k} = $${i}`);
      values.push((input as any)[k]);
      i++;
    }
  }
  if (fields.length === 0) return getMeeting(id, { id: ctx.actorId, role: 'member' });

  values.push(id);
  const rows = await query(
    `UPDATE meetings SET ${fields.join(', ')} WHERE id = $${i}
     RETURNING id, title_en, title_om, agenda_en, agenda_om, location, scheduled_at, updated_at`,
    values
  );
  if (!rows.rows[0]) throw new NotFoundError('Meeting not found');

  await writeAudit(
    { action: 'MEETING_UPDATED', entity: 'meetings', entityId: id, details: input },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );
  return rows.rows[0];
}

export async function deleteMeeting(id: string, ctx: Ctx) {
  const rows = await query(`DELETE FROM meetings WHERE id = $1 RETURNING id`, [id]);
  if (!rows.rows[0]) throw new NotFoundError('Meeting not found');

  await writeAudit(
    { action: 'MEETING_DELETED', entity: 'meetings', entityId: id },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );
}

export async function saveMinutes(meetingId: string, input: SaveMinutesInput, ctx: Ctx) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const existing = await client.query<{ id: string }>(
      `SELECT id FROM meeting_minutes WHERE meeting_id = $1`,
      [meetingId]
    );

    let result;
    if (existing.rows[0]) {
      result = await client.query(
        `UPDATE meeting_minutes
         SET content_en = COALESCE($2, content_en),
             content_om = COALESCE($3, content_om),
             file_url = COALESCE($4, file_url),
             is_published = $5
         WHERE meeting_id = $1
         RETURNING id, meeting_id, content_en, content_om, file_url, is_published, written_by, created_at, updated_at`,
        [meetingId, input.content_en ?? null, input.content_om ?? null, input.file_url ?? null, input.is_published]
      );
    } else {
      result = await client.query(
        `INSERT INTO meeting_minutes (meeting_id, content_en, content_om, file_url, is_published, written_by)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id, meeting_id, content_en, content_om, file_url, is_published, written_by, created_at, updated_at`,
        [meetingId, input.content_en ?? null, input.content_om ?? null, input.file_url ?? null, input.is_published, ctx.actorId]
      );
    }

    await writeAudit(
      { action: 'MEETING_MINUTES_SAVED', entity: 'meeting_minutes', entityId: result.rows[0].id, details: { meeting_id: meetingId, published: input.is_published } },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    await client.query('COMMIT');
    return result.rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

export async function setAttendance(meetingId: string, memberIds: string[], ctx: Ctx) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Wipe and reinsert for simplicity
    await client.query(`DELETE FROM meeting_attendance WHERE meeting_id = $1`, [meetingId]);
    for (const memberId of memberIds) {
      await client.query(
        `INSERT INTO meeting_attendance (meeting_id, member_id, attended)
         VALUES ($1, $2, TRUE)
         ON CONFLICT (meeting_id, member_id) DO UPDATE SET attended = TRUE`,
        [meetingId, memberId]
      );
    }

    await writeAudit(
      { action: 'MEETING_ATTENDANCE_SET', entity: 'meetings', entityId: meetingId, details: { count: memberIds.length } },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    await client.query('COMMIT');
    return { count: memberIds.length };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}