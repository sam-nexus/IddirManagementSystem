import bcrypt from 'bcryptjs';
import { pool } from '../config/database';
import { normalizeEthiopianPhone } from '../utils/phone';

async function seed(): Promise<void> {
  const rawPhone = process.argv[2] ?? '0911223344';
  const firstName = process.argv[3] ?? 'Odaa';
  const lastName = process.argv[4] ?? 'Chairperson';
  const pin = process.argv[5] ?? '123456';

  const phone = normalizeEthiopianPhone(rawPhone);
  if (!phone) {
    console.error(`❌ Invalid Ethiopian phone: ${rawPhone}`);
    process.exit(1);
  }

  const hash = await bcrypt.hash(pin, 10);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1) Insert chairperson (or update pin if already exists)
    const res = await client.query(
      `
      INSERT INTO members
        (first_name, last_name, phone, role, status, language, pin_hash, must_change_pin)
      VALUES ($1, $2, $3, 'chairperson', 'active', 'en', $4, FALSE)
      ON CONFLICT (phone) DO UPDATE
        SET pin_hash = EXCLUDED.pin_hash,
            must_change_pin = FALSE,
            role = 'chairperson',
            status = 'active'
      RETURNING id, member_no, phone, first_name, last_name, role
      `,
      [firstName, lastName, phone, hash]
    );

    const member = res.rows[0];
    console.log('✅ Chairperson ready:');
    console.log(member);

    // 2) Seed default contribution plan if none exists
    const planRes = await client.query(
      `SELECT COUNT(*)::int AS c FROM contribution_plans`
    );
    if (planRes.rows[0].c === 0) {
      await client.query(
        `INSERT INTO contribution_plans (amount, effective_from, note)
         VALUES ($1, $2, $3)`,
        [100, new Date().toISOString().slice(0, 10), 'Initial monthly dues']
      );
      console.log('✅ Initial contribution plan inserted (100 ETB/month).');
    } else {
      console.log('ℹ️  contribution_plans already has rows — skipping.');
    }

    await client.query('COMMIT');
  } catch (err: any) {
    await client.query('ROLLBACK');
    console.error('❌ Seed failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }

  console.log(`\nLogin: phone=${phone}  PIN=${pin}`);
}

seed();