import { Request, Response, NextFunction } from 'express';
import { normalizeLang, Lang } from '../utils/i18n';
import { supportedLanguages } from '../config/env';

export function requestContext(req: Request, _res: Response, next: NextFunction): void {
  // IP — trust X-Forwarded-For if behind a proxy (Supabase / Vercel / nginx)
  const fwd = (req.headers['x-forwarded-for'] as string | undefined)?.split(',')[0]?.trim();
  req.clientIp = fwd || req.socket.remoteAddress || undefined;
  req.userAgentHeader = req.headers['user-agent'] as string | undefined;

  // Language: explicit header wins, otherwise English
  const headerLang = (req.headers['x-lang'] as string | undefined)
    ?? (req.headers['accept-language'] as string | undefined)?.slice(0, 2);

  let lang: Lang = 'en';
  if (headerLang && (supportedLanguages as string[]).includes(headerLang)) {
    lang = normalizeLang(headerLang);
  }
  req.lang = lang;

  next();
}