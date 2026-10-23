import axios from 'axios';
import { env, isProd } from '../config/env';

interface SendResult {
  success: boolean;
  provider: string;
  messageId?: string;
  campaignId?: string;
  error?: string;
}

function maskPhone(phone: string): string {
  if (phone.length < 6) return '***';
  return phone.slice(0, 4) + '***' + phone.slice(-4);
}

/**
 * Extracts a readable error from Afro Message's response.
 * Their failures use the same { acknowledge, response } envelope.
 */
function extractErrorMessage(data: any): string | undefined {
  if (!data) return undefined;
  if (data.response?.message) return String(data.response.message);
  if (data.response?.status) return String(data.response.status);
  if (data.message) return String(data.message);
  if (typeof data === 'string') return data;
  return JSON.stringify(data).slice(0, 200);
}

// ---------------------------------------------------------------------------
// Single SMS
// ---------------------------------------------------------------------------

async function sendViaAfroMessage(
  phone: string,
  message: string
): Promise<SendResult> {
  try {
    const res = await axios.post(
      'https://api.afromessage.com/api/send',
      {
        from: env.AFROMESSAGE_IDENTIFIER_ID,
        sender: env.AFROMESSAGE_SENDER_NAME,
        to: phone,
        message,
      },
      {
        headers: {
          Authorization: `Bearer ${env.AFROMESSAGE_TOKEN}`,
          'Content-Type': 'application/json',
        },
        timeout: 15_000,
      }
    );

    const data = res.data ?? {};
    const ok = data?.acknowledge === 'success';

    return {
      success: ok,
      provider: 'afromessage',
      messageId: data?.response?.message_id,
      error: ok ? undefined : extractErrorMessage(data),
    };
  } catch (err: any) {
    const errData = err?.response?.data;
    return {
      success: false,
      provider: 'afromessage',
      error: extractErrorMessage(errData) ?? err.message,
    };
  }
}

/**
 * Send a single SMS. Never throws — failures are logged and returned.
 */
export async function sendSms(
  phone: string,
  message: string
): Promise<SendResult> {
  console.log(`[sms] → ${maskPhone(phone)} (${message.length} chars)`);

  if (env.SMS_PROVIDER === 'console' || (!isProd && !env.AFROMESSAGE_TOKEN)) {
    console.log(`[sms:console] ${maskPhone(phone)}\n  └─ ${message}`);
    return { success: true, provider: 'console' };
  }

  const result = await sendViaAfroMessage(phone, message);
  if (!result.success) {
    console.error(`[sms] failed for ${maskPhone(phone)}: ${result.error}`);
  }
  return result;
}

// ---------------------------------------------------------------------------
// Bulk SMS
// ---------------------------------------------------------------------------

export interface BulkRecipient {
  phone: string;
  message: string;
}

/**
 * Sends multiple SMS in one API call. Each recipient can have a different
 * message (needed for the bilingual announcements).
 *
 * Afro Message's bulk endpoint takes a single API call and returns a
 * campaign_id that can be tracked in their dashboard.
 */
export async function sendBulkSms(
  recipients: BulkRecipient[]
): Promise<SendResult> {
  if (recipients.length === 0) {
    return { success: true, provider: 'afromessage' };
  }

  console.log(`[sms:bulk] → ${recipients.length} recipients`);

  if (env.SMS_PROVIDER === 'console' || (!isProd && !env.AFROMESSAGE_TOKEN)) {
    for (const r of recipients) {
      console.log(`[sms:console:bulk] ${maskPhone(r.phone)}\n  └─ ${r.message}`);
    }
    return { success: true, provider: 'console' };
  }

  try {
    const res = await axios.post(
      'https://api.afromessage.com/api/bulk_send',
      {
        from: env.AFROMESSAGE_IDENTIFIER_ID,
        sender: env.AFROMESSAGE_SENDER_NAME,
        to: recipients.map((r) => ({ to: r.phone, message: r.message })),
      },
      {
        headers: {
          Authorization: `Bearer ${env.AFROMESSAGE_TOKEN}`,
          'Content-Type': 'application/json',
        },
        timeout: 30_000,
      }
    );

    const data = res.data ?? {};
    const ok = data?.acknowledge === 'success';

    if (!ok) {
      console.error(`[sms:bulk] failed: ${extractErrorMessage(data)}`);
    }

    return {
      success: ok,
      provider: 'afromessage',
      campaignId: data?.response?.campaign_id,
      error: ok ? undefined : extractErrorMessage(data),
    };
  } catch (err: any) {
    const errData = err?.response?.data;
    const msg = extractErrorMessage(errData) ?? err.message;
    console.error(`[sms:bulk] error: ${msg}`);
    return { success: false, provider: 'afromessage', error: msg };
  }
}