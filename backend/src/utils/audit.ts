import { PoolClient } from 'pg';
import { query } from '../config/database';

export interface AuditContext {
  actorId?: string | null;
  ip?: string | null;
  userAgent?: string | null;
  client?: PoolClient;
}

export interface AuditInput {
  action: string;
  entity?: string | null;
  entityId?: string | null;
  details?: unknown;
}

export async function writeAudit(input: AuditInput, ctx: AuditContext = {}): Promise<void> {
  const sql = `
    INSERT INTO audit_logs (actor_id, action, entity, entity_id, details, ip, user_agent)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
  `;
  const params = [
    ctx.actorId ?? null,
    input.action,
    input.entity ?? null,
    input.entityId ?? null,
    input.details ? JSON.stringify(input.details) : null,
    ctx.ip ?? null,
    ctx.userAgent ?? null,
  ];

  try {
    if (ctx.client) await ctx.client.query(sql, params);
    else await query(sql, params);
  } catch (err) {
    console.error('[audit] failed to write:', (err as Error).message);
  }
}