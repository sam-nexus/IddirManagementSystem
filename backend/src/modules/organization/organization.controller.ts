import { Request, Response } from 'express';
import { ok } from '../../utils/response';
import * as svc from './organization.service';

function ctx(req: Request) {
  return { actorId: req.member!.id, ip: req.clientIp, userAgent: req.userAgentHeader };
}

export async function list(req: Request, res: Response) {
  const data = await svc.listOrganization();
  return ok(res, data);
}

export async function getOne(req: Request, res: Response) {
  const data = await svc.getOrganization(req.params.key);
  return ok(res, data);
}

export async function update(req: Request, res: Response) {
  const data = await svc.updateOrganization(req.params.key, req.body, ctx(req));
  return ok(res, data);
}