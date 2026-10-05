import { Request, Response } from 'express';
import { ok, created, noContent } from '../../utils/response';
import * as svc from './meetings.service';
import { t } from '../../utils/i18n';

function ctx(req: Request) {
  return { actorId: req.member!.id, ip: req.clientIp, userAgent: req.userAgentHeader };
}

function actor(req: Request) {
  return { id: req.member!.id, role: req.member!.role };
}

export async function create(req: Request, res: Response) {
  const data = await svc.createMeeting(req.body, ctx(req));
  return created(res, data, t('meeting.created', req.lang ?? 'en'));
}

export async function list(req: Request, res: Response) {
  const data = await svc.listMeetings(req.query as any);
  return ok(res, data);
}

export async function getOne(req: Request, res: Response) {
  const data = await svc.getMeeting(req.params.id, actor(req));
  return ok(res, data);
}

export async function update(req: Request, res: Response) {
  const data = await svc.updateMeeting(req.params.id, req.body, ctx(req));
  return ok(res, data, { message: t('meeting.updated', req.lang ?? 'en') });
}

export async function remove(req: Request, res: Response) {
  await svc.deleteMeeting(req.params.id, ctx(req));
  return noContent(res);
}

export async function saveMinutes(req: Request, res: Response) {
  const data = await svc.saveMinutes(req.params.id, req.body, ctx(req));
  return ok(res, data, { message: t('meeting.minutesSaved', req.lang ?? 'en') });
}

export async function setAttendance(req: Request, res: Response) {
  const data = await svc.setAttendance(req.params.id, req.body.member_ids, ctx(req));
  return ok(res, data);
}