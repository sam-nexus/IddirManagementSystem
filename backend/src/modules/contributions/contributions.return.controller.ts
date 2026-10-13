import { Request, Response } from 'express';
import { verifyChapaPayment } from './contributions.service';



// Our references look like ODA-1700000000000-ab12cd34. Reject anything else.
const TX_REF_PATTERN = /^[A-Za-z0-9._-]{5,80}$/;

type Kind = 'success' | 'pending' | 'fail' | 'error';

/** Looks for the reference under every name Chapa may use. */
function pickTxRef(query: Request['query']): string | null {
  for (const key of ['trx_ref', 'tx_ref', 'reference']) {
    const value = query[key];
    const candidate = Array.isArray(value) ? value[0] : value;
    if (typeof candidate === 'string' && TX_REF_PATTERN.test(candidate)) {
      return candidate;
    }
  }
  return null;
}

/**
 * Landing page Chapa redirects to after payment.
 * Public (no auth): Chapa's redirect carries no JWT.
 *
 * We never trust the query params. verifyChapaPayment() asks Chapa for the
 * real status and updates the DB only if Chapa confirms success.
 * This page shows fixed messages only and never echoes request data.
 */
export async function chapaReturn(req: Request, res: Response) {
  res.setHeader('Cache-Control', 'no-store');
  console.log('[chapa-return]', req.method, req.originalUrl, '| ua:', req.get('user-agent'));

  const txRef = pickTxRef(req.query);
  if (!txRef) {
    return res.status(400).send(
      render(
        'fail',
        'Payment reference not found',
        'Please return to the app and tap "I paid" to check your payment.',
      ),
    );
  }

  try {
    const result = await verifyChapaPayment(txRef, {
      actorId: null,
      ip: req.clientIp,
      userAgent: req.userAgentHeader,
      lang: req.lang,
    });

    const status = String((result as any)?.status ?? '').toLowerCase();

    if (status === 'success') {
      return res
        .status(200)
        .send(
          render(
            'success',
            'Payment successful',
            'Your payment was received. Return to the app to see your receipt.',
          ),
        );
    }

    if (status === 'pending' || status === 'unknown' || status === '') {
      return res
        .status(200)
        .send(
          render(
            'pending',
            'Payment is being confirmed',
            'This can take a moment. Return to the app, we will confirm it shortly.',
          ),
        );
    }

    return res
      .status(200)
      .send(
        render(
          'fail',
          'Payment not completed',
          'The payment did not go through. Return to the app and try again.',
        ),
      );
  } catch (err) {
    // Details go to the server log, never to the user.
    console.error('[chapa-return] verification failed:', err);
    return res
      .status(500)
      .send(
        render(
          'error',
          'Could not check the payment',
          'Please return to the app and tap "I paid" to check again.',
        ),
      );
  }
}

/** Only fixed text is passed in here; nothing from the request. */
function render(kind: Kind, title: string, message: string): string {
  const color = { success: '#0b8a3e', pending: '#8a6d0b', fail: '#b8860b', error: '#b00020' }[kind];
  const bg = { success: '#eafaf0', pending: '#fff8e1', fail: '#fff8e1', error: '#fdecea' }[kind];

  return `<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<style>
  body { font-family: -apple-system, Segoe UI, Roboto, sans-serif; background: ${bg}; color: ${color};
         display:flex; align-items:center; justify-content:center; min-height:100vh; margin:0; padding:16px; box-sizing:border-box; }
  .card { background:#fff; padding:32px 28px; border-radius:12px; box-shadow:0 4px 24px rgba(0,0,0,0.06); max-width:420px; text-align:center; }
  h1 { margin:0 0 10px; font-size:22px; }
  p { margin:6px 0; color:#444; font-size:15px; line-height:1.5; }
</style></head><body>
<div class="card">
  <h1>${title}</h1>
  <p>${message}</p>
</div></body></html>`;
}