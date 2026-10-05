import { Request, Response } from 'express';
import { ok } from '../../utils/response';
import * as svc from './settings.service';

export async function list(req: Request, res: Response) {
  const data = await svc.listSettings();
  return ok(res, data);
}

export async function getOne(req: Request, res: Response) {
  const data = await svc.getSetting(req.params.key);
  return ok(res, { key: req.params.key, value: data });
}

export async function update(req: Request, res: Response) {
  const data = await svc.updateSetting(req.params.key, req.body.value, {
    actorId: req.member!.id,
    ip: req.clientIp,
    userAgent: req.userAgentHeader,
  });
  return ok(res, data);
}