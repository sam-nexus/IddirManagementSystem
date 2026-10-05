import { query } from '../../config/database';

interface ListAuditInput {
  actor_id?: string;
  action?: string;
  entity?: string;
  entity_id?: string;
  from?: string;
  to?: string;
  page: number;
  limit: number;
}

export async function listAudit(input: ListAuditInput) {
  const where: string[] = [];
  const params: unknown[] = [];
  let i = 1;

  if (input.actor_id)  { where.push(`a.actor_id = $${i}`);   params.push(input.actor_id);   i++; }
  if (input.action)    { where.push(`a.action = $${i}`);     params.push(input.action);     i++; }
  if (input.entity)    { where.push(`a.entity = $${i}`);     params.push(input.entity);     i++; }
  if (input.entity_id) { where.push(`a.entity_id = $${i}`);  params.push(input.entity_id);  i++; }
  if (input.from)      { where.push(`a.created_at >= $${i}::date`); params.push(input.from); i++; }
  if (input.to)        { where.push(`a.created_at < ($${i}::date + INTERVAL '1 day')`); params.push(input.to); i++; }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM audit_logs a ${whereSql}`,
    params
  );

  const rows = await query(
    `SELECT a.id, a.actor_id, a.action, a.entity, a.entity_id,
            a.details, a.ip, a.user_agent, a.created_at,
            m.first_name AS actor_first_name, m.last_name AS actor_last_name, m.role AS actor_role
     FROM audit_logs a
     LEFT JOIN members m ON m.id = a.actor_id
     ${whereSql}
     ORDER BY a.created_at DESC
     LIMIT $${i} OFFSET $${i + 1}`,
    [...params, input.limit, offset]
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

export async function getAuditEntry(id: number) {
  const rows = await query(
    `SELECT a.*, m.first_name AS actor_first_name, m.last_name AS actor_last_name
     FROM audit_logs a
     LEFT JOIN members m ON m.id = a.actor_id
     WHERE a.id = $1`,
    [id]
  );
  return rows.rows[0] ?? null;
}