import { Request, Response } from 'express';
import { ok, created } from '../../utils/response';
import * as items from './items.service';
import * as requests from './requests.service';

function ctx(req: Request) {
  return {
    actorId: req.member!.id,
    role: req.member!.role,
    ip: req.clientIp,
    userAgent: req.userAgentHeader,
  };
}

function actor(req: Request) {
  return { id: req.member!.id, role: req.member!.role };
}

// ---------- Items ----------
export async function listItems(req: Request, res: Response) {
  const data = await items.listItems(req.query as any);
  return ok(res, data);
}
export async function getItem(req: Request, res: Response) {
  const data = await items.getItem(req.params.id);
  return ok(res, data);
}
export async function createItem(req: Request, res: Response) {
  const data = await items.createItem(req.body, ctx(req));
  return created(res, data);
}
export async function updateItem(req: Request, res: Response) {
  const data = await items.updateItem(req.params.id, req.body, ctx(req));
  return ok(res, data);
}

// ---------- Requests ----------
export async function listRequests(req: Request, res: Response) {
  const data = await requests.listRequests(req.query as any, actor(req));
  return ok(res, data);
}
export async function getRequest(req: Request, res: Response) {
  const data = await requests.getRequest(req.params.id, actor(req));
  return ok(res, data);
}
export async function createRequest(req: Request, res: Response) {
  const data = await requests.createRequest(req.body, ctx(req));
  return created(res, data);
}
export async function updateRequest(req: Request, res: Response) {
  const data = await requests.updateRequest(req.params.id, req.body, ctx(req));
  return ok(res, data);
}
export async function cancelRequest(req: Request, res: Response) {
  const data = await requests.cancelRequest(req.params.id, ctx(req));
  return ok(res, data);
}
export async function decide(req: Request, res: Response) {
  const data = await requests.decideRequest(req.params.id, req.body, ctx(req));
  return ok(res, data);
}
export async function handover(req: Request, res: Response) {
  const data = await requests.handover(req.params.id, ctx(req));
  return ok(res, data);
}
export async function returnItem(req: Request, res: Response) {
  const data = await requests.returnItem(req.params.id, req.body, ctx(req));
  return ok(res, data);
}