import { Request, Response } from 'express';
import { ok, created } from '../../utils/response';
import * as svc from './manual.service';

function ctx(req: Request) {
  return {
    actorId: req.member!.id,
    role: req.member!.role,
    ip: req.clientIp,
    userAgent: req.userAgentHeader,
    lang: req.lang,
  };
}

function actor(req: Request) {
  return { id: req.member!.id, role: req.member!.role };
}

export async function submit(req: Request, res: Response) {
  if (!req.file) {
    return res.status(400).json({
      success: false,
      message: 'Screenshot file is required (field name: file)',
    });
  }
  const data = await svc.submitManualPayment(req.body, req.file, ctx(req));
  return created(res, data);
}

export async function list(req: Request, res: Response) {
  const data = await svc.listManualPayments(req.query as any, actor(req));
  return ok(res, data);
}

export async function getOne(req: Request, res: Response) {
  const data = await svc.getManualPayment(req.params.id, actor(req));
  return ok(res, data);
}

export async function approve(req: Request, res: Response) {
  const data = await svc.approveManualPayment(req.params.id, ctx(req));
  return ok(res, data);
}

export async function reject(req: Request, res: Response) {
  const data = await svc.rejectManualPayment(req.params.id, req.body, ctx(req));
  return ok(res, data);
}