import { query } from '../../config/database';
import { NotFoundError } from '../../utils/errors';
import { writeAudit } from '../../utils/audit';
import type { FinancialsInput, ListReportsInput, PublishReportInput } from './reports.schemas';

interface Ctx {
  actorId: string;
  ip?: string;
  userAgent?: string;
}

// =====================================================================
// FINANCIAL AGGREGATION (computed on the fly, then persisted to a report)
// =====================================================================
export async function computeFinancials(input: FinancialsInput) {
  const payments = await query<{ total: string; count: number }>(
    `SELECT COALESCE(SUM(amount),0)::text AS total, COUNT(*)::int AS count
     FROM payments
     WHERE status = 'success' AND paid_at >= $1::date AND paid_at < ($2::date + INTERVAL '1 day')`,
    [input.period_start, input.period_end]
  );

  const byMethod = await query<{ method: string; total: string; count: number }>(
    `SELECT method::text AS method, COALESCE(SUM(amount),0)::text AS total, COUNT(*)::int AS count
     FROM payments
     WHERE status = 'success' AND paid_at >= $1::date AND paid_at < ($2::date + INTERVAL '1 day')
     GROUP BY method`,
    [input.period_start, input.period_end]
  );

  const duesPaid = await query<{ total: string }>(
    `SELECT COALESCE(SUM(amount_paid),0)::text AS total
     FROM contribution_dues
     WHERE period >= $1::date AND period <= $2::date`,
    [input.period_start, input.period_end]
  );

  const duesExpected = await query<{ total: string }>(
    `SELECT COALESCE(SUM(amount_due),0)::text AS total
     FROM contribution_dues
     WHERE period >= $1::date AND period <= $2::date`,
    [input.period_start, input.period_end]
  );

  const expenses = await query<{ total: string; count: number }>(
    `SELECT COALESCE(SUM(amount),0)::text AS total, COUNT(*)::int AS count
     FROM expenses
     WHERE spent_on >= $1::date AND spent_on <= $2::date`,
    [input.period_start, input.period_end]
  );

  const payouts = await query<{ total: string; count: number }>(
    `SELECT COALESCE(SUM(amount),0)::text AS total, COUNT(*)::int AS count
     FROM payouts
     WHERE paid_on >= $1::date AND paid_on <= $2::date`,
    [input.period_start, input.period_end]
  );

  const income = Number(payments.rows[0].total);
  const expenseTotal = Number(expenses.rows[0].total) + Number(payouts.rows[0].total);

  return {
    period: { start: input.period_start, end: input.period_end },
    income: {
      total: income,
      count: payments.rows[0].count,
      by_method: byMethod.rows.map((r) => ({ method: r.method, total: Number(r.total), count: r.count })),
    },
    dues: {
      expected: Number(duesExpected.rows[0].total),
      paid: Number(duesPaid.rows[0].total),
      outstanding: Number(duesExpected.rows[0].total) - Number(duesPaid.rows[0].total),
    },
    expenses: {
      total: Number(expenses.rows[0].total),
      count: expenses.rows[0].count,
    },
    payouts: {
      total: Number(payouts.rows[0].total),
      count: payouts.rows[0].count,
    },
    balance: income - expenseTotal,
  };
}

// =====================================================================
// WHO PAID / WHO DIDN'T (per period)
// =====================================================================
export async function paidVsUnpaid(period: string) {
  const rows = await query<{
    member_id: string;
    member_no: string;
    first_name: string;
    last_name: string;
    phone: string;
    amount_due: string;
    amount_paid: string;
    status: string;
  }>(
    `SELECT d.member_id, m.member_no, m.first_name, m.last_name, m.phone,
            d.amount_due, d.amount_paid, d.status
     FROM contribution_dues d
     JOIN members m ON m.id = d.member_id
     WHERE d.period = $1::date
     ORDER BY m.member_no ASC`,
    [period]
  );

  const paid = rows.rows.filter((r) => r.status === 'paid');
  const partial = rows.rows.filter((r) => r.status === 'partial');
  const unpaid = rows.rows.filter((r) => r.status === 'unpaid');
  const waived = rows.rows.filter((r) => r.status === 'waived');

  return {
    period,
    summary: {
      total: rows.rows.length,
      paid: paid.length,
      partial: partial.length,
      unpaid: unpaid.length,
      waived: waived.length,
    },
    paid, partial, unpaid, waived,
  };
}

// =====================================================================
// PUBLISH REPORT
// =====================================================================
export async function publishReport(input: PublishReportInput, ctx: Ctx) {
  // If no summary provided, compute one
  let summary = input.summary;
  if (!summary) {
    summary = await computeFinancials({
      period_start: input.period_start,
      period_end: input.period_end,
    });
  }

  const rows = await query(
    `INSERT INTO published_reports
       (title_en, title_om, period_start, period_end, summary, file_url, published_by)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING id, title_en, title_om, period_start, period_end, summary, file_url, published_by, published_at`,
    [
      input.title_en,
      input.title_om,
      input.period_start,
      input.period_end,
      JSON.stringify(summary),
      input.file_url ?? null,
      ctx.actorId,
    ]
  );

  await writeAudit(
    { action: 'REPORT_PUBLISHED', entity: 'published_reports', entityId: rows.rows[0].id, details: { period_start: input.period_start, period_end: input.period_end } },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );
  return rows.rows[0];
}

export async function listReports(input: ListReportsInput) {
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM published_reports`
  );

  const rows = await query(
    `SELECT r.id, r.title_en, r.title_om, r.period_start, r.period_end,
            r.summary, r.file_url, r.published_at,
            m.first_name AS publisher_first_name, m.last_name AS publisher_last_name
     FROM published_reports r
     LEFT JOIN members m ON m.id = r.published_by
     ORDER BY r.published_at DESC
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

export async function getReport(id: string) {
  const rows = await query(
    `SELECT r.*, m.first_name AS publisher_first_name, m.last_name AS publisher_last_name
     FROM published_reports r
     LEFT JOIN members m ON m.id = r.published_by
     WHERE r.id = $1`,
    [id]
  );
  if (!rows.rows[0]) throw new NotFoundError('Report not found');
  return rows.rows[0];
}