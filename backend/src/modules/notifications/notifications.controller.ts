import { Request, Response } from 'express';
import { ok, created, noContent } from '../../utils/response';
import * as svc from './notifications.service';

function memberId(req: Request): string {
  return req.member!.id;
}

export async function registerDevice(req: Request, res: Response) {
  const data = await svc.registerDevice(req.body, memberId(req));
  return created(res, data);
}

export async function unregisterDevice(req: Request, res: Response) {
  await svc.unregisterDevice(String(req.query.token ?? ''), memberId(req));
  return noContent(res);
}

export async function list(req: Request, res: Response) {
  const data = await svc.listMyNotifications(memberId(req), req.query as any);
  return ok(res, data);
}

export async function unread(req: Request, res: Response) {
  const data = await svc.unreadCount(memberId(req));
  return ok(res, data);
}

export async function markRead(req: Request, res: Response) {
  const data = await svc.markRead(memberId(req), req.body);
  return ok(res, data);
}