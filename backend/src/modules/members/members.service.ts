import bcrypt from 'bcryptjs';
import { pool, query } from '../../config/database';
import { BadRequestError, ConflictError, ForbiddenError, NotFoundError } from '../../utils/errors';
import { t } from '../../utils/i18n';
import { normalizeEthiopianPhone } from '../../utils/phone';
import { writeAudit } from '../../utils/audit';
import type {
  CreateDependentInput,
  CreateMemberInput,
  ListMembersInput,
  UpdateDependentInput,
  UpdateMemberInput,
} from './members.schemas';

interface Ctx {
  actorId: string;
  ip?: string;
  userAgent?: string;
}

// =====================================================================
// LIST
// =====================================================================
export async function listMembers(input: ListMembersInput) {
  const where: string[] = [];
  const params: unknown[] = [];
  let i = 1;

  if (input.search) {
    where.push(`(first_name ILIKE $${i} OR last_name ILIKE $${i} OR phone ILIKE $${i} OR member_no ILIKE $${i})`);
    params.push(`%${input.search}%`);
    i++;
  }
  if (input.role) {
    where.push(`role = $${i}`);
    params.push(input.role);
    i++;
  }
  if (input.status) {
    where.push(`status = $${i}`);
    params.push(input.status);
    i++;
  }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const offset = (input.page - 1) * input.limit;

  const countRes = await query<{ c: number }>(
    `SELECT COUNT(*)::int AS c FROM members ${whereSql}`,
    params
  );
  const total = countRes.rows[0].c;

  const rows = await query(
    `SELECT id, member_no, first_name, last_name, phone, role, status, language,
            address, joined_at, contribution_override
     FROM members ${whereSql}
     ORDER BY member_no ASC
     LIMIT $${i} OFFSET $${i + 1}`,
    [...params, input.limit, offset]
  );

  return {
    items: rows.rows,
    pagination: {
      page: input.page,
      limit: input.limit,
      total,
      pages: Math.max(1, Math.ceil(total / input.limit)),
    },
  };
}

/**
 * Generates unpaid dues for a newly registered member.
 * Uses the iddir's founding date (default: 2015-09-11, Meskerem 1, 2015 EC).
 * Generates every month up to the current Gregorian month.
 */
async function generateHistoricalDues(
  memberId: string,
  contributionAmount: number,
  client: any // pg.PoolClient
): Promise<void> {
  // The iddir's official start date (e.g., Meskerem 1, 2015 EC = Sep 11, 2015)
  // You can change this to whatever year the iddir actually started.
  const iddirStart = new Date('2015-09-01');
  const today = new Date();

  // Set to the first of the current month
  const currentMonthStart = new Date(today.getFullYear(), today.getMonth(), 1);

  let current = new Date(iddirStart.getFullYear(), iddirStart.getMonth(), 1);

  while (current <= currentMonthStart) {
    // We insert 'YYYY-MM-01'
    const period = current.toISOString().split('T')[0];

    await client.query(
      `INSERT INTO contribution_dues 
         (member_id, period, amount_due, amount_paid, status, ethiopian_month_index)
       VALUES 
         ($1, $2::date, $3, 0, 'unpaid', 
           CASE EXTRACT(MONTH FROM $2::date)::int
             WHEN 9 THEN 1 WHEN 10 THEN 2 WHEN 11 THEN 3 WHEN 12 THEN 4
             WHEN 1 THEN 5 WHEN 2 THEN 6 WHEN 3 THEN 7 WHEN 4 THEN 8
             WHEN 5 THEN 9 WHEN 6 THEN 10 WHEN 7 THEN 11 WHEN 8 THEN 12
           END
         )
       ON CONFLICT (member_id, period) DO NOTHING`,
      [memberId, period, contributionAmount]
    );

    current.setMonth(current.getMonth() + 1);
  }
}


// =====================================================================
// GET ONE
// =====================================================================
export async function getMember(id: string) {
  const rows = await query(
    `SELECT id, member_no, first_name, last_name, phone, role, status, language,
            address, joined_at, contribution_override, must_change_pin
     FROM members WHERE id = $1`,
    [id]
  );
  const m = rows.rows[0];
  if (!m) throw new NotFoundError(t('member.notFound', 'en'));
  return m;
}

// =====================================================================
// CREATE
// =====================================================================
export async function createMember(input: CreateMemberInput, ctx: Ctx) {
  const phone = normalizeEthiopianPhone(input.phone);
  if (!phone) throw new BadRequestError(t('member.invalidPhone', 'en'));

  // Committee-role uniqueness check (chairperson, secretary, treasurer, auditor)
  const committeeRoles = ['chairperson', 'secretary', 'treasurer', 'auditor'];
  if (committeeRoles.includes(input.role)) {
    const existing = await query<{ c: number }>(
      `SELECT COUNT(*)::int AS c FROM members WHERE role = $1 AND status = 'active'`,
      [input.role]
    );
    if (existing.rows[0].c > 0) {
      throw new ConflictError(`An active ${input.role} already exists`);
    }
  }

  const tempPin = input.pin ?? Math.floor(100000 + Math.random() * 900000).toString();
  const hash = await bcrypt.hash(tempPin, 10);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const inserted = await client.query(
      `INSERT INTO members
         (first_name, last_name, phone, role, status, language, address, pin_hash, must_change_pin, contribution_override, created_by)
       VALUES ($1, $2, $3, $4, 'active', $5, $6, $7, TRUE, $8, $9)
       RETURNING id, member_no, first_name, last_name, phone, role, status, language, address, joined_at`,
      [
        input.first_name,
        input.last_name,
        phone,
        input.role,
        input.language,
        input.address ?? null,
        hash,
        input.contribution_override ?? null,
        ctx.actorId,
      ]
    );

    const member = inserted.rows[0];

    await writeAudit(
      {
        action: 'MEMBER_CREATED',
        entity: 'members',
        entityId: member.id,
        details: { phone, role: input.role },
      },
      { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent, client }
    );
    // NEW: Generate all historical dues back to the iddir's founding
    // Determine the amount (use override or default 100)
    const amount = input.contribution_override ?? 100.00;
    await generateHistoricalDues(member.rows[0].id, amount, client);
    
    await client.query('COMMIT');

    return {
      member,
      // Return the PIN only once so the secretary can share it with the member
      temporary_pin: input.pin ? undefined : tempPin,
    };
  } catch (err: any) {
    await client.query('ROLLBACK');
    if (err.code === '23505') {
      throw new ConflictError(t('member.duplicatePhone', 'en'));
    }
    throw err;
  } finally {
    client.release();
  }
}

// =====================================================================
// UPDATE
// =====================================================================
export async function updateMember(id: string, input: UpdateMemberInput, ctx: Ctx) {
  const before = await getMember(id);

  // Committee-role uniqueness on change
  if (input.role && input.role !== before.role) {
    const committeeRoles = ['chairperson', 'secretary', 'treasurer', 'auditor'];
    if (committeeRoles.includes(input.role)) {
      const existing = await query<{ c: number }>(
        `SELECT COUNT(*)::int AS c FROM members WHERE role = $1 AND status = 'active' AND id <> $2`,
        [input.role, id]
      );
      if (existing.rows[0].c > 0) {
        throw new ConflictError(`An active ${input.role} already exists`);
      }
    }
  }

  const fields: string[] = [];
  const values: unknown[] = [];
  let i = 1;

  const mapping: Record<string, string> = {
    first_name: 'first_name',
    last_name: 'last_name',
    language: 'language',
    address: 'address',
    role: 'role',
    contribution_override: 'contribution_override',
  };

  for (const [k, col] of Object.entries(mapping)) {
    if ((input as any)[k] !== undefined) {
      fields.push(`${col} = $${i}`);
      values.push((input as any)[k]);
      i++;
    }
  }

  if (fields.length === 0) return before;

  values.push(id);
  const rows = await query(
    `UPDATE members SET ${fields.join(', ')} WHERE id = $${i}
     RETURNING id, member_no, first_name, last_name, phone, role, status, language, address, joined_at, contribution_override`,
    values
  );

  await writeAudit(
    { action: 'MEMBER_UPDATED', entity: 'members', entityId: id, details: { before, after: input } },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  return rows.rows[0];
}

// =====================================================================
// SUSPEND / ACTIVATE
// =====================================================================
export async function setMemberStatus(
  id: string,
  status: 'active' | 'suspended' | 'inactive',
  ctx: Ctx
) {
  const member = await getMember(id);
  if (member.id === ctx.actorId && status !== 'active') {
    throw new ForbiddenError('You cannot suspend or deactivate yourself');
  }

  const rows = await query(
    `UPDATE members SET status = $2 WHERE id = $1
     RETURNING id, member_no, first_name, last_name, phone, role, status, language`,
    [id, status]
  );

  await writeAudit(
    { action: `MEMBER_STATUS_${status.toUpperCase()}`, entity: 'members', entityId: id, details: { from: member.status, to: status } },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  return rows.rows[0];
}

// =====================================================================
// DEPENDENTS
// =====================================================================
export async function listDependents(memberId: string) {
  const rows = await query(
    `SELECT id, member_id, full_name, relationship, date_of_birth, is_active, created_at
     FROM dependents WHERE member_id = $1 ORDER BY created_at ASC`,
    [memberId]
  );
  return rows.rows;
}

export async function createDependent(memberId: string, input: CreateDependentInput, ctx: Ctx) {
  const rows = await query(
    `INSERT INTO dependents (member_id, full_name, relationship, date_of_birth)
     VALUES ($1, $2, $3, $4)
     RETURNING id, member_id, full_name, relationship, date_of_birth, is_active, created_at`,
    [memberId, input.full_name, input.relationship, input.date_of_birth ?? null]
  );

  await writeAudit(
    { action: 'DEPENDENT_CREATED', entity: 'dependents', entityId: rows.rows[0].id, details: input },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  return rows.rows[0];
}

export async function updateDependent(
  memberId: string,
  depId: string,
  input: UpdateDependentInput,
  ctx: Ctx
) {
  const fields: string[] = [];
  const values: unknown[] = [];
  let i = 1;

  for (const k of ['full_name', 'relationship', 'date_of_birth', 'is_active'] as const) {
    if ((input as any)[k] !== undefined) {
      fields.push(`${k} = $${i}`);
      values.push((input as any)[k]);
      i++;
    }
  }

  if (fields.length === 0) {
    const r = await query(`SELECT * FROM dependents WHERE id = $1 AND member_id = $2`, [depId, memberId]);
    if (!r.rows[0]) throw new NotFoundError('Dependent not found');
    return r.rows[0];
  }

  values.push(depId, memberId);
  const rows = await query(
    `UPDATE dependents SET ${fields.join(', ')}
     WHERE id = $${i} AND member_id = $${i + 1}
     RETURNING id, member_id, full_name, relationship, date_of_birth, is_active, created_at`,
    values
  );

  if (!rows.rows[0]) throw new NotFoundError('Dependent not found');

  await writeAudit(
    { action: 'DEPENDENT_UPDATED', entity: 'dependents', entityId: depId, details: input },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );

  return rows.rows[0];
}

export async function deleteDependent(memberId: string, depId: string, ctx: Ctx) {
  const rows = await query(
    `DELETE FROM dependents WHERE id = $1 AND member_id = $2 RETURNING id`,
    [depId, memberId]
  );
  if (!rows.rows[0]) throw new NotFoundError('Dependent not found');

  await writeAudit(
    { action: 'DEPENDENT_DELETED', entity: 'dependents', entityId: depId },
    { actorId: ctx.actorId, ip: ctx.ip, userAgent: ctx.userAgent }
  );
}