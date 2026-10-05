import { query } from '../../config/database';
import { NotFoundError } from '../../utils/errors';
import { writeAudit } from '../../utils/audit';
import { env } from '../../config/env';

type SettingType = 'string' | 'number' | 'boolean' | 'json';

interface SettingRow {
  key: string;
  value: string;
  value_type: SettingType;
  description: string | null;
  updated_by: string | null;
  updated_at: Date;
}

// In-process cache. Invalidated on write. Keeps hot reads fast.
let cache: Map<string, unknown> | null = null;
let cacheLoadedAt = 0;
const CACHE_TTL_MS = 30_000;

async function loadAll(): Promise<Map<string, unknown>> {
  const rows = await query<SettingRow>(`SELECT key, value, value_type FROM settings`);
  const map = new Map<string, unknown>();
  for (const row of rows.rows) map.set(row.key, parseValue(row.value, row.value_type));
  return map;
}

function parseValue(raw: string, type: SettingType): unknown {
  switch (type) {
    case 'number':  return Number(raw);
    case 'boolean': return raw.toLowerCase() === 'true';
    case 'json':    try { return JSON.parse(raw); } catch { return null; }
    default:        return raw;
  }
}

function serializeValue(value: unknown, type: SettingType): string {
  switch (type) {
    case 'boolean': return value ? 'true' : 'false';
    case 'json':    return JSON.stringify(value);
    default:        return String(value);
  }
}

async function getCache(): Promise<Map<string, unknown>> {
  const stale = Date.now() - cacheLoadedAt > CACHE_TTL_MS;
  if (!cache || stale) {
    cache = await loadAll();
    cacheLoadedAt = Date.now();
  }
  return cache;
}

function invalidateCache(): void {
  cache = null;
  cacheLoadedAt = 0;
}

// =====================================================================
// Public API
// =====================================================================
export async function listSettings() {
  const rows = await query<SettingRow>(
    `SELECT s.key, s.value, s.value_type, s.description, s.updated_by, s.updated_at,
            m.first_name AS updated_by_first_name, m.last_name AS updated_by_last_name
     FROM settings s
     LEFT JOIN members m ON m.id = s.updated_by
     ORDER BY s.key ASC`
  );
  return rows.rows.map((r) => ({
    ...r,
    parsed_value: parseValue(r.value, r.value_type),
  }));
}

export async function getSetting<T = unknown>(key: string, fallback?: T): Promise<T> {
  const rows = await query<SettingRow>(
    `SELECT key, value, value_type FROM settings WHERE key = $1`,
    [key]
  );
  if (!rows.rows[0]) {
    if (fallback !== undefined) return fallback;
    throw new NotFoundError(`Setting "${key}" not found`);
  }
  return parseValue(rows.rows[0].value, rows.rows[0].value_type) as T;
}

export async function updateSetting(
  key: string,
  value: unknown,
  ctx: { actorId: string; ip?: string; userAgent?: string }
) {
  const existing = await query<SettingRow>(
    `SELECT key, value, value_type FROM settings WHERE key = $1`,
    [key]
  );
  if (!existing.rows[0]) throw new NotFoundError(`Setting "${key}" not found`);

  const before = existing.rows[0];
  const serialized = serializeValue(value, before.value_type);

  await query(
    `UPDATE settings SET value = $2, updated_by = $3, updated_at = NOW() WHERE key = $1`,
    [key, serialized, ctx.actorId]
  );

  await writeAudit(
    {
      action: 'SETTING_UPDATED',
      entity: 'settings',
      entityId: key,           // audit_logs.entity_id is TEXT — key fits
      details: { key, before: before.value, after: serialized, value_type: before.value_type },
    },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  invalidateCache();

  return {
    key,
    value: serialized,
    parsed_value: parseValue(serialized, before.value_type),
    value_type: before.value_type,
  };
}

// =====================================================================
// Convenience accessors used by other modules
// =====================================================================
export async function getPenaltyConfig() {
  const fallback = {
    enabled: env.PENALTY_ENABLED,
    grace_days: env.PENALTY_GRACE_DAYS,
    amount: env.PENALTY_AMOUNT,
    frequency_days: env.PENALTY_FREQUENCY_DAYS,
  };

  try {
    const cache = await getCache();
    return {
      enabled:        (cache.get('penalty.enabled')        as boolean) ?? fallback.enabled,
      grace_days:     (cache.get('penalty.grace_days')     as number)  ?? fallback.grace_days,
      amount:         (cache.get('penalty.amount')         as number)  ?? fallback.amount,
      frequency_days: (cache.get('penalty.frequency_days') as number)  ?? fallback.frequency_days,
    };
  } catch {
    // If settings table isn't reachable, fall back to env
    return fallback;
  }
}