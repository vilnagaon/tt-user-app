import os
"""Recompute metrics and auto-tags for all audience members with purchases."""
import json
import urllib.request
import ssl

SB_URL = "https://lmqzufwcoyojsyrvkegh.supabase.co"
SB_KEY = os.environ["SUPABASE_SERVICE_KEY"]
DB_CONN = f"postgresql://postgres.lmqzufwcoyojsyrvkegh:{os.environ['SUPABASE_DB_PASSWORD']}@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

import subprocess

def psql(sql):
    result = subprocess.run(
        ["/opt/homebrew/opt/libpq/bin/psql", DB_CONN, "-t", "-A", "-c", sql],
        capture_output=True, text=True
    )
    return result.stdout.strip()

print("=== RECOMPUTE METRICS & AUTO-TAGS ===")

# Get all emails that have purchases
emails_raw = psql("SELECT DISTINCT email FROM purchases;")
emails = [e.strip() for e in emails_raw.split("\n") if e.strip() and "@" in e]
print(f"Found {len(emails)} emails with purchases")

for i, email in enumerate(emails):
    escaped = email.replace("'", "''")
    psql(f"SELECT recompute_metrics('{escaped}');")
    psql(f"SELECT auto_tag('{escaped}');")
    if (i + 1) % 100 == 0:
        print(f"  {i+1}/{len(emails)} processed...")

print(f"\nDone: {len(emails)} profiles recomputed")

# Summary stats
print("\n=== SUMMARY ===")
print(psql("""
SELECT
  count(*) as total_audience,
  count(*) FILTER (WHERE source_shopify) as from_shopify,
  count(*) FILTER (WHERE source_odoo) as from_odoo,
  count(*) FILTER (WHERE source_mailchimp) as from_mailchimp,
  count(*) FILTER (WHERE source_shopify AND source_odoo) as multi_shop_pos,
  count(*) FILTER (WHERE source_shopify AND source_mailchimp) as multi_shop_mc,
  count(*) FILTER (WHERE source_odoo AND source_mailchimp) as multi_pos_mc,
  count(*) FILTER (WHERE source_shopify AND source_odoo AND source_mailchimp) as all_three,
  count(*) FILTER (WHERE lifetime_value > 0) as with_purchases,
  count(*) FILTER (WHERE lifetime_value > 500) as vip,
  round(avg(lifetime_value) FILTER (WHERE lifetime_value > 0), 2) as avg_ltv
FROM audience;
"""))

print("\n--- Tags ---")
print(psql("SELECT tag, count(*) as n FROM tags GROUP BY tag ORDER BY n DESC LIMIT 15;"))

print("\n--- Preferred store ---")
print(psql("SELECT preferred_store, count(*) as n FROM audience WHERE preferred_store IS NOT NULL GROUP BY preferred_store ORDER BY n DESC;"))
