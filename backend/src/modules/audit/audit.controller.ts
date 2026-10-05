import { Request, Response } from 'express';
import { ok } from '../../utils/response';
import * as svc from './audit.service';
import { NotFoundError } from '../../utils/errors';

export async function list(req: Request, res: Response) {
  const data = await svc.listAudit({
    actor_id: (req.query as any).actor_id,
    action: (req.query as any).action,
    entity: (req.query as any).entity,
    entity_id: (req.query as any).entity_id,
    from: (req.query as any).from,
    to: (req.query as any).to,
    page: Number((req.query as any).page ?? 1),
    limit: Number((req.query as any).limit ?? 50),
  });
  return ok(res, data);
}

export async function getOne(req: Request, res: Response) {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) throw new NotFoundError('Invalid id');
  const entry = await svc.getAuditEntry(id);
  if (!entry) throw new NotFoundError('Audit entry not found');
  return ok(res, entry);
}