import { query } from '../../config/database';
import { NotFoundError } from '../../utils/errors';
import { writeAudit } from '../../utils/audit';
import type { UpdateOrganizationInput } from './organization.schemas';

interface Ctx {
  actorId: string;
  ip?: string;
  userAgent?: string;
}

// =====================================================================
// LIST — all rows, ordered logically for the About screen
// =====================================================================
export async function listOrganization() {
  const rows = await query(
    `SELECT id, key, title_en, title_om, content_en, content_om, metadata, updated_at
     FROM organization_info
     ORDER BY
       CASE key
         WHEN 'about'   THEN 1
         WHEN 'mission' THEN 2
         WHEN 'vision'  THEN 3
         WHEN 'bylaws'  THEN 4
         WHEN 'contact' THEN 5
         ELSE 9
       END`
  );
  return rows.rows;
}

// =====================================================================
// GET one
// =====================================================================
export async function getOrganization(key: string) {
  const rows = await query(
    `SELECT id, key, title_en, title_om, content_en, content_om, metadata, updated_at
     FROM organization_info
     WHERE key = $1`,
    [key]
  );
  const row = rows.rows[0];
  if (!row) throw new NotFoundError(`Organization info "${key}" not found`);
  return row;
}

// =====================================================================
// UPDATE
// =====================================================================
export async function updateOrganization(
  key: string,
  input: UpdateOrganizationInput,
  ctx: Ctx
) {
  const before = await getOrganization(key);

  const fields: string[] = [];
  const values: unknown[] = [];
  let i = 1;

  if (input.title_en   !== undefined) { fields.push(`title_en = $${i++}`);   values.push(input.title_en); }
  if (input.title_om   !== undefined) { fields.push(`title_om = $${i++}`);   values.push(input.title_om); }
  if (input.content_en !== undefined) { fields.push(`content_en = $${i++}`); values.push(input.content_en); }
  if (input.content_om !== undefined) { fields.push(`content_om = $${i++}`); values.push(input.content_om); }
  if (input.metadata   !== undefined) { fields.push(`metadata = $${i++}`);   values.push(input.metadata ? JSON.stringify(input.metadata) : null); }

  if (fields.length === 0) return before;

  fields.push(`updated_by = $${i++}`);
  values.push(ctx.actorId);

  fields.push(`updated_at = NOW()`);

  values.push(key);
  const rows = await query(
    `UPDATE organization_info
     SET ${fields.join(', ')}
     WHERE key = $${i}
     RETURNING id, key, title_en, title_om, content_en, content_om, metadata, updated_at`,
    values
  );

  if (!rows.rows[0]) throw new NotFoundError(`Organization info "${key}" not found`);

  await writeAudit(
    {
      action: 'ORGANIZATION_UPDATED',
      entity: 'organization_info',
      entityId: key,
      details: { key, before: { title_en: before.title_en, content_en: before.content_en }, after: input },
    },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  return rows.rows[0];
}