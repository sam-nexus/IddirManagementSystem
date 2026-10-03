import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { UnauthorizedError, ForbiddenError } from '../utils/errors';
import { t } from '../utils/i18n';

export interface AccessTokenPayload {
  sub: string;                 // member id
  role: 'member' | 'chairperson' | 'secretary' | 'treasurer' | 'auditor';
  status: 'active' | 'suspended' | 'inactive';
  lang: 'en' | 'om';
  must_change_pin: boolean;
  device_id?: string;
  type: 'access';
}

/**
 * Require a valid access token. Attaches req.member.
 */
export function requireAuth(req: Request, _res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return next(new UnauthorizedError(t('error.unauthorized', req.lang ?? 'en')));
  }

  const token = header.slice('Bearer '.length).trim();

  try {
    const payload = jwt.verify(token, env.JWT_ACCESS_SECRET) as AccessTokenPayload;
    if (payload.type !== 'access') {
      return next(new UnauthorizedError(t('auth.tokenExpired', req.lang ?? 'en')));
    }

    if (payload.status === 'suspended') {
      return next(new ForbiddenError(t('auth.accountSuspended', req.lang ?? 'en')));
    }
    if (payload.status === 'inactive') {
      return next(new ForbiddenError(t('auth.accountInactive', req.lang ?? 'en')));
    }

    req.member = {
      id: payload.sub,
      member_no: '',       // fill from DB if you need it (routes should re-fetch when they need it)
      role: payload.role,
      status: payload.status,
      language: payload.lang,
      must_change_pin: payload.must_change_pin,
      device_id: payload.device_id,
    };

    // Override language if the client sent an explicit header
    if (req.lang) req.member.language = req.lang;

    next();
  } catch {
    next(new UnauthorizedError(t('auth.tokenExpired', req.lang ?? 'en')));
  }
}

/**
 * Require one of the given roles. Use after requireAuth.
 */
export function requireRole(...roles: AccessTokenPayload['role'][]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.member) {
      return next(new UnauthorizedError(t('error.unauthorized', req.lang ?? 'en')));
    }
    if (!roles.includes(req.member.role)) {
      return next(new ForbiddenError(t('error.forbidden', req.lang ?? 'en')));
    }
    next();
  };
}

/**
 * Block requests when the member still needs to change their PIN.
 * Use on everything except /auth/change-pin.
 */
export function requirePinChanged(req: Request, _res: Response, next: NextFunction): void {
  if (req.member?.must_change_pin) {
    return next(new ForbiddenError(t('auth.mustChangePin', req.lang ?? 'en')));
  }
  next();
}