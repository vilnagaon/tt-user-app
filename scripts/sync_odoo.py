import os
"""Sync Odoo POS partners + orders → Supabase audience + purchases + Shopify customer creation."""
import json
import urllib.request
import ssl
import time

# Config
ODOO_URL = "https://tea-tree.odoo.com/jsonrpc"
ODOO_DB = "tsc-be-tea-tree-main-18515272"
ODOO_UID = 15
ODOO_KEY = os.environ["ODOO_API_KEY"]
SB_URL = "https://lmqzufwcoyojsyrvkegh.supabase.co"
SB_KEY = os.environ["SUPABASE_SERVICE_KEY"]
SHOPIFY_SHOP = "263f0b-3.myshopify.com"
SHOPIFY_CLIENT_ID = os.environ.get("SHOPIFY_CLIENT_ID", "")
SHOPIFY_CLIENT_SECRET = os.environ.get("SHOPIFY_CLIENT_SECRET", "")
SHOPIFY_API_VERSION = "2025-01"

POS_MAP = {1: "pos_waterloo", 2: "pos_popup", 3: "pos_liege", 4: "pos_namur", 5: "pos_liege"}
STORE_TAGS = {1: "POS-Waterloo", 2: "POS-Popup", 3: "POS-Liège", 4: "POS-Namur", 5: "POS-Liège"}

ctx = ssl.create_default_context()

def odoo_rpc(model, method, domain, kwargs=None):
    payload = json.dumps({
        "jsonrpc": "2.0", "method": "call", "id": 1,
        "params": {
            "service": "object", "method": "execute_kw",
            "args": [ODOO_DB, ODOO_UID, ODOO_KEY, model, method, [domain], kwargs or {}]
        }
    }).encode()
    req = urllib.request.Request(ODOO_URL, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, context=ctx, timeout=60) as resp:
        r = json.loads(resp.read())
        if "error" in r:
            raise Exception(r["error"]["data"]["message"])
        return r["result"]

def sb_upsert(table, records):
    data = json.dumps(records).encode()
    req = urllib.request.Request(
        f"{SB_URL}/rest/v1/{table}",
        data=data, method="POST",
        headers={
            "apikey": SB_KEY, "Authorization": f"Bearer {SB_KEY}",
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates",
        }
    )
    try:
        with urllib.request.urlopen(req, context=ctx) as resp:
            return resp.status
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        if "duplicate" not in body and "already exists" not in body:
            print(f"  Error: {e.code} {body[:300]}")
        return e.code

def sb_check_exists(email):
    """Check if email is already a Shopify customer in Supabase."""
    req = urllib.request.Request(
        f"{SB_URL}/rest/v1/audience?email=eq.{urllib.parse.quote(email)}&select=source_shopify",
        headers={"apikey": SB_KEY, "Authorization": f"Bearer {SB_KEY}"}
    )
    try:
        with urllib.request.urlopen(req, context=ctx) as resp:
            data = json.loads(resp.read())
            return data[0].get("source_shopify", False) if data else False
    except:
        return False

def sb_check_blocked(email):
    """Check if email is bounced or unsubscribed."""
    req = urllib.request.Request(
        f"{SB_URL}/rest/v1/tags?email=eq.{urllib.parse.quote(email)}&tag=in.(mc_bounced,mc_unsubscribed)&select=tag",
        headers={"apikey": SB_KEY, "Authorization": f"Bearer {SB_KEY}"}
    )
    try:
        with urllib.request.urlopen(req, context=ctx) as resp:
            data = json.loads(resp.read())
            return len(data) > 0
    except:
        return False

# ── SHOPIFY CUSTOMER CREATION ──

_shopify_token = None

def get_shopify_token():
    global _shopify_token
    if _shopify_token:
        return _shopify_token
    if not SHOPIFY_CLIENT_ID or not SHOPIFY_CLIENT_SECRET:
        return None
    data = f"grant_type=client_credentials&client_id={SHOPIFY_CLIENT_ID}&client_secret={SHOPIFY_CLIENT_SECRET}".encode()
    req = urllib.request.Request(f"https://{SHOPIFY_SHOP}/admin/oauth/access_token", data=data, method="POST")
    with urllib.request.urlopen(req, context=ctx) as resp:
        _shopify_token = json.loads(resp.read())["access_token"]
    return _shopify_token

def create_shopify_customer(email, first_name, last_name, phone, city, zip_code, store_tag):
    """Create a customer in Shopify if not already there. Returns True if created."""
    token = get_shopify_token()
    if not token:
        return False

    mutation = """
    mutation customerCreate($input: CustomerInput!) {
      customerCreate(input: $input) {
        customer { id email }
        userErrors { field message }
      }
    }
    """
    variables = {
        "input": {
            "email": email,
            "firstName": first_name or None,
            "lastName": last_name or None,
            "phone": phone or None,
            "tags": [store_tag, "auto-sync-odoo"],
            "emailMarketingConsent": {
                "marketingState": "SUBSCRIBED",
                "consentUpdatedAt": "2026-04-06T00:00:00Z",
                "marketingOptInLevel": "SINGLE_OPT_IN"
            },
        }
    }
    if city or zip_code:
        variables["input"]["addresses"] = [{
            "city": city or "", "zip": zip_code or "", "countryCode": "BE"
        }]

    payload = json.dumps({"query": mutation, "variables": variables}).encode()
    req = urllib.request.Request(
        f"https://{SHOPIFY_SHOP}/admin/api/{SHOPIFY_API_VERSION}/graphql.json",
        data=payload,
        headers={"Content-Type": "application/json", "X-Shopify-Access-Token": token}
    )
    try:
        with urllib.request.urlopen(req, context=ctx) as resp:
            result = json.loads(resp.read())
        errs = result.get("data", {}).get("customerCreate", {}).get("userErrors", [])
        if errs:
            msg = errs[0].get("message", "")
            if "taken" not in msg.lower():
                pass  # silently skip "already exists"
            return False
        return True
    except:
        return False


# ══════════════════════════════════════════════════
# MAIN SYNC
# ══════════════════════════════════════════════════

import urllib.parse

print("=== SYNC ODOO POS → SUPABASE + SHOPIFY ===")

# 1. Fetch all partners with email
print("\n--- Partners ---")
partners = odoo_rpc("res.partner", "search_read",
    [["email", "!=", False], ["customer_rank", ">", 0]],
    {"fields": ["id", "name", "email", "phone", "street", "city", "zip"], "limit": 15000}
)
print(f"  {len(partners)} partners with email found")

partner_map = {}
batch = []
shopify_created = 0
shopify_skipped = 0

for p in partners:
    email = (p.get("email") or "").lower().strip()
    if not email or "@" not in email:
        continue
    partner_map[p["id"]] = email
    name_parts = (p.get("name") or "").split(" ", 1)
    first_name = name_parts[0] if name_parts else ""
    last_name = name_parts[1] if len(name_parts) > 1 else ""

    batch.append({
        "email": email,
        "first_name": first_name or None,
        "last_name": last_name or None,
        "phone": p.get("phone"),
        "address_street": p.get("street"),
        "address_city": p.get("city"),
        "address_zip": p.get("zip"),
        "source_odoo": True,
        "odoo_partner_id": p["id"],
    })

# Batch upsert partners (100 at a time)
for i in range(0, len(batch), 100):
    chunk = batch[i:i+100]
    sb_upsert("audience", chunk)
    if (i // 100) % 10 == 0 and i > 0:
        print(f"  {i} partners upserted...")

print(f"  {len(batch)} partners synced to audience")

# 2. Create new partners in Shopify (only those not already there)
print("\n--- Shopify Customer Creation ---")
for p in partners:
    email = (p.get("email") or "").lower().strip()
    if not email or "@" not in email:
        continue

    # Skip if already in Shopify or blocked
    if sb_check_exists(email):
        shopify_skipped += 1
        continue
    if sb_check_blocked(email):
        shopify_skipped += 1
        continue

    name_parts = (p.get("name") or "").split(" ", 1)
    first_name = name_parts[0] if name_parts else ""
    last_name = name_parts[1] if len(name_parts) > 1 else ""

    created = create_shopify_customer(
        email, first_name, last_name,
        p.get("phone"), p.get("city"), p.get("zip"),
        "POS-client"
    )
    if created:
        shopify_created += 1
        # Mark in Supabase
        sb_upsert("audience", [{"email": email, "source_shopify": True}])

    # Rate limit
    if (shopify_created + shopify_skipped) % 4 == 0:
        time.sleep(1)
    if shopify_created % 50 == 0 and shopify_created > 0:
        print(f"  {shopify_created} Shopify customers created...")

print(f"  {shopify_created} new Shopify customers created, {shopify_skipped} skipped")

# 3. Fetch POS orders (since 2025-01-01)
print("\n--- POS Orders ---")
total_orders = 0
offset = 0
BATCH_SIZE = 200

while True:
    orders = odoo_rpc("pos.order", "search_read",
        [["date_order", ">=", "2025-01-01"], ["partner_id", "!=", False]],
        {"fields": ["id", "name", "date_order", "amount_total", "config_id", "partner_id"],
         "order": "date_order asc", "limit": BATCH_SIZE, "offset": offset}
    )
    if not orders:
        break

    purchase_batch = []
    for o in orders:
        pid = o["partner_id"][0] if o["partner_id"] else None
        email = partner_map.get(pid)
        if not email:
            continue

        config_id = o["config_id"][0] if o["config_id"] else 4
        source = POS_MAP.get(config_id, "pos_namur")

        purchase_batch.append({
            "email": email,
            "source": source,
            "source_order_id": f"odoo-pos-{o['id']}",
            "order_date": o["date_order"],
            "total": o["amount_total"],
            "items": "[]",
        })

    if purchase_batch:
        sb_upsert("purchases", purchase_batch)
        total_orders += len(purchase_batch)

    if total_orders % 1000 == 0 and total_orders > 0:
        print(f"  {total_orders} orders...")

    offset += BATCH_SIZE
    if len(orders) < BATCH_SIZE:
        break

print(f"  {total_orders} POS orders synced to purchases")
print(f"\nDone: {len(batch)} partners + {total_orders} orders + {shopify_created} new Shopify customers")
