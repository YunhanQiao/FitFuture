import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const BUCKET = process.env.SUPABASE_STORAGE_BUCKET ?? 'fitfuture-photos';

export const storageService = {
  async upload(path: string, data: Buffer, contentType: string): Promise<void> {
    const { error } = await supabase.storage
      .from(BUCKET)
      .upload(path, data, { contentType, upsert: false });
    if (error) throw new Error(`Storage upload failed: ${error.message}`);
  },

  async getSignedUrl(path: string, expiresInSeconds = 3600): Promise<string> {
    const { data, error } = await supabase.storage
      .from(BUCKET)
      .createSignedUrl(path, expiresInSeconds);
    if (error || !data) throw new Error(`Failed to generate signed URL: ${error?.message}`);
    return data.signedUrl;
  },

  async delete(path: string): Promise<void> {
    const { error } = await supabase.storage.from(BUCKET).remove([path]);
    if (error) throw new Error(`Storage delete failed: ${error.message}`);
  },
};
