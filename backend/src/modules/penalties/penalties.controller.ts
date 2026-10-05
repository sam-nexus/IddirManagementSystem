import { Request, Response } from 'express';
import { ok, created } from '../../utils/response';
import * as svc from './penalties.service';

function ctx(req: Request) {
  return { actorId: req.member!.id, ip: req.clientIp, userAgent: req.userAgentHeader };
}

function actor(req: Request) {
  return { id: req.member!.id, role: req.member!.role };
}

export async function list(req: Request, res: Response) {
  const data = await svc.listPenalties(req.query as any, actor(req));
  return ok(res, data);
}

export async function mySummary(req: Request, res: Response) {
  const data = await svc.getMyPenaltySummary(req.member!.id);
  return ok(res, data);
}

export async function getOne(req: Request, res: Response) {
  const data = await svc.getPenalty(req.params.id, actor(req));
  return ok(res, data);
}

export async function createManual(req: Request, res: Response) {
  const data = await svc.createManualPenalty(req.body, ctx(req));
  return created(res, data);
}

export async function waive(req: Request, res: Response) {
  const data = await svc.waivePenalty(req.params.id, req.body, ctx(req));
  return ok(res, data);
}

export async function markPaid(req: Request, res: Response) {
  const data = await svc.markPenaltyPaid(req.params.id, ctx(req));
  return ok(res, data);
}