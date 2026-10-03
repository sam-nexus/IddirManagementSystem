import axios from 'axios';
import { env, isProd } from '../config/env';
import { query } from '../config/database';

interface SendResult {
  success: boolean;
  provider: string;
  error?: string;
}

/**
 * Mask a phone number for logs: 0912345678 -> 091***5678
 */
function maskPhone(phone: string): string {
  if (phone.length < 6) return '***';
  return phone.slice(0, 3) + '***' + phone.slice(-4);
}

async function logSms(
  phone: string,
  message: string,
  provider: string,
  status: string,
  error?: string
): Promise<void> {
  try {
    await query(
      `INSERT INTO sms_log (phone, message, provider, status, error) VALUES ($1, $2, $3, $4, $5)`,
      [phone, message, provider, status, error ?? null]
    );
  } catch (err) {
    console.error('[sms] failed to write log:', (err as Error).message);
  }
}

async function sendViaAfroMessage(phone: string, message: string): Promise<SendResult> {
  const url = 'https://api.afromessage.com/api/send';
  const payload = {
    from: env.AFROMESSAGE_IDENTIFIER_ID,
    sender: env.AFROMESSAGE_SENDER_NAME,
    to: phone,
    message,
  };

  try {
    const res = await axios.post(url, payload, {
      headers: {
        Authorization: `Bearer ${env.AFROMESSAGE_TOKEN}`,
        'Content-Type': 'application/json',
      },
      timeout: 15_000,
    });

    const data = res.data ?? {};
    const ok = data?.acknowledge === 'success';
    return {
      success: ok,
      provider: 'afromessage',
      error: ok ? undefined : JSON.stringify(data).slice(0, 200),
    };
  } catch (err: any) {
    return {
      success: false,
      provider: 'afromessage',
      error: err?.response?.data ? JSON.stringify(err.response.data).slice(0, 200) : err.message,
    };
  }
}

/**
 * Send an SMS. Never throws — failures are logged and returned.
 */
export async function sendSms(phone: string, message: string): Promise<SendResult> {
  console.log(`[sms] → ${maskPhone(phone)} (${message.length} chars)`);

  // Dev console mode
  if (env.SMS_PROVIDER === 'console' || !isProd && !env.AFROMESSAGE_TOKEN) {
    console.log(`[sms:console] ${maskPhone(phone)}\n  └─ ${message}`);
    await logSms(phone, message, 'console', 'sent');
    return { success: true, provider: 'console' };
  }

  const result = await sendViaAfroMessage(phone, message);
  await logSms(phone, message, result.provider, result.success ? 'sent' : 'failed', result.error);

  if (!result.success) {
    console.error(`[sms] failed for ${maskPhone(phone)}: ${result.error}`);
  }
  return result;
}