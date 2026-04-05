import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { MAILCHIMP, normalizeEmail } from '../_shared/config.ts';
import { getServiceClient, upsertAudience, logSync } from '../_shared/supabase.ts';

async function mcFetch(path: string) {
  const res = await fetch(`https://${MAILCHIMP.dc}.api.mailchimp.com/3.0${path}`, {
    headers: {
      'Authorization': `Basic ${btoa('anystring:' + MAILCHIMP.apiKey)}`,
      'Content-Type': 'application/json',
    },
  });
  return res.json();
}

async function mcPatch(path: string, body: Record<string, unknown>) {
  const res = await fetch(`https://${MAILCHIMP.dc}.api.mailchimp.com/3.0${path}`, {
    method: 'PATCH',
    headers: {
      'Authorization': `Basic ${btoa('anystring:' + MAILCHIMP.apiKey)}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  return res.json();
}

serve(async (_req) => {
  const db = getServiceClient();
  await logSync(db, 'mailchimp', 'running');
  let processed = 0, created = 0, updated = 0;

  try {
    // Get last sync time
    const { data: lastSync } = await db
      .from('sync_log')
      .select('finished_at')
      .eq('source', 'mailchimp')
      .eq('status', 'success')
      .order('finished_at', { ascending: false })
      .limit(1)
      .single();

    const since = lastSync?.finished_at || '2025-01-01T00:00:00Z';
    const sinceParam = `&since_last_changed=${encodeURIComponent(since)}`;

    // Paginate through members
    let offset = 0;
    const count = 100;
    let hasMore = true;

    while (hasMore) {
      const data = await mcFetch(
        `/lists/${MAILCHIMP.listId}/members?count=${count}&offset=${offset}&sort_field=last_changed&sort_dir=DESC${sinceParam}`
      );

      const members = data.members || [];
      if (members.length === 0) break;

      for (const member of members) {
        const email = normalizeEmail(member.email_address);
        if (!email) continue;
        processed++;

        const { data: existing } = await db
          .from('audience')
          .select('email')
          .eq('email', email)
          .single();

        if (existing) updated++;
        else created++;

        // Map Mailchimp status
        const statusMap: Record<string, string> = {
          'subscribed': 'subscribed',
          'unsubscribed': 'unsubscribed',
          'cleaned': 'cleaned',
          'pending': 'pending',
          'transactional': 'transactional',
        };

        await upsertAudience(db, email, {
          first_name: member.merge_fields?.FNAME || undefined,
          last_name: member.merge_fields?.LNAME || undefined,
          status: statusMap[member.status] || 'subscribed',
          source_mailchimp: true,
          mailchimp_member_id: member.id,
          custom_fields: {
            mailchimp_rating: member.member_rating,
            mailchimp_open_rate: member.stats?.avg_open_rate,
            mailchimp_click_rate: member.stats?.avg_click_rate,
            mailchimp_tags: member.tags?.map((t: any) => t.name) || [],
          },
        });

        // Sync Mailchimp tags → our tags table
        for (const tag of member.tags || []) {
          await db
            .from('tags')
            .upsert(
              { email, tag: tag.name, source: 'sync_mailchimp' },
              { onConflict: 'email,tag' }
            );
        }
      }

      offset += count;
      hasMore = members.length === count;
    }

    // ── PUSH ENRICHED TAGS BACK TO MAILCHIMP ──
    // Get all audience members that have been enriched by POS/Shopify
    const { data: enriched } = await db
      .from('audience')
      .select('email, preferred_store, lifetime_value, last_purchase_date, mailchimp_member_id')
      .eq('source_mailchimp', true)
      .not('mailchimp_member_id', 'is', null)
      .gt('lifetime_value', 0)
      .limit(200);

    for (const member of enriched || []) {
      // Update merge fields in Mailchimp
      const subscriberHash = member.mailchimp_member_id;
      await mcPatch(`/lists/${MAILCHIMP.listId}/members/${subscriberHash}`, {
        merge_fields: {
          STORE: member.preferred_store || '',
          LTV: member.lifetime_value?.toString() || '0',
          LASTBUY: member.last_purchase_date?.split('T')[0] || '',
        },
      });
    }

    await logSync(db, 'mailchimp', 'success', {
      records_processed: processed,
      records_created: created,
      records_updated: updated,
    });

    return new Response(JSON.stringify({ ok: true, processed, created, updated }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    await logSync(db, 'mailchimp', 'error', {
      error_message: error.message,
      records_processed: processed,
    });
    return new Response(JSON.stringify({ ok: false, error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
