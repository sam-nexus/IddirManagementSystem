import { closePool, pool } from '../config/database';

(async () => {
  try {
    await pool.query('SELECT 1');
    console.log('✅ DB connection OK');
    await closePool();
    process.exit(0);
  } catch (err: any) {
    console.error('❌ DB connection FAILED');
    console.error('   message :', err.message);
    console.error('   code    :', err.code);
    console.error('   host    :', err.hostname ?? '(unknown)');
    await closePool().catch(() => {});
    process.exit(1);
  }
})();