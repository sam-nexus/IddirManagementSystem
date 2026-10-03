import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../utils/errors';
import { fail } from '../utils/response';
import { t } from '../utils/i18n';
import { isProd } from '../config/env';

export function notFoundHandler(req: Request, res: Response): void {
  fail(res, 404, t('error.notFound', req.lang ?? 'en'));
}

export function errorHandler(
  err: unknown,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  const lang = req.lang ?? 'en';

  // Zod (in case validate() is bypassed)
  if (err instanceof ZodError) {
    fail(
      res,
      400,
      t('error.validation', lang),
      err.errors.map((e) => ({ field: e.path.join('.') || '(root)', message: e.message }))
    );
    return;
  }

  // Our own typed errors
  if (err instanceof AppError) {
    const errors =
      Array.isArray(err.details) && err.details.length > 0
        ? (err.details as Array<{ field?: string; message: string }>)
        : undefined;
    fail(res, err.status, err.message, errors);
    return;
  }

  // Unknown — log full stack in dev, hide it in prod
  console.error('[error]', err);
  const message = isProd ? t('error.serverError', lang) : (err as Error)?.message ?? 'Unknown error';
  fail(res, 500, message);
}