-- ============================================================================
-- Teatower User App — Database Schema
-- Migration 001: Core tables (audience, tags, purchases, sync_log)
-- Model: Mailchimp-style audience with email as primary key
-- ============================================================================

-- ── AUDIENCE ────────────────────────────────────────────────────────────────
-- One record per email. The single source of truth for every Teatower customer.
-- Enriched by syncs from Shopify, Odoo POS, and Mailchimp.

CREATE TABLE audience (
  email TEXT PRIMARY KEY CHECK (email = lower(trim(email))),

  -- Identity
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  birth_date DATE,
  language TEXT DEFAULT 'fr',

  -- Address
  address_street TEXT,
  address_city TEXT,
  address_zip TEXT,
  address_country TEXT DEFAULT 'BE',

  -- Status (Mailchimp-style)
  status TEXT DEFAULT 'subscribed' CHECK (status IN (
    'subscribed',
    'unsubscribed',
    'cleaned',
    'transactional',
    'pending'
  )),

  -- Source flags
  source_shopify BOOLEAN DEFAULT false,
  source_odoo BOOLEAN DEFAULT false,
  source_mailchimp BOOLEAN DEFAULT false,
  source_app BOOLEAN DEFAULT false,

  -- External IDs (for bidirectional sync)
  shopify_customer_id TEXT,
  odoo_partner_id INTEGER,
  mailchimp_member_id TEXT,

  -- Preferred store (computed from POS purchases)
  preferred_store TEXT CHECK (preferred_store IN (
    'waterloo', 'namur', 'liege', 'online', NULL
  )),

  -- Computed metrics (refreshed by sync engine)
  lifetime_value DECIMAL(10,2) DEFAULT 0,
  total_orders INTEGER DEFAULT 0,
  total_orders_pos INTEGER DEFAULT 0,
  total_orders_online INTEGER DEFAULT 0,
  avg_basket DECIMAL(10,2) DEFAULT 0,
  first_purchase_date TIMESTAMPTZ,
  last_purchase_date TIMESTAMPTZ,
  last_activity_date TIMESTAMPTZ,

  -- Tea Profile (the heart of the app)
  tea_profile JSONB DEFAULT '{}',

  -- Extensible custom fields (like Mailchimp merge fields)
  custom_fields JSONB DEFAULT '{}',

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  synced_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_audience_store ON audience(preferred_store);
CREATE INDEX idx_audience_status ON audience(status);
CREATE INDEX idx_audience_ltv ON audience(lifetime_value DESC);
CREATE INDEX idx_audience_last_purchase ON audience(last_purchase_date DESC);
CREATE INDEX idx_audience_shopify ON audience(shopify_customer_id) WHERE shopify_customer_id IS NOT NULL;
CREATE INDEX idx_audience_odoo ON audience(odoo_partner_id) WHERE odoo_partner_id IS NOT NULL;
CREATE INDEX idx_audience_mailchimp ON audience(mailchimp_member_id) WHERE mailchimp_member_id IS NOT NULL;

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audience_updated_at
  BEFORE UPDATE ON audience
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── TAGS ────────────────────────────────────────────────────────────────────
-- Segmentation tags, like Mailchimp tags but enriched with commerce data.

CREATE TABLE tags (
  email TEXT REFERENCES audience(email) ON DELETE CASCADE,
  tag TEXT NOT NULL,
  added_at TIMESTAMPTZ DEFAULT now(),
  source TEXT DEFAULT 'auto', -- 'auto' | 'manual' | 'sync_mailchimp' | 'sync_shopify'
  PRIMARY KEY (email, tag)
);

CREATE INDEX idx_tags_tag ON tags(tag);
CREATE INDEX idx_tags_email ON tags(email);

-- ── PURCHASES ───────────────────────────────────────────────────────────────
-- Unified purchase history from Shopify + Odoo POS.

CREATE TABLE purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL REFERENCES audience(email) ON DELETE CASCADE,

  source TEXT NOT NULL CHECK (source IN (
    'shopify', 'pos_waterloo', 'pos_namur', 'pos_liege'
  )),
  source_order_id TEXT,

  order_date TIMESTAMPTZ NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'EUR',

  items JSONB NOT NULL DEFAULT '[]',

  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(source, source_order_id)
);

CREATE INDEX idx_purchases_email ON purchases(email);
CREATE INDEX idx_purchases_date ON purchases(order_date DESC);
CREATE INDEX idx_purchases_source ON purchases(source);

-- ── SYNC LOG ────────────────────────────────────────────────────────────────
-- Audit trail for all sync operations.

CREATE TABLE sync_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source TEXT NOT NULL,
  started_at TIMESTAMPTZ DEFAULT now(),
  finished_at TIMESTAMPTZ,
  status TEXT DEFAULT 'running' CHECK (status IN ('running', 'success', 'error')),
  records_processed INTEGER DEFAULT 0,
  records_created INTEGER DEFAULT 0,
  records_updated INTEGER DEFAULT 0,
  records_matched INTEGER DEFAULT 0,
  error_message TEXT,
  details JSONB
);

-- ── ROW LEVEL SECURITY ─────────────────────────────────────────────────────
-- Each authenticated user can only read their own record.

ALTER TABLE audience ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;

-- Users can read their own data (matched by auth email)
CREATE POLICY "Users read own audience record"
  ON audience FOR SELECT
  USING (email = auth.email());

CREATE POLICY "Users read own tags"
  ON tags FOR SELECT
  USING (email = auth.email());

CREATE POLICY "Users read own purchases"
  ON purchases FOR SELECT
  USING (email = auth.email());

-- Users can update their own tea_profile and custom_fields
CREATE POLICY "Users update own profile"
  ON audience FOR UPDATE
  USING (email = auth.email())
  WITH CHECK (email = auth.email());

-- Service role (sync engine) can do everything
-- (Supabase service_role key bypasses RLS by default)

-- ── COMPUTED METRICS FUNCTION ───────────────────────────────────────────────
-- Recalculates LTV, order counts, preferred store, etc. for a given email.

CREATE OR REPLACE FUNCTION recompute_metrics(target_email TEXT)
RETURNS VOID AS $$
DECLARE
  stats RECORD;
  fav_store TEXT;
BEGIN
  SELECT
    COALESCE(SUM(total), 0) as ltv,
    COUNT(*) as total_orders,
    COUNT(*) FILTER (WHERE source != 'shopify') as pos_orders,
    COUNT(*) FILTER (WHERE source = 'shopify') as online_orders,
    COALESCE(AVG(total), 0) as avg_basket,
    MIN(order_date) as first_purchase,
    MAX(order_date) as last_purchase
  INTO stats
  FROM purchases
  WHERE email = target_email;

  -- Most frequent store
  SELECT source INTO fav_store
  FROM purchases
  WHERE email = target_email
  GROUP BY source
  ORDER BY COUNT(*) DESC
  LIMIT 1;

  -- Map POS sources to store names
  fav_store := CASE fav_store
    WHEN 'pos_waterloo' THEN 'waterloo'
    WHEN 'pos_namur' THEN 'namur'
    WHEN 'pos_liege' THEN 'liege'
    WHEN 'shopify' THEN 'online'
    ELSE NULL
  END;

  UPDATE audience SET
    lifetime_value = stats.ltv,
    total_orders = stats.total_orders,
    total_orders_pos = stats.pos_orders,
    total_orders_online = stats.online_orders,
    avg_basket = stats.avg_basket,
    first_purchase_date = stats.first_purchase,
    last_purchase_date = stats.last_purchase,
    preferred_store = COALESCE(fav_store, preferred_store),
    synced_at = now()
  WHERE email = target_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── AUTO-TAG FUNCTION ───────────────────────────────────────────────────────
-- Automatically assigns tags based on purchase data and metrics.

CREATE OR REPLACE FUNCTION auto_tag(target_email TEXT)
RETURNS VOID AS $$
DECLARE
  rec RECORD;
BEGIN
  SELECT * INTO rec FROM audience WHERE email = target_email;
  IF NOT FOUND THEN RETURN; END IF;

  -- VIP (LTV > 500€)
  IF rec.lifetime_value > 500 THEN
    INSERT INTO tags (email, tag, source) VALUES (target_email, 'vip', 'auto')
    ON CONFLICT DO NOTHING;
  END IF;

  -- Multi-canal
  IF rec.total_orders_pos > 0 AND rec.total_orders_online > 0 THEN
    INSERT INTO tags (email, tag, source) VALUES (target_email, 'multi_canal', 'auto')
    ON CONFLICT DO NOTHING;
  END IF;

  -- Dormant (no purchase in 180 days)
  IF rec.last_purchase_date < now() - INTERVAL '180 days' THEN
    INSERT INTO tags (email, tag, source) VALUES (target_email, 'dormant', 'auto')
    ON CONFLICT DO NOTHING;
  ELSE
    DELETE FROM tags WHERE email = target_email AND tag = 'dormant';
  END IF;

  -- New customer (first purchase < 30 days)
  IF rec.first_purchase_date > now() - INTERVAL '30 days' THEN
    INSERT INTO tags (email, tag, source) VALUES (target_email, 'nouveau', 'auto')
    ON CONFLICT DO NOTHING;
  ELSE
    DELETE FROM tags WHERE email = target_email AND tag = 'nouveau';
  END IF;

  -- Store tags
  IF rec.preferred_store IS NOT NULL THEN
    INSERT INTO tags (email, tag, source)
    VALUES (target_email, 'client_' || rec.preferred_store, 'auto')
    ON CONFLICT DO NOTHING;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
