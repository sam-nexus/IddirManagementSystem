import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { env } from '../config/env';

let client: SupabaseClient | null = null;

function getClient(): SupabaseClient {
  if (client) return client;

  if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error(
      'Supabase Storage not configured: set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env'
    );
  }

  client = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return client;
}

export interface UploadResult {
  path: string;         // e.g. "manual-payments/uuid.jpg"
  signedUrl: string;    // time-limited URL for viewing
  fullPath: string;     // storage://bucket/path — store this in DB
}

/**
 * Upload a file buffer to Supabase Storage and return a signed URL.
 * @param folder subfolder inside the bucket
 * @param buffer file contents
 * @param contentType MIME type e.g. image/jpeg
 * @param originalName original filename (used for extension only)
 * @param ttlSeconds signed URL validity (default 7 days)
 */
export async function uploadFile(
  folder: string,
  buffer: Buffer,
  contentType: string,
  originalName: string,
  ttlSeconds = 7 * 24 * 3600
): Promise<UploadResult> {
  const supabase = getClient();
  const bucket = env.SUPABASE_STORAGE_BUCKET;

  const ext = (originalName.split('.').pop() ?? 'bin').toLowerCase().slice(0, 8);
  const filename = `${Date.now()}-${Math.random().toString(36).slice(2, 10)}.${ext}`;
  const path = `${folder}/${filename}`;

  const { error } = await supabase.storage.from(bucket).upload(path, buffer, {
    contentType,
    cacheControl: '3600',
    upsert: false,
  });

  if (error) throw new Error(`Storage upload failed: ${error.message}`);

  const { data: signed, error: signedErr } = await supabase.storage
    .from(bucket)
    .createSignedUrl(path, ttlSeconds);

  if (signedErr || !signed?.signedUrl) {
    throw new Error(`Storage sign URL failed: ${signedErr?.message ?? 'unknown'}`);
  }

  return {
    path,
    signedUrl: signed.signedUrl,
    fullPath: `storage://${bucket}/${path}`,
  };
}

/**
 * Re-sign an existing path (used when reading a receipt/proof later).
 */
export async function signUrl(path: string, ttlSeconds = 7 * 24 * 3600): Promise<string> {
  const supabase = getClient();
  const bucket = env.SUPABASE_STORAGE_BUCKET;

  const { data, error } = await supabase.storage.from(bucket).createSignedUrl(path, ttlSeconds);
  if (error || !data?.signedUrl) {
    throw new Error(`Storage sign URL failed: ${error?.message ?? 'unknown'}`);
  }
  return data.signedUrl;
}

export async function deleteFile(path: string): Promise<void> {
  const supabase = getClient();
  const bucket = env.SUPABASE_STORAGE_BUCKET;
  const { error } = await supabase.storage.from(bucket).remove([path]);
  if (error) throw new Error(`Storage delete failed: ${error.message}`);
}