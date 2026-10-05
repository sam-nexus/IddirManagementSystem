import { pool, query } from '../../config/database';
import { BadRequestError, ConflictError, ForbiddenError, NotFoundError } from '../../utils/errors';
import { writeAudit } from '../../utils/audit';
import { t } from '../../utils/i18n';
import { uploadFile, signUrl } from '../../integrations/storage.client';
import { notifyMember } from '../notifications/notifications.service';
import { sendSms } from '../../integrations/sms.client';
import type { ListManualInput, RejectManualInput, SubmitManualInput } from './manual.schemas';

interface Ctx {
  actorId: string;
  role: string;
  ip?: string;
  userAgent?: string;
  lang?: 'en' | 'om';
}

const REVIEWER_ROLES = ['treasurer', 'chairperson'];

// =====================================================================
// SUBMIT (member uploads screenshot + amount + note)
// =====================================================================
export async function submitManualPayment(
  input: SubmitManualInput,
  file: { buffer: Buffer; mimetype: string; originalname: string; size: number },
  ctx: Ctx
) {
  // Validate file
  if (!file || !file.buffer) throw new BadRequestError('Screenshot file is required');

  const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'application/pdf'];
  if (!allowed.includes(file.mimetype)) {
    throw new BadRequestError(
      `Unsupported file type: ${file.mimetype}. Allowed: JPG, PNG, WEBP, HEIC, PDF`
    );
  }
  if (file.size > 5 * 1024 * 1024) {
    throw new BadRequestError('File too large (max 5 MB)');
  }

  const targetMemberId = input.member_id ?? ctx.actorId;

  // Only committee can submit on behalf of another member
  const isCommittee = REVIEWER_ROLES.includes(ctx.role) || ctx.role === 'secretary' || ctx.role === 'auditor';
  if (targetMemberId !== ctx.actorId && !isCommittee) {
    throw new ForbiddenError('You can only submit payments for yourself');
  }

  // Verify the member exists
  const member = await query<{ id: string; first_name: string; last_name: string }>(
    `SELECT id, first_name, last_name FROM members WHERE id = $1`,
    [targetMemberId]
  );
  if (!member.rows[0]) throw new NotFoundError('Member not found');

  // Upload proof to storage
  const uploaded = await uploadFile(
    `manual-payments/${targetMemberId}`,
    file.buffer,
    file.mimetype,
    file.originalname
  );

  // Create the payment row (pending)
  const rows = await query<{ id: string; receipt_no: string | null }>(
    `INSERT INTO payments
       (member_id, amount, currency, method, status, note, proof_url, proof_note, recorded_by)
     VALUES ($1, $2, 'ETB', 'manual', 'pending', $3, $4, $5, $6)
     RETURNING id, receipt_no`,
    [
      targetMemberId,
      input.amount,
      input.note ?? null,
      uploaded.path,                              // store just the path; sign later
      input.note ?? null,                         // redundant but keeps proof_note filled
      ctx.actorId,                                // who submitted
    ]
  );

  await writeAudit(
    {
      action: 'MANUAL_PAYMENT_SUBMITTED',
      entity: 'payments',
      entityId: rows.rows[0].id,
      details: {
        member_id: targetMemberId,
        amount: input.amount,
        submitted_by: ctx.actorId,
        proof_path: uploaded.path,
      },
    },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  // Notify the treasurer(s)
  notifyCommittee(
    `New manual payment of ${input.amount} ETB awaiting review from ${member.rows[0].first_name} ${member.rows[0].last_name}`
  ).catch(() => {});

  return {
    id: rows.rows[0].id,
    status: 'pending',
    amount: input.amount,
    proof_url: uploaded.signedUrl,
  };
}

// =====================================================================
// LIST PENDING / REVIEWED
// =====================================================================
export async function listManualPayments(input: ListManualInput, actor: { id: string; role: string }) {
  const isReviewer = REVIEWER_ROLES.includes(actor.role);
  const where: string[] = [`p.method = 'manual'`];
  const params: unknown[] = [];
  let i = 1;

  if (!isReviewer) {
    // Members see only their own manual payments
    where.push(`p.member_id = $${i++}`);
    params.push(actor.id);
  } else if (input.member_id) {
    where.push(`p.member_id = $${i++}`);
    params.push(input.member_id);
  }

  if (input.status) {
    where.push(`p.status = $${i++}`);
    params.push(input.status);
  }

  const whereSql = `WHERE ${where.join(' AND ')}`;
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM payments p ${whereSql}`,
    params
  );

  const rows = await query(
    `SELECT p.id, p.member_id, m.member_no, m.first_name, m.last_name, m.phone,
            p.amount, p.currency, p.method, p.status,
            p.proof_url AS proof_path, p.note, p.review_note,
            p.recorded_by, p.reviewed_by, p.reviewed_at,
            p.paid_at, p.verified_at, p.created_at
     FROM payments p
     JOIN members m ON m.id = p.member_id
     ${whereSql}
     ORDER BY p.created_at DESC
     LIMIT $${i} OFFSET $${i + 1}`,
    [...params, input.limit, offset]
  );

  // Sign proof URLs on the fly (short TTL for response)
  const items = await Promise.all(
    rows.rows.map(async (r: any) => {
      let proofUrl: string | null = null;
      if (r.proof_path) {
        try {
          proofUrl = await signUrl(r.proof_path, 3600); // 1 hour
        } catch {
          proofUrl = null;
        }
      }
      const { proof_path, ...rest } = r;
      return { ...rest, proof_url: proofUrl };
    })
  );

  return {
    items,
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
export async function getManualPayment(id: string, actor: { id: string; role: string }) {
  const rows = await query(
    `SELECT p.*, m.member_no, m.first_name, m.last_name, m.phone
     FROM payments p
     JOIN members m ON m.id = p.member_id
     WHERE p.id = $1 AND p.method = 'manual'`,
    [id]
  );
  const payment = rows.rows[0];
  if (!payment) throw new NotFoundError('Manual payment not found');

  const isReviewer = REVIEWER_ROLES.includes(actor.role);
  if (!isReviewer && payment.member_id !== actor.id) {
    throw new ForbiddenError('You can only view your own payments');
  }

  let proofUrl: string | null = null;
  if (payment.proof_url) {
    try { proofUrl = await signUrl(payment.proof_url, 3600); } catch { proofUrl = null; }
  }

  return { ...payment, proof_url: proofUrl };
}

// =====================================================================
// APPROVE (treasurer/chairperson) — allocates like verify
// =====================================================================
export async function approveManualPayment(id: string, ctx: Ctx) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const payRes = await client.query<{
      id: string;
      member_id: string;
      amount: string;
      status: string;
      method: string;
    }>(
      `SELECT id, member_id, amount, status, method
       FROM payments WHERE id = $1 FOR UPDATE`,
      [id]
    );
    const payment = payRes.rows[0];
    if (!payment) throw new NotFoundError('Manual payment not found');
    if (payment.method !== 'manual') throw new BadRequestError('Not a manual payment');
    if (payment.status !== 'pending') {
      throw new ConflictError(`Payment is already ${payment.status}`);
    }

    const receiptNo = `RCT-${new Date().getFullYear()}-${String(Date.now()).slice(-6)}`;

    await client.query(
      `UPDATE payments
       SET status = 'success',
           receipt_no = $2,
           paid_at = NOW(),
           verified_at = NOW(),
           reviewed_by = $3,
           reviewed_at = NOW()
       WHERE id = $1`,
      [id, receiptNo, ctx.actorId]
    );

    let remaining = Number(payment.amount);

    // ---- 1) Dues first (oldest) ----
    const dues = await client.query<{ id: string; period: string; amount_due: string; amount_paid: string }>(
      `SELECT id, period, amount_due, amount_paid
       FROM contribution_dues
       WHERE member_id = $1 AND status IN ('unpaid','partial')
       ORDER BY period ASC`,
      [payment.member_id]
    );

    const duesAllocated: Array<{ due_id: string; period: string; amount: number }> = [];
    for (const d of dues.rows) {
      if (remaining <= 0) break;
      const outstanding = Number(d.amount_due) - Number(d.amount_paid);
      const allocate = Math.min(remaining, outstanding);
      const newPaid = Number(d.amount_paid) + allocate;
      const newStatus = newPaid >= Number(d.amount_due) ? 'paid' : 'partial';

      await client.query(
        `INSERT INTO payment_allocations (payment_id, due_id, amount) VALUES ($1, $2, $3)
         ON CONFLICT (payment_id, due_id) DO UPDATE SET amount = payment_allocations.amount + EXCLUDED.amount`,
        [id, d.id, allocate]
      );
      await client.query(
        `UPDATE contribution_dues SET amount_paid = $2, status = $3 WHERE id = $1`,
        [d.id, newPaid, newStatus]
      );

      duesAllocated.push({ due_id: d.id, period: String(d.period).slice(0, 10), amount: allocate });
      remaining -= allocate;
    }

    // ---- 2) Penalties ----
    const penaltiesAllocated: Array<{ penalty_id: string; amount: number }> = [];
    if (remaining > 0) {
      const penalties = await client.query<{ id: string; amount: string }>(
        `SELECT id, amount FROM penalties
         WHERE member_id = $1 AND status = 'unpaid'
         ORDER BY created_at ASC`,
        [payment.member_id]
      );

      for (const p of penalties.rows) {
        if (remaining <= 0) break;
        const pAmount = Number(p.amount);
        const allocate = Math.min(remaining, pAmount);

        await client.query(
          `INSERT INTO payment_penalty_allocations (payment_id, penalty_id, amount)
           VALUES ($1, $2, $3)
           ON CONFLICT (payment_id, penalty_id) DO UPDATE
             SET amount = payment_penalty_allocations.amount + EXCLUDED.amount`,
          [id, p.id, allocate]
        );
        if (allocate >= pAmount) {
          await client.query(`UPDATE penalties SET status = 'paid' WHERE id = $1`, [p.id]);
        }

        penaltiesAllocated.push({ penalty_id: p.id, amount: allocate });
        remaining -= allocate;
      }
    }

    await writeAudit(
      {
        action: 'MANUAL_PAYMENT_APPROVED',
        entity: 'payments',
        entityId: id,
        details: { receipt_no: receiptNo, dues_allocated: duesAllocated, penalties_allocated: penaltiesAllocated, remaining },
      },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );

    const member = await client.query<{ phone: string; language: 'en' | 'om' }>(
      `SELECT phone, language FROM members WHERE id = $1`,
      [payment.member_id]
    );

    await client.query('COMMIT');

    if (member.rows[0]) {
      const lang = member.rows[0].language === 'om' ? 'om' : 'en';
      sendSms(
        member.rows[0].phone,
        t('sms.paymentSuccess', lang, {
          amount: Number(payment.amount).toFixed(2),
          currency: 'ETB',
          receipt: receiptNo,
        })
      ).catch(() => {});
    }

    notifyMember({
      memberId: payment.member_id,
      titleEn: 'Payment approved',
      titleOm: 'Kaffaltiin mirkanaa\'eera',
      bodyEn: `Your payment of ${payment.amount} ETB has been approved. Receipt ${receiptNo}.`,
      bodyOm: `Kaffaltiin kee ${payment.amount} ETB mirkanaa\'eera. Nagahee ${receiptNo}.`,
      kind: 'payment',
      refId: id,
    }).catch(() => {});

    return {
      id,
      status: 'success',
      receipt_no: receiptNo,
      allocated: { dues: duesAllocated, penalties: penaltiesAllocated, remaining },
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// REJECT
// =====================================================================
export async function rejectManualPayment(id: string, input: RejectManualInput, ctx: Ctx) {
  const rows = await query<{ id: string; member_id: string; status: string; method: string }>(
    `SELECT id, member_id, status, method FROM payments WHERE id = $1`,
    [id]
  );
  const payment = rows.rows[0];
  if (!payment) throw new NotFoundError('Manual payment not found');
  if (payment.method !== 'manual') throw new BadRequestError('Not a manual payment');
  if (payment.status !== 'pending') {
    throw new ConflictError(`Payment is already ${payment.status}`);
  }

  await query(
    `UPDATE payments
     SET status = 'failed',
         review_note = $2,
         reviewed_by = $3,
         reviewed_at = NOW()
     WHERE id = $1`,
    [id, input.reason, ctx.actorId]
  );

  await writeAudit(
    {
      action: 'MANUAL_PAYMENT_REJECTED',
      entity: 'payments',
      entityId: id,
      details: { reason: input.reason },
    },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  notifyMember({
    memberId: payment.member_id,
    titleEn: 'Payment rejected',
    titleOm: 'Kaffaltiin didameera',
    bodyEn: `Your manual payment submission was rejected: ${input.reason}`,
    bodyOm: `Galmeen kaffaltii harkaa kee didameera: ${input.reason}`,
    kind: 'payment',
    refId: id,
  }).catch(() => {});

  return { id, status: 'failed', review_note: input.reason };
}

// =====================================================================
// Helper
// =====================================================================
async function notifyCommittee(message: string): Promise<void> {
  const rows = await query<{ phone: string }>(
    `SELECT phone FROM members
     WHERE status = 'active' AND role = ANY($1::member_role[])`,
    [REVIEWER_ROLES]
  );
  for (const r of rows.rows) sendSms(r.phone, `Odaa: ${message}`).catch(() => {});
}