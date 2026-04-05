import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { SHOPIFY, normalizeEmail } from '../_shared/config.ts';
import { getServiceClient, upsertAudience, insertPurchase, recomputeMetrics, autoTag, logSync } from '../_shared/supabase.ts';

async function getShopifyToken(): Promise<string> {
  const res = await fetch(`https://${SHOPIFY.shop}/admin/oauth/access_token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=client_credentials&client_id=${SHOPIFY.clientId}&client_secret=${SHOPIFY.clientSecret}`,
  });
  const data = await res.json();
  return data.access_token;
}

async function graphql(token: string, query: string, variables?: Record<string, unknown>) {
  const res = await fetch(`https://${SHOPIFY.shop}/admin/api/${SHOPIFY.apiVersion}/graphql.json`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Shopify-Access-Token': token,
    },
    body: JSON.stringify({ query, variables }),
  });
  return res.json();
}

serve(async (_req) => {
  const db = getServiceClient();
  const logId = await logSync(db, 'shopify', 'running');
  let processed = 0, created = 0, updated = 0;

  try {
    const token = await getShopifyToken();

    // Get last sync time
    const { data: lastSync } = await db
      .from('sync_log')
      .select('finished_at')
      .eq('source', 'shopify')
      .eq('status', 'success')
      .order('finished_at', { ascending: false })
      .limit(1)
      .single();

    const since = lastSync?.finished_at || '2025-01-01T00:00:00Z';

    // Fetch customers updated since last sync
    let hasNext = true;
    let cursor: string | null = null;

    while (hasNext) {
      const query = `
        query ($cursor: String) {
          customers(first: 50, after: $cursor, query: "updated_at:>'${since}'") {
            edges {
              node {
                id email firstName lastName phone
                defaultAddress { address1 city zip country }
                ordersCount
                totalSpent
                createdAt updatedAt
                orders(first: 10, sortKey: CREATED_AT, reverse: true) {
                  edges {
                    node {
                      id name createdAt
                      totalPriceSet { shopMoney { amount } }
                      lineItems(first: 20) {
                        edges {
                          node { title quantity sku
                            originalTotalSet { shopMoney { amount } }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            pageInfo { hasNextPage endCursor }
          }
        }
      `;

      const result = await graphql(token, query, { cursor });
      const edges = result.data?.customers?.edges || [];
      const pageInfo = result.data?.customers?.pageInfo;

      for (const { node: customer } of edges) {
        const email = normalizeEmail(customer.email);
        if (!email) continue;
        processed++;

        // Check if exists
        const { data: existing } = await db
          .from('audience')
          .select('email')
          .eq('email', email)
          .single();

        if (existing) updated++;
        else created++;

        // Upsert audience record
        await upsertAudience(db, email, {
          first_name: customer.firstName || undefined,
          last_name: customer.lastName || undefined,
          phone: customer.phone || undefined,
          address_street: customer.defaultAddress?.address1 || undefined,
          address_city: customer.defaultAddress?.city || undefined,
          address_zip: customer.defaultAddress?.zip || undefined,
          address_country: customer.defaultAddress?.country || undefined,
          source_shopify: true,
          shopify_customer_id: customer.id,
        });

        // Upsert orders
        for (const { node: order } of customer.orders?.edges || []) {
          const items = (order.lineItems?.edges || []).map((e: any) => ({
            sku: e.node.sku,
            name: e.node.title,
            qty: e.node.quantity,
            price: parseFloat(e.node.originalTotalSet?.shopMoney?.amount || '0'),
          }));

          await insertPurchase(db, {
            email,
            source: 'shopify',
            source_order_id: order.id,
            order_date: order.createdAt,
            total: parseFloat(order.totalPriceSet?.shopMoney?.amount || '0'),
            items,
          });
        }

        // Recompute
        await recomputeMetrics(db, email);
        await autoTag(db, email);
      }

      hasNext = pageInfo?.hasNextPage || false;
      cursor = pageInfo?.endCursor || null;
    }

    await logSync(db, 'shopify', 'success', {
      records_processed: processed,
      records_created: created,
      records_updated: updated,
    });

    return new Response(JSON.stringify({ ok: true, processed, created, updated }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    await logSync(db, 'shopify', 'error', {
      error_message: error.message,
      records_processed: processed,
    });
    return new Response(JSON.stringify({ ok: false, error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
