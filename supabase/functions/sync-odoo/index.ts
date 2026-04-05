import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { ODOO, POS_CONFIG_MAP, normalizeEmail } from '../_shared/config.ts';
import { getServiceClient, upsertAudience, insertPurchase, recomputeMetrics, autoTag, logSync } from '../_shared/supabase.ts';

async function odooRpc(model: string, method: string, args: unknown[], kwargs?: Record<string, unknown>) {
  const res = await fetch(ODOO.url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      jsonrpc: '2.0',
      method: 'call',
      id: 1,
      params: {
        service: 'object',
        method: 'execute_kw',
        args: [ODOO.db, ODOO.uid, ODOO.apiKey, model, method, args, kwargs || {}],
      },
    }),
  });
  const data = await res.json();
  if (data.error) throw new Error(data.error.data?.message || 'Odoo RPC error');
  return data.result;
}

serve(async (_req) => {
  const db = getServiceClient();
  await logSync(db, 'odoo', 'running');
  let processed = 0, created = 0, updated = 0;

  try {
    // Get last sync time
    const { data: lastSync } = await db
      .from('sync_log')
      .select('finished_at')
      .eq('source', 'odoo')
      .eq('status', 'success')
      .order('finished_at', { ascending: false })
      .limit(1)
      .single();

    const since = lastSync?.finished_at || '2025-01-01 00:00:00';

    // 1. Fetch POS orders with partner emails
    const orders = await odooRpc('pos.order', 'search_read', [
      [['date_order', '>=', since], ['partner_id', '!=', false]],
    ], {
      fields: ['id', 'name', 'date_order', 'amount_total', 'config_id', 'partner_id', 'lines'],
      order: 'date_order asc',
      limit: 500,
    });

    // Collect unique partner IDs
    const partnerIds = [...new Set(orders.map((o: any) => o.partner_id[0]))];

    // 2. Fetch partner details
    const partners = partnerIds.length > 0
      ? await odooRpc('res.partner', 'search_read', [
          [['id', 'in', partnerIds]],
        ], {
          fields: ['id', 'name', 'email', 'phone', 'street', 'city', 'zip', 'country_id'],
          limit: 500,
        })
      : [];

    const partnerMap = new Map(partners.map((p: any) => [p.id, p]));

    // 3. Fetch order lines for product details
    const allLineIds = orders.flatMap((o: any) => o.lines || []);
    const lines = allLineIds.length > 0
      ? await odooRpc('pos.order.line', 'search_read', [
          [['id', 'in', allLineIds]],
        ], {
          fields: ['id', 'order_id', 'product_id', 'qty', 'price_subtotal_incl'],
          limit: 5000,
        })
      : [];

    // Group lines by order
    const linesByOrder = new Map<number, any[]>();
    for (const line of lines) {
      const orderId = line.order_id[0];
      if (!linesByOrder.has(orderId)) linesByOrder.set(orderId, []);
      linesByOrder.get(orderId)!.push(line);
    }

    // 4. Process each order
    const processedEmails = new Set<string>();

    for (const order of orders) {
      const partner = partnerMap.get(order.partner_id[0]);
      if (!partner) continue;

      const email = normalizeEmail(partner.email);
      if (!email) continue;
      processed++;

      // Parse partner name
      const nameParts = (partner.name || '').split(' ');
      const firstName = nameParts[0] || '';
      const lastName = nameParts.slice(1).join(' ') || '';

      // Determine store
      const configId = order.config_id?.[0];
      const source = POS_CONFIG_MAP[configId] || 'pos_namur';

      // Upsert audience
      const { data: existing } = await db
        .from('audience')
        .select('email')
        .eq('email', email)
        .single();

      if (existing) updated++;
      else created++;

      await upsertAudience(db, email, {
        first_name: firstName || undefined,
        last_name: lastName || undefined,
        phone: partner.phone || undefined,
        address_street: partner.street || undefined,
        address_city: partner.city || undefined,
        address_zip: partner.zip || undefined,
        source_odoo: true,
        odoo_partner_id: partner.id,
      });

      // Build order items
      const orderLines = linesByOrder.get(order.id) || [];
      const items = orderLines.map((l: any) => ({
        sku: l.product_id?.[1]?.match(/\[([^\]]+)\]/)?.[1] || '',
        name: l.product_id?.[1]?.replace(/\[.*?\]\s*/, '') || '',
        qty: l.qty,
        price: l.price_subtotal_incl,
      }));

      // Insert purchase
      await insertPurchase(db, {
        email,
        source,
        source_order_id: `odoo-${order.id}`,
        order_date: order.date_order,
        total: order.amount_total,
        items,
      });

      processedEmails.add(email);
    }

    // 5. Recompute metrics for all affected emails
    for (const email of processedEmails) {
      await recomputeMetrics(db, email);
      await autoTag(db, email);
    }

    await logSync(db, 'odoo', 'success', {
      records_processed: processed,
      records_created: created,
      records_updated: updated,
      records_matched: updated, // updated = matched existing record
    });

    return new Response(JSON.stringify({ ok: true, processed, created, updated }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    await logSync(db, 'odoo', 'error', {
      error_message: error.message,
      records_processed: processed,
    });
    return new Response(JSON.stringify({ ok: false, error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
