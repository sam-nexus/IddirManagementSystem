import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

let initialized = false;

function ensureInitialized(): void {
  if (initialized || getApps().length > 0) {
    initialized = true;
    return;
  }

  const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!json) {
    console.warn('[push] FIREBASE_SERVICE_ACCOUNT_JSON not set — push disabled');
    return;
  }

  try {
    initializeApp({
      credential: cert(JSON.parse(Buffer.from(json, 'base64').toString('utf8'))),
    });
    initialized = true;
    console.log('[push] Firebase Admin initialized');
  } catch (err: any) {
    console.error('[push] init failed:', err.message);
  }
}

export interface PushPayload {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export async function sendPush(payload: PushPayload): Promise<{ success: boolean; error?: string }> {
  ensureInitialized();
  if (!initialized) {
    return { success: false, error: 'Firebase not configured' };
  }

  try {
    await getMessaging().send({
      token: payload.token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data ?? {},
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'odaa_general',
          icon: 'ic_notification',
        },
      },
    });
    return { success: true };
  } catch (err: any) {
    return { success: false, error: err.message };
  }
}