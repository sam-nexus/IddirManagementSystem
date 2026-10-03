import { pool, query } from '../../config/database';
import { BadRequestError, ConflictError, ForbiddenError, NotFoundError } from '../../utils/errors';
import { writeAudit } from '../../utils/audit';
import { sendSms } from '../../integrations/sms.client';
import { t } from '../../utils/i18n';
import type {
  CreateRequestInput,
  DecideInput,
  ListPayoutsInput,
  ListRequestsInput,
  PayoutInput,
  UpdateRequestInput,
} from './support.schemas';

interface Ctx {
  actorId: string;
  ip?: string;
  userAgent?: string;
  lang?: 'en' | 'om';
}

const COMMITTEE_ROLES = ['chairperson', 'secretary', 'treasurer', 'auditor'] as const;

// How many approvals before auto-approval. Majority of active committee.
async function getApprovalThreshold(): Promise<number> {
  const res = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM members
     WHERE status = 'active' AND role = ANY($1::member_role[])`,
    [COMMITTEE_ROLES]
  );
  const total = res.rows[0].c;
  // 1 if there is only 1 committee member, otherwise simple majority
  return Math.max(1, Math.floor(total / 2) + 1);
}

// =====================================================================
// CREATE REQUEST
// =====================================================================
export async function createRequest(input: CreateRequestInput, ctx: Ctx) {
  // If dependent_id given, make sure it belongs to the member
  if (input.dependent_id) {
    const dep = await query<{ id: string }>(
      `SELECT id FROM dependents WHERE id = $1 AND member_id = $2`,
      [input.dependent_id, ctx.actorId]
    );
    if (!dep.rows[0]) throw new BadRequestError('Dependent does not belong to you');
  }

  const rows = await query(
    `INSERT INTO support_requests
       (member_id, dependent_id, type, description, amount_requested, status, attachment_url)
     VALUES ($1, $2, $3, $4, $5, 'pending', $6)
     RETURNING id, member_id, dependent_id, type, description, amount_requested,
               amount_approved, status, attachment_url, created_at`,
    [
      ctx.actorId,
      input.dependent_id ?? null,
      input.type,
      input.description,
      input.amount_requested ?? null,
      input.attachment_url ?? null,
    ]
  );

  const request = rows.rows[0];

  await writeAudit(
    {
      action: 'SUPPORT_REQUEST_CREATED',
      entity: 'support_requests',
      entityId: request.id,
      details: { type: input.type, amount_requested: input.amount_requested ?? null },
    },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  // Notify committee via SMS (best-effort, doesn't block)
  notifyCommittee(
    `Odaa: New ${input.type} support request submitted by member ${ctx.actorId.slice(0, 8)}.`
  ).catch(() => {});

  return request;
}

// =====================================================================
// LIST
// =====================================================================
export async function listRequests(input: ListRequestsInput, actor: { id: string; role: string }) {
  const isCommittee = COMMITTEE_ROLES.includes(actor.role as any);
  const where: string[] = [];
  const params: unknown[] = [];
  let i = 1;

  // Non-committee: see only their own
  if (!isCommittee) {
    where.push(`r.member_id = $${i}`);
    params.push(actor.id);
    i++;
  } else if (input.member_id) {
    where.push(`r.member_id = $${i}`);
    params.push(input.member_id);
    i++;
  }

  if (input.status) { where.push(`r.status = $${i}`); params.push(input.status); i++; }
  if (input.type)   { where.push(`r.type = $${i}`);   params.push(input.type);   i++; }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM support_requests r ${whereSql}`,
    params
  );

  const rows = await query(
    `SELECT r.id, r.member_id, m.member_no, m.first_name, m.last_name, m.phone,
            r.dependent_id, d.full_name AS dependent_name,
            r.type, r.description, r.amount_requested, r.amount_approved,
            r.status, r.attachment_url, r.created_at, r.updated_at
     FROM support_requests r
     JOIN members m ON m.id = r.member_id
     LEFT JOIN dependents d ON d.id = r.dependent_id
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
            d.full_name AS dependent_name
     FROM support_requests r
     JOIN members m ON m.id = r.member_id
     LEFT JOIN dependents d ON d.id = r.dependent_id
     WHERE r.id = $1`,
    [id]
  );
  const request = rows.rows[0];
  if (!request) throw new NotFoundError('Support request not found');

  const isCommittee = COMMITTEE_ROLES.includes(actor.role as any);
  if (!isCommittee && request.member_id !== actor.id) {
    throw new ForbiddenError('You can only view your own requests');
  }

  // Include approvals
  const approvals = await query(
    `SELECT a.id, a.approver_id, a.decision, a.comment, a.decided_at,
            m.first_name, m.last_name, m.role
     FROM support_approvals a
     JOIN members m ON m.id = a.approver_id
     WHERE a.request_id = $1
     ORDER BY a.decided_at ASC`,
    [id]
  );

  const payout = await query(
    `SELECT id, amount, paid_on, method, reference, recorded_by, created_at
     FROM payouts WHERE request_id = $1`,
    [id]
  );

  return {
    ...request,
    approvals: approvals.rows,
    payout: payout.rows[0] ?? null,
  };
}

// =====================================================================
// UPDATE (owner, only while pending)
// =====================================================================
export async function updateRequest(id: string, input: UpdateRequestInput, ctx: Ctx) {
  const existing = await query<{ id: string; member_id: string; status: string }>(
    `SELECT id, member_id, status FROM support_requests WHERE id = $1`,
    [id]
  );
  const row = existing.rows[0];
  if (!row) throw new NotFoundError('Support request not found');

  if (row.member_id !== ctx.actorId) {
    throw new ForbiddenError('You can only edit your own requests');
  }
  if (row.status !== 'pending') {
    throw new ConflictError('Cannot edit a request that is already under review');
  }

  const fields: string[] = [];
  const values: unknown[] = [];
  let i = 1;
  for (const k of ['description', 'amount_requested', 'attachment_url'] as const) {
    if ((input as any)[k] !== undefined) {
      fields.push(`${k} = $${i}`);
      values.push((input as any)[k]);
      i++;
    }
  }
  if (fields.length === 0) return getRequest(id, { id: ctx.actorId, role: 'member' });

  values.push(id);
  const rows = await query(
    `UPDATE support_requests SET ${fields.join(', ')} WHERE id = $${i}
     RETURNING id, member_id, type, description, amount_requested, amount_approved, status, attachment_url, updated_at`,
    values
  );

  await writeAudit(
    { action: 'SUPPORT_REQUEST_UPDATED', entity: 'support_requests', entityId: id, details: input },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  return rows.rows[0];
}

// =====================================================================
// APPROVE / REJECT (one vote per committee member)
// =====================================================================
export async function decideRequest(id: string, input: DecideInput, ctx: Ctx) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Lock row
    const reqRes = await client.query<{
      id: string;
      member_id: string;
      status: string;
      amount_requested: string | null;
      amount_approved: string | null;
      type: string;
    }>(
      `SELECT id, member_id, status, amount_requested, amount_approved, type
       FROM support_requests WHERE id = $1 FOR UPDATE`,
      [id]
    );
    const request = reqRes.rows[0];
    if (!request) throw new NotFoundError('Support request not found');

    if (['paid', 'cancelled', 'rejected'].includes(request.status)) {
      throw new ConflictError(`Cannot vote on a request with status "${request.status}"`);
    }

    // Record vote (unique index prevents double-vote)
    try {
      await client.query(
        `INSERT INTO support_approvals (request_id, approver_id, decision, comment)
         VALUES ($1, $2, $3, $4)`,
        [id, ctx.actorId, input.decision, input.comment ?? null]
      );
    } catch (err: any) {
      if (err.code === '23505') {
        throw new ConflictError('You already voted on this request');
      }
      throw err;
    }

    // Count votes
    const votes = await client.query<{ approve: number; reject: number }>(
      `SELECT
         COUNT(*) FILTER (WHERE decision = 'approve')::int AS approve,
         COUNT(*) FILTER (WHERE decision = 'reject')::int  AS reject
       FROM support_approvals WHERE request_id = $1`,
      [id]
    );
    const { approve, reject } = votes.rows[0];

    const threshold = await getApprovalThreshold();

    let newStatus = request.status;
    let approvedAmount = request.amount_approved;

    if (input.decision === 'reject' && reject >= threshold) {
      newStatus = 'rejected';
    } else if (input.decision === 'approve' && approve >= threshold) {
      newStatus = 'approved';
      approvedAmount = request.amount_requested;
    } else if (approve + reject > 0 && request.status === 'pending') {
      newStatus = 'under_review';
    }

    if (newStatus !== request.status || approvedAmount !== request.amount_approved) {
      await client.query(
        `UPDATE support_requests
         SET status = $2, amount_approved = $3
         WHERE id = $1`,
        [id, newStatus, approvedAmount]
      );
    }

    await writeAudit(
      {
        action: input.decision === 'approve' ? 'SUPPORT_APPROVED' : 'SUPPORT_REJECTED',
        entity: 'support_requests',
        entityId: id,
        details: { decision: input.decision, approve, reject, threshold, newStatus, comment: input.comment ?? null },
      },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    await client.query('COMMIT');

    // Notify the member if the decision changed
    if (newStatus !== request.status) {
      notifyMember(request.member_id, `Odaa: Your support request is now ${newStatus}.`).catch(() => {});
    }

    return { id, status: newStatus, approve, reject, threshold };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// RECORD PAYOUT (treasurer)
// =====================================================================
export async function recordPayout(id: string, input: PayoutInput, ctx: Ctx) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const reqRes = await client.query<{
      id: string;
      member_id: string;
      status: string;
      amount_approved: string | null;
    }>(
      `SELECT id, member_id, status, amount_approved FROM support_requests WHERE id = $1 FOR UPDATE`,
      [id]
    );
    const request = reqRes.rows[0];
    if (!request) throw new NotFoundError('Support request not found');
    if (request.status !== 'approved') {
      throw new ConflictError('Only approved requests can be paid out');
    }

    // Prevent double payout — the schema allows only one payout per request
    const existing = await client.query<{ id: string }>(
      `SELECT id FROM payouts WHERE request_id = $1`,
      [id]
    );
    if (existing.rows[0]) throw new ConflictError('A payout already exists for this request');

    // Insert payout (append-only)
    const payoutRes = await client.query(
      `INSERT INTO payouts (request_id, amount, paid_on, method, reference, recorded_by)
       VALUES ($1, $2, COALESCE($3::date, CURRENT_DATE), $4, $5, $6)
       RETURNING id, request_id, amount, paid_on, method, reference, recorded_by, created_at`,
      [
        id,
        input.amount,
        input.paid_on ?? null,
        input.method ?? 'cash',
        input.reference ?? null,
        ctx.actorId,
      ]
    );

    await client.query(
      `UPDATE support_requests SET status = 'paid' WHERE id = $1`,
      [id]
    );

    await writeAudit(
      {
        action: 'SUPPORT_PAYOUT_RECORDED',
        entity: 'payouts',
        entityId: payoutRes.rows[0].id,
        details: { request_id: id, amount: input.amount, method: input.method ?? 'cash' },
      },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    await client.query('COMMIT');

    notifyMember(request.member_id, `Odaa: Support payout of ${input.amount} ETB has been recorded.`).catch(() => {});

    return payoutRes.rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// LIST PAYOUTS
// =====================================================================
export async function listPayouts(input: ListPayoutsInput) {
  const where: string[] = [];
  const params: unknown[] = [];
  let i = 1;

  if (input.member_id) {
    where.push(`r.member_id = $${i}`);
    params.push(input.member_id);
    i++;
  }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM payouts p JOIN support_requests r ON r.id = p.request_id ${whereSql}`,
    params
  );

  const rows = await query(
    `SELECT p.id, p.request_id, p.amount, p.paid_on, p.method, p.reference,
            p.recorded_by, p.created_at,
            r.member_id, m.member_no, m.first_name, m.last_name,
            r.type, r.status AS request_status
     FROM payouts p
     JOIN support_requests r ON r.id = p.request_id
     JOIN members m ON m.id = r.member_id
     ${whereSql}
     ORDER BY p.created_at DESC
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

export async function getPayout(id: string) {
  const rows = await query(
    `SELECT p.*, r.member_id, r.type, r.status AS request_status, r.amount_approved,
            m.member_no, m.first_name, m.last_name, m.phone
     FROM payouts p
     JOIN support_requests r ON r.id = p.request_id
     JOIN members m ON m.id = r.member_id
     WHERE p.id = $1`,
    [id]
  );
  if (!rows.rows[0]) throw new NotFoundError('Payout not found');
  return rows.rows[0];
}

// =====================================================================
// Notifications (best-effort)
// =====================================================================
async function notifyCommittee(message: string): Promise<void> {
  const rows = await query<{ phone: string }>(
    `SELECT phone FROM members
     WHERE status = 'active' AND role = ANY($1::member_role[])`,
    [COMMITTEE_ROLES]
  );
  for (const r of rows.rows) {
    sendSms(r.phone, message).catch(() => {});
  }
}

async function notifyMember(memberId: string, message: string): Promise<void> {
  const rows = await query<{ phone: string }>(
    `SELECT phone FROM members WHERE id = $1`,
    [memberId]
  );
  if (rows.rows[0]) sendSms(rows.rows[0].phone, message).catch(() => {});
}