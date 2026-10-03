/**
 * Normalize an Ethiopian phone number to E.164: +2519XXXXXXXX or +2517XXXXXXXX.
 * Accepts: 0911223344, 911223344, 251911223344, +251911223344, with spaces/dashes.
 * Returns null if the number can't be normalized to a valid Ethiopian mobile.
 */
export function normalizeEthiopianPhone(input: string): string | null {
  if (!input) return null;

  // strip everything except digits
  let s = String(input).trim().replace(/[\s\-()]/g, '');
  s = s.replace(/\D/g, '');
  if (!s) return null;

  // Convert to 9-digit local (starting with 9 or 7)
  let local9: string | null = null;

  if (s.length === 9 && (s.startsWith('9') || s.startsWith('7'))) {
    local9 = s;
  } else if (s.length === 10 && s.startsWith('0')) {
    const body = s.slice(1);
    if (body.startsWith('9') || body.startsWith('7')) local9 = body;
  } else if (s.length === 12 && s.startsWith('251')) {
    const body = s.slice(3);
    if (body.startsWith('9') || body.startsWith('7')) local9 = body;
  }

  if (!local9) return null;
  return `+251${local9}`;
}

export function isValidEthiopianPhone(input: string): boolean {
  return normalizeEthiopianPhone(input) !== null;
}