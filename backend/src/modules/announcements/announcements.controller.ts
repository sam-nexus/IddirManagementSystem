import { Request, Response } from 'express';
import { ok, created, noContent } from '../../utils/response';
import * as svc from './announcements.service';
import { t } from '../../utils/i18n';

function ctx(req: Request) {
  return { actorId: req.member!.id, ip: req.clientIp, userAgent: req.userAgentHeader, lang: req.lang };
}

export async function create(req: Request, res: Response) {
  const data = await svc.createAnnouncement(req.body, ctx(req));
  return created(res, data, t('announcement.created', req.lang ?? 'en'));
}

export async function list(req: Request, res: Response) {
  const data = await svc.listAnnouncements(req.query as any);
  return ok(res, data);
}

export async function getOne(req: Request, res: Response) {
  const data = await svc.getAnnouncement(req.params.id);
  return ok(res, data);
}

export async function update(req: Request, res: Response) {
  const data = await svc.updateAnnouncement(req.params.id, req.body, ctx(req));
  return ok(res, data, { message: t('announcement.updated', req.lang ?? 'en') });
}

export async function remove(req: Request, res: Response) {
  await svc.deleteAnnouncement(req.params.id, ctx(req));
  return noContent(res);
}