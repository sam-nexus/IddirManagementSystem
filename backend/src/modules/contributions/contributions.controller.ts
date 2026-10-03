import { Request, Response } from 'express';
import { ok, created } from '../../utils/response';
import * as svc from './contributions.service';
import { t } from '../../utils/i18n';

function ctx(req: Request) {
  return { actorId: req.member!.id, ip: req.clientIp, userAgent: req.userAgentHeader, lang: req.lang };
}

export async function getPlan(req: Request, res: Response) {
  const data = await svc.getCurrentPlan();
  return ok(res, data);
}

export async function generate(req: Request, res: Response) {
  const data = await svc.generateDues(req.body.period, ctx(req));
  return ok(res, data, { message: t('dues.generated', req.lang ?? 'en') });
}

export async function listDues(req: Request, res: Response) {
  const data = await svc.listDues(req.query as any);
  return ok(res, data);
}

export async function myDues(req: Request, res: Response) {
  const data = await svc.getMyDues(req.member!.id, (req.query as any).period);
  return ok(res, data);
}

export async function initPayment(req: Request, res: Response) {
  const data = await svc.initChapaPayment(req.body, req.member!.id, ctx(req));
  return ok(res, data, { message: t('payment.initiated', req.lang ?? 'en') });
}

export async function verifyPayment(req: Request, res: Response) {
  const data = await svc.verifyChapaPayment(req.body.tx_ref, ctx(req));
  return ok(res, data, { message: t('payment.success', req.lang ?? 'en') });
}

export async function cashPayment(req: Request, res: Response) {
  const data = await svc.recordCashPayment(req.body, ctx(req));
  return created(res, data, t('payment.cashRecorded', req.lang ?? 'en'));
}

export async function listPayments(req: Request, res: Response) {
  const data = await svc.listPayments(req.query as any);
  return ok(res, data);
}

export async function getReceipt(req: Request, res: Response) {
  const data = await svc.getReceipt(req.params.id);
  return ok(res, data);
}