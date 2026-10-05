import { pool, query } from '../../config/database';
import { BadRequestError, ConflictError, ForbiddenError, NotFoundError } from '../../utils/errors';
import { writeAudit } from '../../utils/audit';
import { notifyMember } from '../notifications/notifications.service';
import type {
  CreateRequestInput,
  DecideInput,
  ListRequestsInput,
  ReturnInput,
  UpdateRequestInput,
} from './equipment.schemas';

interface Ctx {
  actorId: string;
  role?: string;
  ip?: string;
  userAgent?: string;
}

const COMMITTEE_ROLES = ['chairperson', 'secretary', 'treasurer', 'auditor'];

// =====================================================================
// LIST
// =====================================================================
export async function listRequests(
  input: ListRequestsInput,
  actor: { id: string; role: string }
) {
  const isCommittee = COMMITTEE_ROLES.includes(actor.role);
  const where: string[] = [];
  const params: unknown[] = [];
  let i = 1;

  if (!isCommittee) {
    where.push(`r.member_id = $${i++}`);
    params.push(actor.id);
  } else if (input.member_id) {
    where.push(`r.member_id = $${i++}`);
    params.push(input.member_id);
  }
  if (input.status)  { where.push(`r.status = $${i++}`);  params.push(input.status); }
  if (input.item_id) { where.push(`r.item_id = $${i++}`); params.push(input.item_id); }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM equipment_requests r ${whereSql}`,
    params
  );

  const rows = await query(
    `SELECT r.id, r.member_id, m.member_no, m.first_name, m.last_name, m.phone,
            r.item_id, i.name_en AS item_name_en, i.name_om AS item_name_om,
            r.quantity, r.purpose, r.needed_from, r.needed_until, r.status,
            r.approved_by, r.approved_at, r.decided_note,
            r.handed_over_by, r.handed_over_at,
            r.returned_by, r.returned_at, r.return_condition,
            r.created_at, r.updated_at
     FROM equipment_requests r
     JOIN members m ON m.id = r.member_id
     JOIN equipment_items i ON i.id = r.item_id
     ${whereSql}
     ORDER BY r.created_at DESC
     LIMIT $${i} OFFSET $${i + 1}`,
    [...params, input.limit, offset]
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

// =====================================================================
// GET ONE
// =====================================================================
export async function getRequest(id: string, actor: { id: string; role: string }) {
  const rows = await query(
    `SELECT r.*, m.member_no, m.first_name, m.last_name, m.phone,
            i.name_en AS item_name_en, i.name_om AS item_name_om,
            i.quantity_total AS item_quantity_total,
            i.quantity_available AS item_quantity_available
     FROM equipment_requests r
     JOIN members m ON m.id = r.member_id
     JOIN equipment_items i ON i.id = r.item_id
     WHERE r.id = $1`,
    [id]
  );
  const request = rows.rows[0];
  if (!request) throw new NotFoundError('Equipment request not found');

  const isCommittee = COMMITTEE_ROLES.includes(actor.role);
  if (!isCommittee && request.member_id !== actor.id) {
    throw new ForbiddenError('You can only view your own equipment requests');
  }
  return request;
}

// =====================================================================
// CREATE
// =====================================================================
export async function createRequest(input: CreateRequestInput, ctx: Ctx) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const item = await client.query<{
      id: string;
      name_en: string;
      quantity_available: number;
      is_active: boolean;
    }>(
      `SELECT id, name_en, quantity_available, is_active FROM equipment_items WHERE id = $1 FOR UPDATE`,
      [input.item_id]
    );
    if (!item.rows[0]) throw new NotFoundError('Equipment item not found');
    if (!item.rows[0].is_active) throw new ConflictError('This item is not available for lending');
    if (input.quantity > item.rows[0].quantity_available) {
      throw new ConflictError(
        `Only ${item.rows[0].quantity_available} unit(s) available`
      );
    }

    const rows = await client.query(
      `INSERT INTO equipment_requests
         (member_id, item_id, quantity, purpose, needed_from, needed_until, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'pending')
       RETURNING id, member_id, item_id, quantity, purpose, needed_from, needed_until, status, created_at`,
      [
        ctx.actorId,
        input.item_id,
        input.quantity,
        input.purpose ?? null,
        input.needed_from,
        input.needed_until,
      ]
    );

    await writeAudit(
      {
        action: 'EQUIPMENT_REQUEST_CREATED',
        entity: 'equipment_requests',
        entityId: rows.rows[0].id,
        details: { item_id: input.item_id, quantity: input.quantity },
      },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    await client.query('COMMIT');

    notifyCommittee(`${item.rows[0].name_en} request from member`).catch(() => {});
    return rows.rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// UPDATE (owner, only while pending)
// =====================================================================
export async function updateRequest(id: string, input: UpdateRequestInput, ctx: Ctx) {
  const existing = await query<{
    id: string;
    member_id: string;
    status: string;
    item_id: string;
    needed_from: string;
    needed_until: string;
  }>(
    `SELECT id, member_id, status, item_id, needed_from, needed_until
     FROM equipment_requests WHERE id = $1`,
    [id]
  );
  const row = existing.rows[0];
  if (!row) throw new NotFoundError('Equipment request not found');
  if (row.member_id !== ctx.actorId) throw new ForbiddenError('Not your request');
  if (row.status !== 'pending') throw new ConflictError('Cannot edit after review started');

  const fields: string[] = [];
  const values: unknown[] = [];
  let i = 1;

  for (const k of ['quantity', 'purpose', 'needed_from', 'needed_until'] as const) {
    if ((input as any)[k] !== undefined) {
      fields.push(`${k} = $${i++}`);
      values.push((input as any)[k]);
    }
  }
  if (fields.length === 0) return getRequest(id, { id: ctx.actorId, role: 'member' });

  values.push(id);
  const rows = await query(
    `UPDATE equipment_requests SET ${fields.join(', ')}
     WHERE id = $${i}
     RETURNING id, member_id, item_id, quantity, purpose, needed_from, needed_until, status, updated_at`,
    values
  );

  await writeAudit(
    { action: 'EQUIPMENT_REQUEST_UPDATED', entity: 'equipment_requests', entityId: id, details: input },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );
  return rows.rows[0];
}

// =====================================================================
// CANCEL (owner)
// =====================================================================
export async function cancelRequest(id: string, ctx: Ctx) {
  const existing = await query<{ id: string; member_id: string; status: string }>(
    `SELECT id, member_id, status FROM equipment_requests WHERE id = $1`,
    [id]
  );
  const row = existing.rows[0];
  if (!row) throw new NotFoundError('Equipment request not found');
  if (row.member_id !== ctx.actorId) throw new ForbiddenError('Not your request');
  if (!['pending', 'approved'].includes(row.status)) {
    throw new ConflictError(`Cannot cancel a request in status "${row.status}"`);
  }

  const rows = await query(
    `UPDATE equipment_requests SET status = 'cancelled' WHERE id = $1
     RETURNING id, status, updated_at`,
    [id]
  );

  await writeAudit(
    { action: 'EQUIPMENT_REQUEST_CANCELLED', entity: 'equipment_requests', entityId: id },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );
  return rows.rows[0];
}

// =====================================================================
// DECIDE (committee)
// =====================================================================
export async function decideRequest(id: string, input: DecideInput, ctx: Ctx) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const req = await client.query<{
      id: string;
      member_id: string;
      item_id: string;
      quantity: number;
      status: string;
    }>(
      `SELECT id, member_id, item_id, quantity, status FROM equipment_requests WHERE id = $1 FOR UPDATE`,
      [id]
    );
    const request = req.rows[0];
    if (!request) throw new NotFoundError('Equipment request not found');
    if (request.status !== 'pending') {
      throw new ConflictError(`Cannot decide on a request in status "${request.status}"`);
    }

    if (input.decision === 'approve') {
      // Re-check availability at decision time
      const item = await client.query<{ quantity_available: number }>(
        `SELECT quantity_available FROM equipment_items WHERE id = $1 FOR UPDATE`,
        [request.item_id]
      );
      if (request.quantity > item.rows[0].quantity_available) {
        throw new ConflictError('Not enough units available to approve this request');
      }

      await client.query(
        `UPDATE equipment_requests
         SET status = 'approved', approved_by = $2, approved_at = NOW(), decided_note = $3
         WHERE id = $1`,
        [id, ctx.actorId, input.note ?? null]
      );
    } else {
      await client.query(
        `UPDATE equipment_requests
         SET status = 'rejected', approved_by = $2, approved_at = NOW(), decided_note = $3
         WHERE id = $1`,
        [id, ctx.actorId, input.note ?? null]
      );
    }

    await writeAudit(
      {
        action: input.decision === 'approve' ? 'EQUIPMENT_REQUEST_APPROVED' : 'EQUIPMENT_REQUEST_REJECTED',
        entity: 'equipment_requests',
        entityId: id,
        details: { note: input.note ?? null },
      },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    await client.query('COMMIT');

    notifyMember({
      memberId: request.member_id,
      titleEn: `Equipment request ${input.decision === 'approve' ? 'approved' : 'rejected'}`,
      titleOm: `Gaaffiin meeshaa ${input.decision === 'approve' ? 'mirkanaa\'e' : 'didame'}`,
      bodyEn: input.note ?? '',
      bodyOm: input.note ?? '',
      kind: 'equipment',
      refId: id,
    }).catch(() => {});

    return { id, status: input.decision === 'approve' ? 'approved' : 'rejected' };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// HANDOVER (item physically leaves the store)
// =====================================================================
export async function handover(id: string, ctx: Ctx) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const req = await client.query<{
      id: string;
      member_id: string;
      item_id: string;
      quantity: number;
      status: string;
    }>(
      `SELECT id, member_id, item_id, quantity, status FROM equipment_requests WHERE id = $1 FOR UPDATE`,
      [id]
    );
    const request = req.rows[0];
    if (!request) throw new NotFoundError('Equipment request not found');
    if (request.status !== 'approved') {
      throw new ConflictError('Only approved requests can be handed over');
    }

    const item = await client.query<{ quantity_available: number }>(
      `SELECT quantity_available FROM equipment_items WHERE id = $1 FOR UPDATE`,
      [request.item_id]
    );
    if (request.quantity > item.rows[0].quantity_available) {
      throw new ConflictError('Not enough units available to hand over');
    }

    // Decrement availability
    await client.query(
      `UPDATE equipment_items
       SET quantity_available = quantity_available - $2
       WHERE id = $1`,
      [request.item_id, request.quantity]
    );

    await client.query(
      `UPDATE equipment_requests
       SET status = 'out', handed_over_by = $2, handed_over_at = NOW()
       WHERE id = $1`,
      [id, ctx.actorId]
    );

    await writeAudit(
      {
        action: 'EQUIPMENT_HANDED_OVER',
        entity: 'equipment_requests',
        entityId: id,
        details: { item_id: request.item_id, quantity: request.quantity },
      },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    await client.query('COMMIT');
    return { id, status: 'out' };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// RETURN
// =====================================================================
export async function returnItem(id: string, input: ReturnInput, ctx: Ctx) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const req = await client.query<{
      id: string;
      member_id: string;
      item_id: string;
      quantity: number;
      status: string;
    }>(
      `SELECT id, member_id, item_id, quantity, status FROM equipment_requests WHERE id = $1 FOR UPDATE`,
      [id]
    );
    const request = req.rows[0];
    if (!request) throw new NotFoundError('Equipment request not found');
    if (!['out', 'overdue'].includes(request.status)) {
      throw new ConflictError('Only handed-over requests can be returned');
    }

    // Only add back what's actually returned (partial returns leave some outstanding)
    const returnQty = input.condition === 'partial'
      ? Math.max(1, Math.floor(request.quantity / 2))   // simple partial rule
      : request.quantity;

    await client.query(
      `UPDATE equipment_items
       SET quantity_available = LEAST(quantity_available + $2, quantity_total)
       WHERE id = $1`,
      [request.item_id, returnQty]
    );

    await client.query(
      `UPDATE equipment_requests
       SET status = 'returned',
           returned_by = $2,
           returned_at = NOW(),
           return_condition = $3,
           decided_note = COALESCE($4, decided_note)
       WHERE id = $1`,
      [id, ctx.actorId, input.condition, input.note ?? null]
    );

    await writeAudit(
      {
        action: 'EQUIPMENT_RETURNED',
        entity: 'equipment_requests',
        entityId: id,
        details: { condition: input.condition, returned_quantity: returnQty, note: input.note ?? null },
      },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    await client.query('COMMIT');

    notifyMember({
      memberId: request.member_id,
      titleEn: 'Equipment returned',
      titleOm: 'Meeshaan deebi\'eera',
      bodyEn: `Condition: ${input.condition}`,
      bodyOm: `Haala: ${input.condition}`,
      kind: 'equipment',
      refId: id,
    }).catch(() => {});

    return { id, status: 'returned', condition: input.condition };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// Helpers
// =====================================================================
async function notifyCommittee(message: string): Promise<void> {
  const rows = await query<{ phone: string }>(
    `SELECT phone FROM members
     WHERE status = 'active' AND role = ANY($1::member_role[])`,
    [COMMITTEE_ROLES]
  );
  const { sendSms } = await import('../../integrations/sms.client.js');
  for (const r of rows.rows) sendSms(r.phone, `Odaa: ${message}`).catch(() => {});
}