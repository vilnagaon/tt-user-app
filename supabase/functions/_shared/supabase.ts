import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

export function getServiceClient() {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );
}

export async function upsertAudience(
  client: ReturnType<typeof createClient>,
  email: string,
  data: Record<string, unknown>,
) {
  const { error } = await client
    .from('audience')
    .upsert({ email, ...data, updated_at: new Date().toISOString() }, { onConflict: 'email' });

  if (error) throw new Error(`Upsert failed for ${email}: ${error.message}`);
}

export async function insertPurchase(
  client: ReturnType<typeof createClient>,
  purchase: {
    email: string;
    source: string;
    source_order_id: string;
    order_date: string;
    total: number;
    items: unknown[];
  },
) {
  const { error } = await client
    .from('purchases')
    .upsert(purchase, { onConflict: 'source,source_order_id' });

  if (error && !error.message.includes('duplicate')) {
    throw new Error(`Purchase insert failed: ${error.message}`);
  }
}

export async function recomputeMetrics(
  client: ReturnType<typeof createClient>,
  email: string,
) {
  const { error } = await client.rpc('recompute_metrics', { target_email: email });
  if (error) console.error(`Recompute failed for ${email}: ${error.message}`);
}

export async function autoTag(
  client: ReturnType<typeof createClient>,
  email: string,
) {
  const { error } = await client.rpc('auto_tag', { target_email: email });
  if (error) console.error(`Auto-tag failed for ${email}: ${error.message}`);
}

export async function logSync(
  client: ReturnType<typeof createClient>,
  source: string,
  status: 'running' | 'success' | 'error',
  stats?: Record<string, unknown>,
) {
  if (status === 'running') {
    const { data } = await client
      .from('sync_log')
      .insert({ source, status: 'running' })
      .select('id')
      .single();
    return data?.id;
  } else {
    // Update the last running log for this source
    await client
      .from('sync_log')
      .update({
        status,
        finished_at: new Date().toISOString(),
        ...stats,
      })
      .eq('source', source)
      .eq('status', 'running')
      .order('started_at', { ascending: false })
      .limit(1);
  }
}
