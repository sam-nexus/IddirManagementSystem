import cron from 'node-cron';
import { pool, query } from '../config/database';
import { sendSms } from '../integrations/sms.client';
import { t } from '../utils/i18n';
import { applyAutomaticPenalties } from '../modules/penalties/penalties.service';

export function startJobs(): void {
  // 1) Monthly dues generation — 1st of every month at 02:00
  cron.schedule('0 2 1 * *', async () => {
    console.log('[jobs] running monthly dues generation');
    try {
      await generateMonthlyDues();
    } catch (err: any) {
      console.error('[jobs] dues generation failed:', err.message);
    }
  });

  // 2) Payment reminders — every day at 09:00
  cron.schedule('0 9 * * *', async () => {
    console.log('[jobs] running payment reminders');
    try {
      await sendPaymentReminders();
    } catch (err: any) {
      console.error('[jobs] reminders failed:', err.message);
    }
  });

  // 3) Automatic penalties — every day at 03:00
  cron.schedule('0 3 * * *', async () => {
    console.log('[jobs] running automatic penalties');
    try {
      const result = await applyAutomaticPenalties();
      if (!result.enabled) {
        console.log('[jobs] penalties disabled by settings — skipped');
      } else {
        console.log(`[jobs] penalties applied: ${result.created} created`);
      }
    } catch (err: any) {
      console.error('[jobs] penalties failed:', err.message);
    }
  });

  // 4) DB keep-alive — every 4 minutes
  cron.schedule('*/4 * * * *', () => {
    pool.query('SELECT 1').catch(() => {});
  });

  console.log('⏰ Scheduled jobs started');
}

// =====================================================================
// Monthly dues generation
// =====================================================================
async function generateMonthlyDues(): Promise<void> {
  const now = new Date();
  const period = `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, '0')}-01`;

  const plan = await query<{ amount: string }>(
    `SELECT amount FROM contribution_plans
     WHERE effective_from <= $1::date
     ORDER BY effective_from DESC LIMIT 1`,
    [period]
  );
  if (!plan.rows[0]) {
    console.warn('[jobs] no contribution plan for', period);
    return;
  }
  const planAmount = Number(plan.rows[0].amount);

  const members = await query<{ id: string; contribution_override: string | null }>(
    `SELECT id, contribution_override FROM members WHERE status = 'active'`
  );

  let created = 0;
  for (const m of members.rows) {
    const amount = m.contribution_override !== null ? Number(m.contribution_override) : planAmount;
    const res = await query(
      `INSERT INTO contribution_dues (member_id, period, amount_due, amount_paid, status)
       VALUES ($1, $2, $3, 0, 'unpaid')
       ON CONFLICT (member_id, period) DO NOTHING
       RETURNING id`,
      [m.id, period, amount]
    );
    if (res.rows[0]) created++;
  }
  console.log(`[jobs] dues generated for ${period}: ${created} rows`);
}

// =====================================================================
// Payment reminders
// =====================================================================
async function sendPaymentReminders(): Promise<void> {
  const now = new Date();
  const period = `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, '0')}-01`;

  const rows = await query<{
    member_id: string;
    phone: string;
    language: 'en' | 'om';
    first_name: string;
    amount_due: string;
    amount_paid: string;
  }>(
    `SELECT m.id AS member_id, m.phone, m.language, m.first_name,
            d.amount_due, d.amount_paid
     FROM contribution_dues d
     JOIN members m ON m.id = d.member_id
     WHERE d.period = $1::date AND d.status IN ('unpaid','partial') AND m.status = 'active'`,
    [period]
  );

  const month = String(now.getUTCMonth() + 1);
  const year = String(now.getUTCFullYear());

  for (const r of rows.rows) {
    const amount = (Number(r.amount_due) - Number(r.amount_paid)).toFixed(2);
    const msg = t('sms.duesReminder', r.language === 'om' ? 'om' : 'en', {
      amount,
      currency: 'ETB',
      month,
      year,
    });
    sendSms(r.phone, msg).catch(() => {});
  }
  console.log(`[jobs] reminders sent: ${rows.rows.length}`);
}

// =====================================================================
// Manual triggers (for testing)
// =====================================================================
export async function runDuesNow(): Promise<void> {
  await generateMonthlyDues();
}

export async function runRemindersNow(): Promise<void> {
  await sendPaymentReminders();
}

export async function runPenaltiesNow(): Promise<{ created: number; skipped: number; enabled: boolean }> {
  return await applyAutomaticPenalties();
}