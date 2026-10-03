import { Request, Response } from 'express';
import { ok, created } from '../../utils/response';
import * as svc from './auth.service';
import { t } from '../../utils/i18n';

export async function login(req: Request, res: Response) {
  const result = await svc.login(req.body, {
    ip: req.clientIp,
    userAgent: req.userAgentHeader,
  });
  return ok(res, result, { message: t('auth.loginSuccess', req.lang ?? 'en') });
}

export async function sendOtp(req: Request, res: Response) {
  const result = await svc.sendOtp(req.body);
  return ok(res, result, { message: t('auth.otpSent', req.lang ?? 'en') });
}

export async function verifyOtp(req: Request, res: Response) {
  const result = await svc.verifyOtpCode(req.body);
  return ok(res, result);
}

export async function refresh(req: Request, res: Response) {
  const result = await svc.refresh(req.body, {
    ip: req.clientIp,
    userAgent: req.userAgentHeader,
  });
  return ok(res, result);
}

export async function logout(req: Request, res: Response) {
  await svc.logout(req.member!.id, req.body?.refresh_token);
  return ok(res, null, { message: t('auth.logoutSuccess', req.lang ?? 'en') });
}

export async function me(req: Request, res: Response) {
  const data = await svc.me(req.member!.id);
  return ok(res, data);
}

export async function updateProfile(req: Request, res: Response) {
  const data = await svc.updateProfile(req.member!.id, req.body);
  return ok(res, data);
}

export async function changePin(req: Request, res: Response) {
  await svc.changePin(req.member!.id, req.body);
  return ok(res, null, { message: t('auth.pinChanged', req.lang ?? 'en') });
}