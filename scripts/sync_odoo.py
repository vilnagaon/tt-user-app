import os
"""Sync Odoo POS partners + orders → Supabase audience + purchases."""
import json
import urllib.request
import ssl

# Config
ODOO_URL = "https://tea-tree.odoo.com/jsonrpc"
ODOO_DB = "tsc-be-tea-tree-main-18515272"
ODOO_UID = 15
ODOO_KEY = os.environ["ODOO_API_KEY"]
SB_URL = "https://lmqzufwcoyojsyrvkegh.supabase.co"
SB_KEY = os.environ["SUPABASE_SERVICE_KEY"]

POS_MAP = {1: "pos_waterloo", 2: "pos_popup", 3: "pos_liege", 4: "pos_namur", 5: "pos_liege"}

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

print("=== SYNC ODOO POS → SUPABASE ===")

# 1. Fetch all partners with email
print("\n--- Partners ---")
partners = odoo_rpc("res.partner", "search_read",
    [["email", "!=", False], ["customer_rank", ">", 0]],
    {"fields": ["id", "name", "email", "phone", "street", "city", "zip"], "limit": 15000}
)
print(f"  {len(partners)} partners with email found")

partner_map = {}
batch = []
for p in partners:
    email = (p.get("email") or "").lower().strip()
    if not email or "@" not in email:
        continue
    partner_map[p["id"]] = email
    name_parts = (p.get("name") or "").split(" ", 1)
    batch.append({
        "email": email,
        "first_name": name_parts[0] if name_parts else None,
        "last_name": name_parts[1] if len(name_parts) > 1 else None,
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

# 2. Fetch POS orders (since 2025-01-01)
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
            "items": "[]",  # Will enrich with line items in Sprint 2
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
print(f"\nDone: {len(batch)} partners + {total_orders} POS orders from Odoo")
