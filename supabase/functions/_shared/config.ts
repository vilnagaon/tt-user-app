// Teatower Sync Engine — Shared Configuration
// All API credentials loaded from Supabase Edge Function secrets

export const SHOPIFY = {
  shop: '263f0b-3.myshopify.com',
  clientId: Deno.env.get('SHOPIFY_CLIENT_ID') || '',
  clientSecret: Deno.env.get('SHOPIFY_CLIENT_SECRET') || '',
  apiVersion: '2025-01',
};

export const ODOO = {
  url: 'https://tea-tree.odoo.com/jsonrpc',
  db: 'tsc-be-tea-tree-main-18515272',
  login: Deno.env.get('ODOO_LOGIN') || '',
  apiKey: Deno.env.get('ODOO_API_KEY') || '',
  uid: 15,
};

export const MAILCHIMP = {
  apiKey: Deno.env.get('MAILCHIMP_API_KEY') || '',
  dc: 'us13',
  listId: '3c28234aea',
};

export const POS_CONFIG_MAP: Record<number, string> = {
  1: 'pos_waterloo',
  2: 'pos_popup',
  3: 'pos_liege',
  4: 'pos_namur',
  5: 'pos_liege', // "Liège bis" → Liège
};

export function normalizeEmail(email: string | null | undefined): string | null {
  if (!email) return null;
  return email.toLowerCase().trim();
}
