import os
"""Sync Shopify product catalog → Supabase products table."""
import json
import urllib.request
import ssl

SHOP = "263f0b-3.myshopify.com"
CLIENT_ID = os.environ.get("SHOPIFY_CLIENT_ID", "")
CLIENT_SECRET = os.environ.get("SHOPIFY_CLIENT_SECRET", "")
SB_URL = "https://lmqzufwcoyojsyrvkegh.supabase.co"
SB_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")

ctx = ssl.create_default_context()

def get_token():
    data = f"grant_type=client_credentials&client_id={CLIENT_ID}&client_secret={CLIENT_SECRET}".encode()
    req = urllib.request.Request(f"https://{SHOP}/admin/oauth/access_token", data=data, method="POST")
    with urllib.request.urlopen(req, context=ctx) as resp:
        return json.loads(resp.read())["access_token"]

def sb_upsert(records):
    data = json.dumps(records).encode()
    req = urllib.request.Request(f"{SB_URL}/rest/v1/products", data=data, method="POST",
        headers={"apikey": SB_KEY, "Authorization": f"Bearer {SB_KEY}",
                 "Content-Type": "application/json", "Prefer": "resolution=merge-duplicates"})
    try:
        with urllib.request.urlopen(req, context=ctx) as resp: return resp.status
    except: return 0

print("=== SYNC PRODUCTS → SUPABASE ===")
token = get_token()

products = []
url = f"https://{SHOP}/admin/api/2025-01/products.json?status=active&limit=250"
while url:
    req = urllib.request.Request(url, headers={"X-Shopify-Access-Token": token})
    with urllib.request.urlopen(req, context=ctx) as resp:
        data = json.loads(resp.read())
        products.extend(data["products"])
        link = resp.headers.get("Link", "")
        url = link.split("<")[1].split(">")[0] if 'rel="next"' in link else None

print(f"  {len(products)} products from Shopify")

batch = []
for p in products:
    if not p.get("variants"): continue
    v = p["variants"][0]
    batch.append({
        "sku": v.get("sku") or str(v["id"]),
        "shopify_product_id": str(p["id"]),
        "shopify_variant_id": str(v["id"]),
        "name": p["title"],
        "category": p.get("product_type") or None,
        "weight_grams": int(v.get("weight", 0) * 1000) if v.get("weight") else None,
        "price_eur": float(v["price"]),
        "barcode": v.get("barcode") or None,
        "image_url": p["images"][0]["src"] if p.get("images") else None,
        "is_active": True,
    })
    if len(batch) >= 50:
        sb_upsert(batch)
        batch = []

if batch: sb_upsert(batch)
print(f"Done: {len(products)} products synced")
