import { Request, Response } from 'express';
import { ok, created } from '../../utils/response';
import * as svc from './support.service';
import { t } from '../../utils/i18n';

function ctx(req: Request) {
  return {
    actorId: req.member!.id,
    ip: req.clientIp,
    userAgent: req.userAgentHeader,
    lang: req.lang,
  };
}

function actor(req: Request) {
  return { id: req.member!.id, role: req.member!.role };
}

export async function create(req: Request, res: Response) {
  const data = await svc.createRequest(req.body, ctx(req));
  return created(res, data, t('support.requested', req.lang ?? 'en'));
}

export async function list(req: Request, res: Response) {
  const data = await svc.listRequests(req.query as any, actor(req));
  return ok(res, data);
}

export async function getOne(req: Request, res: Response) {
  const data = await svc.getRequest(req.params.id, actor(req));
  return ok(res, data);
}

export async function update(req: Request, res: Response) {
  const data = await svc.updateRequest(req.params.id, req.body, ctx(req));
  return ok(res, data);
}

export async function decide(req: Request, res: Response) {
  const data = await svc.decideRequest(req.params.id, req.body, ctx(req));
  const msg =
    req.body.decision === 'approve'
      ? t('support.approved', req.lang ?? 'en')
      : t('support.rejected', req.lang ?? 'en');
  return ok(res, data, { message: msg });
}

export async function payout(req: Request, res: Response) {
  const data = await svc.recordPayout(req.params.id, req.body, ctx(req));
  return created(res, data, t('payout.paid', req.lang ?? 'en'));
}

export async function listPayouts(req: Request, res: Response) {
  const data = await svc.listPayouts(req.query as any);
  return ok(res, data);
}

export async function getPayout(req: Request, res: Response) {
  const data = await svc.getPayout(req.params.id);
  return ok(res, data);
}