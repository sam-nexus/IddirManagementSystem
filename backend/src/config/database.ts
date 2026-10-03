import dns from 'dns';
dns.setDefaultResultOrder('ipv4first');

import { Pool, PoolClient, QueryResult, QueryResultRow } from 'pg';
import { env, isProd } from './env';

export const pool = new Pool({
  connectionString: env.DATABASE_URL,
  max: 5,
  min: 1,
  idleTimeoutMillis: 15_000,
  connectionTimeoutMillis: 30_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10_000,
  ssl: { rejectUnauthorized: false },
});

// Log but don't crash on idle-client errors (Supabase occasionally drops them)
pool.on('error', (err) => {
  console.error('[db] idle client error:', err.message);
});

/**
 * Query with retry on transient errors (Supabase pooler occasionally drops
 * connections; this makes those transparent to callers).
 */
export async function query<T extends QueryResultRow = any>(
  text: string,
  params: any[] = [],
  attempt = 1
): Promise<QueryResult<T>> {
  const start = Date.now();
  try {
    const result = await pool.query<T>(text, params);
    const duration = Date.now() - start;
    if (!isProd && duration > 500) {
      console.warn(`[db] slow query (${duration}ms):`, text.slice(0, 100));
    }
    return result;
  } catch (err: any) {
    const transient =
      err.code === 'ECONNRESET' ||
      err.code === 'ETIMEDOUT' ||
      err.code === 'ECONNREFUSED' ||
      /Connection terminated|timeout|terminating connection/i.test(err.message ?? '');

    if (transient && attempt < 3) {
      const delay = 150 * attempt;      // 150ms, 300ms
      console.warn(`[db] transient error (attempt ${attempt}), retrying in ${delay}ms: ${err.message}`);
      await new Promise((r) => setTimeout(r, delay));
      return query<T>(text, params, attempt + 1);
    }
    console.error('[db] query error after retries:', err.message, '\nSQL:', text.slice(0, 200));
    throw err;
  }
}

export async function rows<T extends QueryResultRow = any>(
  text: string,
  params: any[] = []
): Promise<T[]> {
  const res = await query<T>(text, params);
  return res.rows;
}

export async function one<T extends QueryResultRow = any>(
  text: string,
  params: any[] = []
): Promise<T | null> {
  const res = await query<T>(text, params);
  return res.rows[0] ?? null;
}

export async function transaction<T>(
  fn: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

export async function pingDb(): Promise<boolean> {
  try {
    await pool.query('SELECT 1');
    return true;
  } catch (err: any) {
    console.error('[db:ping]', err.message);
    return false;
  }
}

export async function closePool(): Promise<void> {
  await pool.end();
}