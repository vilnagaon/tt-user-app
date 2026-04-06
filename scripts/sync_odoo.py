import os
"""Sync Odoo POS partners + orders → Supabase audience + purchases + Shopify + Mailchimp customer creation."""
import json
import urllib.request
import ssl
import time
import hashlib
from base64 import b64encode

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

MAILCHIMP_API_KEY = os.environ.get("MAILCHIMP_API_KEY", "")
MAILCHIMP_DC = "us13"
MAILCHIMP_LIST = "3c28234aea"

def parse_odoo_name(full_name):
    """Parse Odoo 'name' field into (first_name, last_name).
    Handles duplicated first names: 'Christian Christian Yerles' → ('Christian', 'Yerles')
    """
    name = full_name.strip()
    if not name:
        return ("", "")
    parts = name.split()
    if len(parts) == 1:
        return (parts[0], "")
    # Check if second word is a duplicate of the first (case-insensitive)
    if parts[1].lower() == parts[0].lower():
        # "Christian Christian Yerles" → first="Christian", last="Yerles"
        return (parts[0], " ".join(parts[2:]))
    else:
        # "Francoise Saint Paul" → first="Francoise", last="Saint Paul"
        return (parts[0], " ".join(parts[1:]))

POS_MAP = {1: "pos_waterloo", 2: "pos_popup", 3: "pos_liege", 4: "pos_namur", 5: "pos_liege"}
STORE_TAGS = {1: "POS-Waterloo", 2: "POS-Popup", 3: "POS-Liège", 4: "POS-Namur", 5: "POS-Liège"}
STORE_MC_TAGS = {"waterloo": "Waterloo", "namur": "Namur", "liege": "Liège", "pos_waterloo": "Waterloo", "pos_namur": "Namur", "pos_liege": "Liège"}

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


# ── MAILCHIMP SUBSCRIBER CREATION ──

def add_to_mailchimp(email, first_name, last_name, store_tag):
    """Add a subscriber to Mailchimp if not already there. Returns True if added."""
    if not MAILCHIMP_API_KEY:
        return False

    auth = b64encode(f"anystring:{MAILCHIMP_API_KEY}".encode()).decode()
    subscriber_hash = hashlib.md5(email.lower().encode()).hexdigest()

    # Check if already exists
    req = urllib.request.Request(
        f"https://{MAILCHIMP_DC}.api.mailchimp.com/3.0/lists/{MAILCHIMP_LIST}/members/{subscriber_hash}",
        headers={"Authorization": f"Basic {auth}"}
    )
    try:
        with urllib.request.urlopen(req, context=ctx) as resp:
            existing = json.loads(resp.read())
            if existing.get("status") in ("subscribed", "unsubscribed", "cleaned", "pending"):
                return False  # Already exists
    except urllib.error.HTTPError as e:
        if e.code != 404:
            return False  # Some other error
        # 404 = not found, proceed to create

    # Create subscriber
    mc_tag = STORE_MC_TAGS.get(store_tag, "Autres")
    body = {
        "email_address": email,
        "status": "subscribed",
        "merge_fields": {
            "FNAME": first_name or "",
            "LNAME": last_name or "",
        },
        "tags": [mc_tag, "auto-sync-odoo"],
    }

    data = json.dumps(body).encode()
    req = urllib.request.Request(
        f"https://{MAILCHIMP_DC}.api.mailchimp.com/3.0/lists/{MAILCHIMP_LIST}/members",
        data=data, method="POST",
        headers={"Authorization": f"Basic {auth}", "Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, context=ctx) as resp:
            return True
    except urllib.error.HTTPError:
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
    first_name, last_name = parse_odoo_name(p.get("name") or "")

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

# 2. Create new partners in Shopify + Mailchimp (only those not already there)
print("\n--- Shopify + Mailchimp Customer Creation ---")
mailchimp_created = 0
mailchimp_skipped = 0

for p in partners:
    email = (p.get("email") or "").lower().strip()
    if not email or "@" not in email:
        continue

    # Skip if blocked (bounced/unsubscribed)
    if sb_check_blocked(email):
        shopify_skipped += 1
        mailchimp_skipped += 1
        continue

    first_name, last_name = parse_odoo_name(p.get("name") or "")
    store = p.get("city") or ""

    # Shopify
    if not sb_check_exists(email):
        created = create_shopify_customer(
            email, first_name, last_name,
            p.get("phone"), p.get("city"), p.get("zip"),
            "POS-client"
        )
        if created:
            shopify_created += 1
            sb_upsert("audience", [{"email": email, "source_shopify": True}])
    else:
        shopify_skipped += 1

    # Mailchimp
    mc_added = add_to_mailchimp(email, first_name, last_name, store.lower() if store else "")
    if mc_added:
        mailchimp_created += 1
        sb_upsert("audience", [{"email": email, "source_mailchimp": True}])
    else:
        mailchimp_skipped += 1

    # Rate limit
    total_calls = shopify_created + shopify_skipped + mailchimp_created + mailchimp_skipped
    if total_calls % 8 == 0:
        time.sleep(1)
    if (shopify_created + mailchimp_created) % 50 == 0 and (shopify_created + mailchimp_created) > 0:
        print(f"  Shopify: {shopify_created} created | Mailchimp: {mailchimp_created} created")

print(f"  Shopify: {shopify_created} created, {shopify_skipped} skipped")
print(f"  Mailchimp: {mailchimp_created} created, {mailchimp_skipped} skipped")

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
print(f"\nDone: {len(batch)} partners + {total_orders} orders + {shopify_created} Shopify + {mailchimp_created} Mailchimp")
