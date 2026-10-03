import { Request, Response } from 'express';
import { ok, created, noContent } from '../../utils/response';
import * as svc from './members.service';
import { t } from '../../utils/i18n';

function ctx(req: Request) {
  return {
    actorId: req.member!.id,
    ip: req.clientIp,
    userAgent: req.userAgentHeader,
  };
}

export async function list(req: Request, res: Response) {
  const data = await svc.listMembers(req.query as any);
  return ok(res, data);
}

export async function getOne(req: Request, res: Response) {
  const data = await svc.getMember(req.params.id);
  return ok(res, data);
}

export async function create(req: Request, res: Response) {
  const data = await svc.createMember(req.body, ctx(req));
  return created(res, data, t('member.created', req.lang ?? 'en'));
}

export async function update(req: Request, res: Response) {
  const data = await svc.updateMember(req.params.id, req.body, ctx(req));
  return ok(res, data, { message: t('member.updated', req.lang ?? 'en') });
}

export async function suspend(req: Request, res: Response) {
  const data = await svc.setMemberStatus(req.params.id, 'suspended', ctx(req));
  return ok(res, data, { message: t('member.suspended', req.lang ?? 'en') });
}

export async function activate(req: Request, res: Response) {
  const data = await svc.setMemberStatus(req.params.id, 'active', ctx(req));
  return ok(res, data, { message: t('member.activated', req.lang ?? 'en') });
}

// ---------- Dependents ----------
export async function listDeps(req: Request, res: Response) {
  const data = await svc.listDependents(req.params.id);
  return ok(res, data);
}

export async function createDep(req: Request, res: Response) {
  const data = await svc.createDependent(req.params.id, req.body, ctx(req));
  return created(res, data, t('dependent.added', req.lang ?? 'en'));
}

export async function updateDep(req: Request, res: Response) {
  const data = await svc.updateDependent(req.params.id, req.params.depId, req.body, ctx(req));
  return ok(res, data, { message: t('dependent.updated', req.lang ?? 'en') });
}

export async function deleteDep(req: Request, res: Response) {
  await svc.deleteDependent(req.params.id, req.params.depId, ctx(req));
  return noContent(res);
}