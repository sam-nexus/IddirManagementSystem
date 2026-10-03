import { Response } from 'express';
import { t, Lang } from './i18n';

export interface ApiEnvelope<T = unknown> {
  success: boolean;
  message: string;
  data?: T;
  errors?: Array<{ field?: string; message: string }>;
  meta?: Record<string, unknown>;
}

export function ok<T>(
  res: Response,
  data: T,
  opts?: { message?: string; lang?: Lang; meta?: Record<string, unknown>; status?: number }
): Response {
  const body: ApiEnvelope<T> = {
    success: true,
    message: opts?.message ?? t('ok', opts?.lang ?? 'en'),
    data,
  };
  if (opts?.meta) body.meta = opts.meta;
  return res.status(opts?.status ?? 200).json(body);
}

export function fail(
  res: Response,
  status: number,
  message: string,
  errors?: Array<{ field?: string; message: string }>,
  lang: Lang = 'en'
): Response {
  return res.status(status).json({
    success: false,
    message,
    errors,
  } satisfies ApiEnvelope);
}

export function created<T>(res: Response, data: T, message?: string, lang?: Lang): Response {
  return ok(res, data, { message, lang, status: 201 });
}

export function noContent(res: Response): Response {
  return res.status(204).send();
}