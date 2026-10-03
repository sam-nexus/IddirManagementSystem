import { PoolClient } from 'pg';
import { pool, query } from '../../config/database';
import { BadRequestError, ConflictError, NotFoundError } from '../../utils/errors';
import { t } from '../../utils/i18n';
import { writeAudit } from '../../utils/audit';
import { generateTxRef } from '../../utils/otp';
import { initializeTransaction, verifyTransaction } from '../../integrations/chapa.client';
import { env } from '../../config/env';
import { sendSms } from '../../integrations/sms.client';

interface Ctx {
  actorId: string;
  ip?: string;
  userAgent?: string;
  lang?: 'en' | 'om';
}

// =====================================================================
// CONTRIBUTION PLAN
// =====================================================================
export async function getCurrentPlan() {
  const rows = await query<{ id: string; amount: string; effective_from: string; note: string | null }>(
    `SELECT id, amount, effective_from, note
     FROM contribution_plans
     WHERE effective_from <= CURRENT_DATE
     ORDER BY effective_from DESC
     LIMIT 1`
  );
  if (!rows.rows[0]) throw new NotFoundError('No active contribution plan');
  return rows.rows[0];
}

async function getAmountForDate(client: PoolClient | null, date: string): Promise<number> {
  // TEMP DEBUG — remove after we find the issue
  const all = await query('SELECT id, amount, effective_from FROM contribution_plans ORDER BY effective_from DESC');
  console.log('[dues:debug] plans visible to backend:', JSON.stringify(all.rows, null, 2));
  console.log('[dues:debug] requested period:', date);
  console.log('[dues:debug] DB url host:', (() => {
    try { return new URL(process.env.DATABASE_URL || '').hostname; } catch { return '(invalid)'; }
  })());

  const sql = `
    SELECT amount FROM contribution_plans
    WHERE effective_from <= $1
    ORDER BY effective_from DESC LIMIT 1
  `;
  const res = client ? await client.query(sql, [date]) : await query(sql, [date]);
  if (!res.rows[0]) throw new NotFoundError('No contribution plan effective for ' + date);
  return Number(res.rows[0].amount);
}

// =====================================================================
// GENERATE MONTHLY DUES
// =====================================================================
export async function generateDues(period: string, ctx: Ctx) {
  // period is YYYY-MM-01
  const planAmount = await getAmountForDate(null, period);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Pull all active members
    const members = await client.query<{ id: string; contribution_override: string | null }>(
      `SELECT id, contribution_override FROM members WHERE status = 'active'`
    );

    let created = 0;
    let skipped = 0;

    for (const m of members.rows) {
      const amount = m.contribution_override !== null ? Number(m.contribution_override) : planAmount;

      const result = await client.query(
        `INSERT INTO contribution_dues (member_id, period, amount_due, amount_paid, status)
         VALUES ($1, $2, $3, 0, 'unpaid')
         ON CONFLICT (member_id, period) DO NOTHING
         RETURNING id`,
        [m.id, period, amount]
      );

      if (result.rows[0]) created++;
      else skipped++;
    }

    await writeAudit(
      { action: 'DUES_GENERATED', entity: 'contribution_dues', details: { period, created, skipped, planAmount } },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    await client.query('COMMIT');
    return { period, planAmount, created, skipped, total_members: members.rows.length };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// LIST DUES (admin view)
// =====================================================================
export async function listDues(input: { member_id?: string; period?: string; status?: string; page: number; limit: number }) {
  const where: string[] = [];
  const params: unknown[] = [];
  let i = 1;

  if (input.member_id) { where.push(`d.member_id = $${i}`); params.push(input.member_id); i++; }
  if (input.period)    { where.push(`d.period = $${i}`);    params.push(input.period);    i++; }
  if (input.status)    { where.push(`d.status = $${i}`);    params.push(input.status);    i++; }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM contribution_dues d ${whereSql}`, params
  );

  const rows = await query(
    `SELECT d.id, d.member_id, m.member_no, m.first_name, m.last_name, m.phone,
            d.period, d.amount_due, d.amount_paid, d.status, d.waived_by, d.waive_reason
     FROM contribution_dues d
     JOIN members m ON m.id = d.member_id
     ${whereSql}
     ORDER BY d.period DESC, m.member_no ASC
     LIMIT $${i} OFFSET $${i + 1}`,
    [...params, input.limit, offset]
  );

  return {
    items: rows.rows,
    pagination: { page: input.page, limit: input.limit, total: countRes.rows[0].c, pages: Math.max(1, Math.ceil(countRes.rows[0].c / input.limit)) },
  };
}

// =====================================================================
// MY DUES + BALANCE
// =====================================================================
export async function getMyDues(memberId: string, period?: string) {
  const where = ['d.member_id = $1'];
  const params: unknown[] = [memberId];
  let i = 2;
  if (period) { where.push(`d.period = $${i}`); params.push(period); i++; }

  const rows = await query(
    `SELECT d.id, d.period, d.amount_due, d.amount_paid, d.status
     FROM contribution_dues d
     WHERE ${where.join(' AND ')}
     ORDER BY d.period DESC`,
    params
  );

  const totals = await query<{ due: string; paid: string }>(
    `SELECT COALESCE(SUM(amount_due),0)::text AS due, COALESCE(SUM(amount_paid),0)::text AS paid
     FROM contribution_dues WHERE member_id = $1`,
    [memberId]
  );

  const due = Number(totals.rows[0].due);
  const paid = Number(totals.rows[0].paid);

  return {
    items: rows.rows,
    summary: {
      total_due: due,
      total_paid: paid,
      balance: Math.max(0, due - paid),
      unpaid_months: rows.rows.filter((r: any) => r.status === 'unpaid' || r.status === 'partial').length,
    },
  };
}

// =====================================================================
// PAY VIA CHAPA — INIT
// =====================================================================
export async function initChapaPayment(input: { member_id?: string; months: number, email?: string }, payerId: string, ctx: Ctx) {
  const memberId = input.member_id ?? payerId;
  const member = await query<{ id: string; first_name: string; last_name: string; phone: string }>(
    `SELECT id, first_name, last_name, phone FROM members WHERE id = $1`,
    [memberId]
  );
  if (!member.rows[0]) throw new NotFoundError(t('member.notFound', ctx.lang ?? 'en'));

  // Find oldest unpaid/partial dues
  const dues = await query<{ id: string; period: string; amount_due: string; amount_paid: string }>(
    `SELECT id, period, amount_due, amount_paid
     FROM contribution_dues
     WHERE member_id = $1 AND status IN ('unpaid','partial')
     ORDER BY period ASC
     LIMIT $2`,
    [memberId, input.months]
  );

  if (dues.rows.length === 0) {
    throw new BadRequestError('No outstanding dues for the selected months');
  }

  const total = dues.rows.reduce((s, d) => s + (Number(d.amount_due) - Number(d.amount_paid)), 0);
  if (total <= 0) throw new BadRequestError('Nothing to pay');

  const txRef = generateTxRef('odaa');

  // Create a pending payment row
  const payment = await query<{ id: string }>(
    `INSERT INTO payments (member_id, amount, currency, method, status, tx_ref)
     VALUES ($1, $2, $3, 'chapa', 'pending', $4)
     RETURNING id`,
    [memberId, total, env.CHAPA_CURRENCY, txRef]
  );

  const chapaRes = await initializeTransaction({
    amount: total,
    currency: env.CHAPA_CURRENCY,
    txRef,
    phone: member.rows[0].phone.replace(/^\+/, ''),
    firstName: member.rows[0].first_name,
    lastName: member.rows[0].last_name,
    email: `${member.rows[0].id.slice(0, 8)}@gmail.com`,
    description: `Odaa dues for ${dues.rows.map((d) => formatPeriod(d.period)).join(', ')}`,
  });

  if (!chapaRes.success || !chapaRes.checkoutUrl) {
  await query(`UPDATE payments SET status = 'failed', raw_response = $2 WHERE id = $1`, [
    payment.rows[0].id,
    JSON.stringify(chapaRes.raw ?? { error: chapaRes.error }),
  ]);

  const rawAny = chapaRes.raw as any;
  const msgField = rawAny?.message;

  // Chapa sometimes returns message as a string, sometimes as an object like:
  //   { email: ["validation.email"], callback_url: [...] }
  // Flatten it into one readable string.
  let chapaMessage: string;
  if (typeof msgField === 'string') {
    chapaMessage = msgField;
  } else if (msgField && typeof msgField === 'object') {
    chapaMessage = Object.entries(msgField)
      .map(([k, v]) => `${k}: ${Array.isArray(v) ? v.join(', ') : String(v)}`)
      .join('; ');
  } else if (typeof rawAny === 'string') {
    chapaMessage = rawAny;
  } else {
    chapaMessage = JSON.stringify(rawAny);
  }

  console.error('[chapa] init failed:', chapaMessage);
  throw new BadRequestError(`Chapa: ${chapaMessage}`);
}

  await query(
    `UPDATE payments SET raw_response = $2 WHERE id = $1`,
    [payment.rows[0].id, JSON.stringify(chapaRes.raw)]
  );

  await writeAudit(
    { action: 'PAYMENT_INITIATED', entity: 'payments', entityId: payment.rows[0].id, details: { memberId, total, txRef } },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  return {
    payment_id: payment.rows[0].id,
    tx_ref: txRef,
    amount: total,
    currency: env.CHAPA_CURRENCY,
    checkout_url: chapaRes.checkoutUrl,
  };
}


/**
 * Formats a period value (which pg returns as a Date for `date` columns)
 * as "YYYY-MM".
 */
function formatPeriod(p: Date | string): string {
  if (typeof p === 'string') return p.slice(0, 7);
  const y = p.getUTCFullYear();
  const m = String(p.getUTCMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

// =====================================================================
// PAY VIA CHAPA — VERIFY
// =====================================================================
export async function verifyChapaPayment(txRef: string, ctx: Ctx) {
  const payment = await query<{
    id: string;
    member_id: string;
    amount: string;
    currency: string;
    status: string;
    tx_ref: string;
  }>(
    `SELECT id, member_id, amount, currency, status, tx_ref FROM payments WHERE tx_ref = $1`,
    [txRef]
  );
  const row = payment.rows[0];
  if (!row) throw new NotFoundError(t('payment.notFound', ctx.lang ?? 'en'));

  if (row.status === 'success') {
    return { payment_id: row.id, status: 'success', already_verified: true };
  }

  const result = await verifyTransaction(txRef);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    if (!result.success) {
      await client.query(
        `UPDATE payments SET status = 'failed', raw_response = $2, verified_at = NOW() WHERE id = $1`,
        [row.id, JSON.stringify(result.raw ?? { error: result.error })]
      );
      await client.query('COMMIT');
      return { payment_id: row.id, status: 'failed', reason: result.error };
    }

    // Mark payment success
    const receiptNo = `RCT-${new Date().getFullYear()}-${String(Date.now()).slice(-6)}`;
    await client.query(
      `UPDATE payments
       SET status = 'success', chapa_ref = $2, verified_at = NOW(), paid_at = NOW(),
           receipt_no = $3, raw_response = $4
       WHERE id = $1`,
      [row.id, result.reference ?? null, receiptNo, JSON.stringify(result.raw)]
    );

    // Allocate amount to oldest unpaid/partial dues
    const dues = await client.query<{ id: string; amount_due: string; amount_paid: string }>(
      `SELECT id, amount_due, amount_paid
       FROM contribution_dues
       WHERE member_id = $1 AND status IN ('unpaid','partial')
       ORDER BY period ASC`,
      [row.member_id]
    );

    let remaining = Number(row.amount);
    for (const d of dues.rows) {
      if (remaining <= 0) break;
      const outstanding = Number(d.amount_due) - Number(d.amount_paid);
      const allocate = Math.min(remaining, outstanding);
      const newPaid = Number(d.amount_paid) + allocate;
      const newStatus = newPaid >= Number(d.amount_due) ? 'paid' : 'partial';

      await client.query(
        `INSERT INTO payment_allocations (payment_id, due_id, amount) VALUES ($1, $2, $3)
         ON CONFLICT (payment_id, due_id) DO UPDATE SET amount = payment_allocations.amount + EXCLUDED.amount`,
        [row.id, d.id, allocate]
      );

      await client.query(
        `UPDATE contribution_dues SET amount_paid = $2, status = $3 WHERE id = $1`,
        [d.id, newPaid, newStatus]
      );

      remaining -= allocate;
    }

    await writeAudit(
      {
        action: 'PAYMENT_VERIFIED',
        entity: 'payments',
        entityId: row.id,
        details: { txRef, amount: row.amount, receiptNo, chapaRef: result.reference },
      },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    // Get member phone + language for SMS
    const member = await client.query<{ phone: string; language: 'en' | 'om' }>(
      `SELECT phone, language FROM members WHERE id = $1`,
      [row.member_id]
    );

    await client.query('COMMIT');

    if (member.rows[0]) {
      const smsText = t('sms.paymentSuccess', member.rows[0].language, {
        amount: Number(row.amount).toFixed(2),
        currency: row.currency,
        receipt: receiptNo,
      });
      sendSms(member.rows[0].phone, smsText).catch(() => {});
    }

    return { payment_id: row.id, status: 'success', receipt_no: receiptNo };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// CASH PAYMENT (treasurer)
// =====================================================================
export async function recordCashPayment(input: { member_id: string; amount: number; note?: string; periods?: string[] }, ctx: Ctx) {
  const member = await query(`SELECT id FROM members WHERE id = $1`, [input.member_id]);
  if (!member.rows[0]) throw new NotFoundError(t('member.notFound', ctx.lang ?? 'en'));

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const receiptNo = `RCT-${new Date().getFullYear()}-${String(Date.now()).slice(-6)}`;

    const payment = await client.query<{ id: string }>(
      `INSERT INTO payments (receipt_no, member_id, amount, currency, method, status, recorded_by, note, paid_at, verified_at)
       VALUES ($1, $2, $3, $4, 'cash', 'success', $5, $6, NOW(), NOW())
       RETURNING id`,
      [receiptNo, input.member_id, input.amount, env.CHAPA_CURRENCY, ctx.actorId, input.note ?? null]
    );

    // Pick dues to allocate
    let dues;
    if (input.periods && input.periods.length > 0) {
      dues = await client.query(
        `SELECT id, amount_due, amount_paid FROM contribution_dues
         WHERE member_id = $1 AND period = ANY($2::date[]) AND status IN ('unpaid','partial')
         ORDER BY period ASC`,
        [input.member_id, input.periods]
      );
    } else {
      dues = await client.query(
        `SELECT id, amount_due, amount_paid FROM contribution_dues
         WHERE member_id = $1 AND status IN ('unpaid','partial')
         ORDER BY period ASC`,
        [input.member_id]
      );
    }

    let remaining = Number(input.amount);
    for (const d of dues.rows) {
      if (remaining <= 0) break;
      const outstanding = Number(d.amount_due) - Number(d.amount_paid);
      const allocate = Math.min(remaining, outstanding);
      const newPaid = Number(d.amount_paid) + allocate;
      const newStatus = newPaid >= Number(d.amount_due) ? 'paid' : 'partial';

      await client.query(
        `INSERT INTO payment_allocations (payment_id, due_id, amount) VALUES ($1, $2, $3)
         ON CONFLICT (payment_id, due_id) DO UPDATE SET amount = payment_allocations.amount + EXCLUDED.amount`,
        [payment.rows[0].id, d.id, allocate]
      );

      await client.query(
        `UPDATE contribution_dues SET amount_paid = $2, status = $3 WHERE id = $1`,
        [d.id, newPaid, newStatus]
      );

      remaining -= allocate;
    }

    await writeAudit(
      { action: 'CASH_PAYMENT_RECORDED', entity: 'payments', entityId: payment.rows[0].id, details: { memberId: input.member_id, amount: input.amount, receiptNo } },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    await client.query('COMMIT');

    return { payment_id: payment.rows[0].id, receipt_no: receiptNo, amount: input.amount };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// PAYMENTS LIST + RECEIPT
// =====================================================================
export async function listPayments(input: { member_id?: string; method?: string; status?: string; page: number; limit: number }) {
  const where: string[] = [];
  const params: unknown[] = [];
  let i = 1;

  if (input.member_id) { where.push(`p.member_id = $${i}`); params.push(input.member_id); i++; }
  if (input.method)    { where.push(`p.method = $${i}`);    params.push(input.method);    i++; }
  if (input.status)    { where.push(`p.status = $${i}`);    params.push(input.status);    i++; }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(`SELECT COUNT(*)::int AS c FROM payments p ${whereSql}`, params);

  const rows = await query(
    `SELECT p.id, p.receipt_no, p.member_id, m.member_no, m.first_name, m.last_name,
            p.amount, p.currency, p.method, p.status, p.tx_ref, p.chapa_ref,
            p.note, p.paid_at, p.verified_at, p.created_at
     FROM payments p
     JOIN members m ON m.id = p.member_id
     ${whereSql}
     ORDER BY p.created_at DESC
     LIMIT $${i} OFFSET $${i + 1}`,
    [...params, input.limit, offset]
  );

  return {
    items: rows.rows,
    pagination: { page: input.page, limit: input.limit, total: countRes.rows[0].c, pages: Math.max(1, Math.ceil(countRes.rows[0].c / input.limit)) },
  };
}

export async function getReceipt(paymentId: string) {
  const payment = await query(
    `SELECT p.*, m.member_no, m.first_name, m.last_name, m.phone
     FROM payments p JOIN members m ON m.id = p.member_id
     WHERE p.id = $1`,
    [paymentId]
  );
  if (!payment.rows[0]) throw new NotFoundError(t('payment.notFound', 'en'));

  const allocations = await query(
    `SELECT pa.amount, d.period, d.amount_due
     FROM payment_allocations pa
     JOIN contribution_dues d ON d.id = pa.due_id
     WHERE pa.payment_id = $1
     ORDER BY d.period ASC`,
    [paymentId]
  );

  return {
    payment: payment.rows[0],
    allocations: allocations.rows,
  };
}