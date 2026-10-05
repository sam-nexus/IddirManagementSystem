interface PushPayload {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

interface PushResult {
  success: boolean;
  error?: string;
}

/**
 * Sends a push notification via Firebase Cloud Messaging.
 *
 * Currently a stub — logs to console and returns success.
 * To enable real push later:
 *   1. npm install firebase-admin
 *   2. Download service-account JSON from Firebase console
 *   3. Set FIREBASE_SERVICE_ACCOUNT_JSON in .env (base64-encoded JSON)
 *   4. Initialize admin.initializeApp({ credential: admin.credential.cert(...) })
 *   5. Replace the body below with admin.messaging().send(...)
 */
export async function sendPush(payload: PushPayload): Promise<PushResult> {
  const enabled = String(process.env.PUSH_PROVIDER ?? 'console').toLowerCase() === 'firebase';
  if (!enabled) {
    console.log(`[push:console] → ${payload.token.slice(0, 12)}***`);
    console.log(`  title: ${payload.title}`);
    console.log(`  body : ${payload.body}`);
    return { success: true };
  }

  // Real Firebase dispatch — enable when ready
  // try {
  //   const admin = await import('firebase-admin');
  //   await admin.messaging().send({
  //     token: payload.token,
  //     notification: { title: payload.title, body: payload.body },
  //     data: payload.data,
  //   });
  //   return { success: true };
  // } catch (err: any) {
  //   return { success: false, error: err.message };
  // }

  return { success: true };
}