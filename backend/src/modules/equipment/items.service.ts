import { query } from '../../config/database';
import { BadRequestError, ConflictError, NotFoundError } from '../../utils/errors';
import { writeAudit } from '../../utils/audit';
import type { CreateItemInput, ListItemsInput, UpdateItemInput } from './equipment.schemas';

interface Ctx {
  actorId: string;
  ip?: string;
  userAgent?: string;
}

// =====================================================================
// LIST
// =====================================================================
export async function listItems(input: ListItemsInput) {
  const where: string[] = [];
  const params: unknown[] = [];
  let i = 1;

  if (!input.include_inactive) {
    where.push(`is_active = TRUE`);
  }
  if (input.only_available) {
    where.push(`quantity_available > 0`);
  }
  if (input.search) {
    where.push(`(name_en ILIKE $${i} OR name_om ILIKE $${i})`);
    params.push(`%${input.search}%`);
    i++;
  }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const rows = await query(
    `SELECT id, name_en, name_om, description_en, description_om,
            quantity_total, quantity_available, is_active, created_at, updated_at
     FROM equipment_items
     ${whereSql}
     ORDER BY is_active DESC, name_en ASC`,
    params
  );
  return rows.rows;
}

// =====================================================================
// GET ONE
// =====================================================================
export async function getItem(id: string) {
  const rows = await query(
    `SELECT id, name_en, name_om, description_en, description_om,
            quantity_total, quantity_available, is_active, created_at, updated_at
     FROM equipment_items WHERE id = $1`,
    [id]
  );
  if (!rows.rows[0]) throw new NotFoundError('Equipment item not found');
  return rows.rows[0];
}

// =====================================================================
// CREATE
// =====================================================================
export async function createItem(input: CreateItemInput, ctx: Ctx) {
  const rows = await query(
    `INSERT INTO equipment_items
       (name_en, name_om, description_en, description_om,
        quantity_total, quantity_available, created_by)
     VALUES ($1, $2, $3, $4, $5, $5, $6)
     RETURNING id, name_en, name_om, description_en, description_om,
               quantity_total, quantity_available, is_active, created_at`,
    [
      input.name_en,
      input.name_om,
      input.description_en ?? null,
      input.description_om ?? null,
      input.quantity_total,
      ctx.actorId,
    ]
  );

  await writeAudit(
    {
      action: 'EQUIPMENT_ITEM_CREATED',
      entity: 'equipment_items',
      entityId: rows.rows[0].id,
      details: { name_en: input.name_en, quantity_total: input.quantity_total },
    },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );
  return rows.rows[0];
}

// =====================================================================
// UPDATE
// =====================================================================
export async function updateItem(id: string, input: UpdateItemInput, ctx: Ctx) {
  const before = await getItem(id);

  // If quantity_total is being reduced, don't allow going below what's on loan
  if (input.quantity_total !== undefined) {
    const onLoan = before.quantity_total - before.quantity_available;
    if (input.quantity_total < onLoan) {
      throw new BadRequestError(
        `Cannot reduce quantity_total below ${onLoan} — that many items are currently on loan`
      );
    }
  }

  const fields: string[] = [];
  const values: unknown[] = [];
  let i = 1;

  for (const k of ['name_en', 'name_om', 'description_en', 'description_om'] as const) {
    if ((input as any)[k] !== undefined) {
      fields.push(`${k} = $${i++}`);
      values.push((input as any)[k]);
    }
  }

  if (input.quantity_total !== undefined) {
    const onLoan = before.quantity_total - before.quantity_available;
    fields.push(`quantity_total = $${i++}`);
    values.push(input.quantity_total);
    fields.push(`quantity_available = $${i++}`);
    values.push(input.quantity_total - onLoan);
  }

  if (input.is_active !== undefined) {
    fields.push(`is_active = $${i++}`);
    values.push(input.is_active);
  }

  if (fields.length === 0) return before;

  values.push(id);
  const rows = await query(
    `UPDATE equipment_items SET ${fields.join(', ')} WHERE id = $${i}
     RETURNING id, name_en, name_om, description_en, description_om,
               quantity_total, quantity_available, is_active, updated_at`,
    values
  );
  if (!rows.rows[0]) throw new NotFoundError('Equipment item not found');

  await writeAudit(
    {
      action: 'EQUIPMENT_ITEM_UPDATED',
      entity: 'equipment_items',
      entityId: id,
      details: { before, after: input },
    },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );
  return rows.rows[0];
}