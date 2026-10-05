import { Request, Response } from 'express';
import { verifyChapaPayment } from './contributions.service';

/**
 * Landing page Chapa redirects to after payment.
 * Public (no auth) — Chapa's redirect carries no JWT.
 *
 * We do NOT trust the query params. We call Chapa's verify endpoint via our
 * service, which updates the DB only if Chapa confirms success.
 */
export async function chapaReturn(req: Request, res: Response) {
  const txRef = String(req.query.tx_ref ?? '');
  const statusFromChapa = String(req.query.status ?? '');

  if (!txRef) {
    return res.status(400).send(render('Missing tx_ref', 'fail', null));
  }

  try {
    const result = await verifyChapaPayment(txRef, {
      actorId: null,
      ip: req.clientIp,
      userAgent: req.userAgentHeader,
      lang: req.lang,
    });

    const ok = result.status === 'success';
    return res.status(200).send(
      render(
        ok ? 'Payment successful' : 'Payment not completed',
        ok ? 'success' : 'fail',
        { tx_ref: txRef, receipt_no: (result as any).receipt_no, status: result.status }
      )
    );
  } catch (err: any) {
    return res.status(500).send(
      render('Could not verify payment', 'error', {
        tx_ref: txRef,
        chapa_status: statusFromChapa,
        error: err.message,
      })
    );
  }
}

function render(
  title: string,
  kind: 'success' | 'fail' | 'error',
  data: Record<string, unknown> | null
): string {
  const colors = { success: '#0b8a3e', fail: '#b8860b', error: '#b00020' };
  const bg = { success: '#eafaf0', fail: '#fff8e1', error: '#fdecea' };
  return `<!doctype html>
<html><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<style>
  body { font-family: -apple-system, Segoe UI, Roboto, sans-serif; background: ${bg[kind]}; color: ${colors[kind]};
         display:flex; align-items:center; justify-content:center; min-height:100vh; margin:0; }
  .card { background:#fff; padding:32px 40px; border-radius:12px; box-shadow:0 4px 24px rgba(0,0,0,0.06); max-width:420px; text-align:center; }
  h1 { margin:0 0 8px; font-size:22px; }
  p { margin:6px 0; color:#444; font-size:14px; }
  code { background:#f4f4f4; padding:2px 6px; border-radius:4px; font-size:13px; }
</style></head><body>
<div class="card">
  <h1>${title}</h1>
  ${data ? `<p><strong>Tx Ref:</strong> <code>${data.tx_ref ?? '-'}</code></p>` : ''}
  ${data && data.receipt_no ? `<p><strong>Receipt:</strong> <code>${data.receipt_no}</code></p>` : ''}
  ${data && data.status ? `<p><strong>Status:</strong> ${data.status}</p>` : ''}
  ${data && data.error ? `<p><strong>Error:</strong> ${data.error}</p>` : ''}
  <p style="margin-top:18px;color:#888;font-size:12px;">You may now close this page.</p>
</div></body></html>`;
}