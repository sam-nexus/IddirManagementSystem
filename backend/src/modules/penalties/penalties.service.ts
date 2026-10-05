import { pool, query } from '../../config/database';
import { BadRequestError, ConflictError, NotFoundError } from '../../utils/errors';
import { writeAudit } from '../../utils/audit';
import { getPenaltyConfig } from '../settings/settings.service';
import { notifyMember } from '../notifications/notifications.service';
import type { ListPenaltiesInput, ManualPenaltyInput, WaivePenaltyInput } from './penalties.schemas';

interface Ctx {
  actorId: string;
  ip?: string;
  userAgent?: string;
}

// =====================================================================
// LIST
// =====================================================================
export async function listPenalties(
  input: ListPenaltiesInput,
  actor: { id: string; role: string }
) {
  const isCommittee = ['chairperson', 'secretary', 'treasurer', 'auditor'].includes(actor.role);
  const where: string[] = [];
  const params: unknown[] = [];
  let i = 1;

  if (!isCommittee) {
    where.push(`p.member_id = $${i++}`);
    params.push(actor.id);
  } else if (input.member_id) {
    where.push(`p.member_id = $${i++}`);
    params.push(input.member_id);
  }
  if (input.status) { where.push(`p.status = $${i++}`); params.push(input.status); }
  if (input.due_id) { where.push(`p.due_id = $${i++}`); params.push(input.due_id); }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM penalties p ${whereSql}`,
    params
  );

  const rows = await query(
    `SELECT p.id, p.member_id, m.member_no, m.first_name, m.last_name, m.phone,
            p.due_id, d.period AS due_period,
            p.amount, p.reason, p.status, p.created_by, p.created_at
     FROM penalties p
     JOIN members m ON m.id = p.member_id
     LEFT JOIN contribution_dues d ON d.id = p.due_id
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

// =====================================================================
// SUMMARY — my total unpaid penalties
// =====================================================================
export async function getMyPenaltySummary(memberId: string) {
  const rows = await query<{
    unpaid_total: string;
    unpaid_count: number;
    paid_total: string;
    waived_total: string;
  }>(
    `SELECT
       COALESCE(SUM(amount) FILTER (WHERE status = 'unpaid'), 0)::text AS unpaid_total,
       COUNT(*) FILTER (WHERE status = 'unpaid')::int                  AS unpaid_count,
       COALESCE(SUM(amount) FILTER (WHERE status = 'paid'), 0)::text   AS paid_total,
       COALESCE(SUM(amount) FILTER (WHERE status = 'waived'), 0)::text AS waived_total
     FROM penalties
     WHERE member_id = $1`,
    [memberId]
  );
  const r = rows.rows[0];
  return {
    unpaid_total: Number(r.unpaid_total),
    unpaid_count: r.unpaid_count,
    paid_total: Number(r.paid_total),
    waived_total: Number(r.waived_total),
  };
}

// =====================================================================
// GET ONE
// =====================================================================
export async function getPenalty(id: string, actor: { id: string; role: string }) {
  const rows = await query(
    `SELECT p.*, m.member_no, m.first_name, m.last_name, m.phone,
            d.period AS due_period
     FROM penalties p
     JOIN members m ON m.id = p.member_id
     LEFT JOIN contribution_dues d ON d.id = p.due_id
     WHERE p.id = $1`,
    [id]
  );
  const penalty = rows.rows[0];
  if (!penalty) throw new NotFoundError('Penalty not found');

  const isCommittee = ['chairperson', 'secretary', 'treasurer', 'auditor'].includes(actor.role);
  if (!isCommittee && penalty.member_id !== actor.id) {
    throw new NotFoundError('Penalty not found');
  }
  return penalty;
}

// =====================================================================
// MANUAL PENALTY (treasurer/chairperson)
// =====================================================================
export async function createManualPenalty(input: ManualPenaltyInput, ctx: Ctx) {
  // Sanity check the member exists
  const member = await query<{ id: string }>(
    `SELECT id FROM members WHERE id = $1`,
    [input.member_id]
  );
  if (!member.rows[0]) throw new NotFoundError('Member not found');

  // If due_id is given, ensure it belongs to the same member
  if (input.due_id) {
    const due = await query<{ id: string; member_id: string }>(
      `SELECT id, member_id FROM contribution_dues WHERE id = $1`,
      [input.due_id]
    );
    if (!due.rows[0]) throw new NotFoundError('Due not found');
    if (due.rows[0].member_id !== input.member_id) {
      throw new BadRequestError('Due does not belong to this member');
    }
  }

  const rows = await query(
    `INSERT INTO penalties (member_id, due_id, amount, reason, status, created_by)
     VALUES ($1, $2, $3, $4, 'unpaid', $5)
     RETURNING id, member_id, due_id, amount, reason, status, created_by, created_at`,
    [
      input.member_id,
      input.due_id ?? null,
      input.amount,
      input.reason,
      ctx.actorId,
    ]
  );

  await writeAudit(
    {
      action: 'PENALTY_MANUAL',
      entity: 'penalties',
      entityId: rows.rows[0].id,
      details: { member_id: input.member_id, amount: input.amount, reason: input.reason },
    },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  notifyMember({
    memberId: input.member_id,
    titleEn: 'New penalty',
    titleOm: 'Adabbii haaraa',
    bodyEn: `A penalty of ${input.amount} ETB was added: ${input.reason}`,
    bodyOm: `Adabbii ${input.amount} ETB dabalameera: ${input.reason}`,
    kind: 'penalty',
    refId: rows.rows[0].id,
  }).catch(() => {});

  return rows.rows[0];
}

// =====================================================================
// WAIVE
// =====================================================================
export async function waivePenalty(id: string, input: WaivePenaltyInput, ctx: Ctx) {
  const existing = await query<{ id: string; member_id: string; status: string; amount: string }>(
    `SELECT id, member_id, status, amount FROM penalties WHERE id = $1`,
    [id]
  );
  const row = existing.rows[0];
  if (!row) throw new NotFoundError('Penalty not found');
  if (row.status !== 'unpaid') {
    throw new ConflictError(`Cannot waive a penalty that is already ${row.status}`);
  }

  const rows = await query(
    `UPDATE penalties SET status = 'waived'
     WHERE id = $1
     RETURNING id, member_id, amount, status`,
    [id]
  );

  await writeAudit(
    {
      action: 'PENALTY_WAIVED',
      entity: 'penalties',
      entityId: id,
      details: { amount: row.amount, reason: input.reason, member_id: row.member_id },
    },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  notifyMember({
    memberId: row.member_id,
    titleEn: 'Penalty waived',
    titleOm: 'Adabbii dhiifameera',
    bodyEn: `Your penalty of ${row.amount} ETB has been waived.`,
    bodyOm: `Adabbii kee ${row.amount} ETB dhiifameera.`,
    kind: 'penalty',
    refId: id,
  }).catch(() => {});

  return rows.rows[0];
}

// =====================================================================
// MARK PAID (cash)
// =====================================================================
export async function markPenaltyPaid(id: string, ctx: Ctx) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const existing = await client.query<{
      id: string;
      member_id: string;
      status: string;
      amount: string;
    }>(
      `SELECT id, member_id, status, amount FROM penalties WHERE id = $1 FOR UPDATE`,
      [id]
    );
    const row = existing.rows[0];
    if (!row) throw new NotFoundError('Penalty not found');
    if (row.status !== 'unpaid') {
      throw new ConflictError(`Cannot mark a penalty as paid that is already ${row.status}`);
    }

    // Record a cash payment dedicated to this penalty
    const receiptNo = `RCT-${new Date().getFullYear()}-${String(Date.now()).slice(-6)}`;
    const payment = await client.query<{ id: string }>(
      `INSERT INTO payments
         (receipt_no, member_id, amount, currency, method, status, recorded_by, note, paid_at, verified_at)
       VALUES ($1, $2, $3, 'ETB', 'cash', 'success', $4, $5, NOW(), NOW())
       RETURNING id`,
      [receiptNo, row.member_id, row.amount, ctx.actorId, `Penalty payment for ${id.slice(0, 8)}`]
    );

    // Link the payment to the penalty
    await client.query(
      `INSERT INTO payment_penalty_allocations (payment_id, penalty_id, amount)
       VALUES ($1, $2, $3)
       ON CONFLICT (payment_id, penalty_id) DO NOTHING`,
      [payment.rows[0].id, id, row.amount]
    );

    await client.query(`UPDATE penalties SET status = 'paid' WHERE id = $1`, [id]);

    await writeAudit(
      {
        action: 'PENALTY_PAID',
        entity: 'penalties',
        entityId: id,
        details: { amount: row.amount, receipt_no: receiptNo, payment_id: payment.rows[0].id },
      },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    await client.query('COMMIT');

    notifyMember({
      memberId: row.member_id,
      titleEn: 'Penalty paid',
      titleOm: 'Adabbii kaffalameera',
      bodyEn: `Your penalty of ${row.amount} ETB has been recorded. Receipt ${receiptNo}.`,
      bodyOm: `Adabbii kee ${row.amount} ETB galmeeffameera. Nagahee ${receiptNo}.`,
      kind: 'penalty',
      refId: id,
    }).catch(() => {});

    return { id, status: 'paid', payment_id: payment.rows[0].id, receipt_no: receiptNo };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// AUTOMATION — called by the cron job (11E)
// =====================================================================
/**
 * For every overdue unpaid due past the grace period, insert a penalty
 * IF no penalty was created for that due in the last `frequency_days`.
 *
 * Returns { created, skipped }.
 */
export async function applyAutomaticPenalties(): Promise<{ created: number; skipped: number; enabled: boolean }> {
  const cfg = await getPenaltyConfig();
  if (!cfg.enabled) return { created: 0, skipped: 0, enabled: false };

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Find unpaid/partial dues past the grace period
    const dues = await client.query<{
      id: string;
      member_id: string;
      period: string;
      amount_due: string;
      amount_paid: string;
    }>(
      `SELECT d.id, d.member_id, d.period, d.amount_due, d.amount_paid
       FROM contribution_dues d
       JOIN members m ON m.id = d.member_id
       WHERE d.status IN ('unpaid','partial')
         AND m.status = 'active'
         AND (d.period + ($1::int || ' days')::interval) < NOW()
         AND NOT EXISTS (
           SELECT 1 FROM penalties p
           WHERE p.due_id = d.id
             AND p.created_at > NOW() - ($2::int || ' days')::interval
         )`,
      [cfg.grace_days, cfg.frequency_days]
    );

    let created = 0;
    for (const d of dues.rows) {
      const reason = `Late payment for ${String(d.period).slice(0, 7)} (overdue >${cfg.grace_days} days)`;
      await client.query(
        `INSERT INTO penalties (member_id, due_id, amount, reason, status, created_by)
         VALUES ($1, $2, $3, $4, 'unpaid', NULL)`,
        [d.member_id, d.id, cfg.amount, reason]
      );
      created++;
    }

    if (created > 0) {
      await writeAudit(
        {
          action: 'PENALTY_AUTO_APPLIED',
          entity: 'penalties',
          details: { created, grace_days: cfg.grace_days, amount: cfg.amount },
        },
        { actorId: null, client }
      );
    }

    await client.query('COMMIT');
    return { created, skipped: dues.rows.length - created, enabled: true };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}