import { createApp } from './app';
import { env } from './config/env';
import { closePool } from './config/database';

import { pool } from './config/database';


async function main(): Promise<void> {

   pool.query('SELECT 1').then(
    () => console.log('[db] pool warm'),
    (e) => console.warn('[db] warmup failed:', e.message)
  );

  const app = createApp();

  const server = app.listen(env.PORT, () => {
    console.log(`🚀 Odaa API listening on http://localhost:${env.PORT}  [${env.NODE_ENV}]`);
  });

  const shutdown = async (signal: string) => {
    console.log(`\n[shutdown] received ${signal}, closing gracefully…`);
    server.close(async () => {
      await closePool().catch(() => {});
      process.exit(0);
    });
    setTimeout(() => process.exit(1), 10_000).unref();
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

main().catch((err) => {
  console.error('Fatal startup error:', err);
  process.exit(1);
});

// Keep the pooler warm — Supabase kills idle connections after ~5 min
setInterval(() => {
  pool.query('SELECT 1').catch((e) => console.warn('[db:keepalive]', e.message));
}, 4 * 60 * 1000).unref();