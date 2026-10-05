import { Request, Response } from 'express';
import { ok, created } from '../../utils/response';
import * as svc from './reports.service';
import { t } from '../../utils/i18n';

function ctx(req: Request) {
  return { actorId: req.member!.id, ip: req.clientIp, userAgent: req.userAgentHeader };
}

export async function financials(req: Request, res: Response) {
  const data = await svc.computeFinancials(req.query as any);
  return ok(res, data);
}

export async function paidVsUnpaid(req: Request, res: Response) {
  const period = String((req.query as any).period);
  const data = await svc.paidVsUnpaid(period);
  return ok(res, data);
}

export async function publish(req: Request, res: Response) {
  const data = await svc.publishReport(req.body, ctx(req));
  return created(res, data, t('report.published', req.lang ?? 'en'));
}

export async function list(req: Request, res: Response) {
  const data = await svc.listReports(req.query as any);
  return ok(res, data);
}

export async function getOne(req: Request, res: Response) {
  const data = await svc.getReport(req.params.id);
  return ok(res, data);
}