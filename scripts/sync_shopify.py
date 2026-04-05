import os
"""Sync Shopify customers + orders → Supabase audience + purchases."""
import json
import urllib.request
import ssl

# Config
SHOP = "263f0b-3.myshopify.com"
CLIENT_ID = os.environ["SHOPIFY_CLIENT_ID"]
CLIENT_SECRET = os.environ["SHOPIFY_CLIENT_SECRET"]
API_VERSION = "2025-01"
SB_URL = "https://lmqzufwcoyojsyrvkegh.supabase.co"
SB_KEY = os.environ["SUPABASE_SERVICE_KEY"]

ctx = ssl.create_default_context()

def get_token():
    data = f"grant_type=client_credentials&client_id={CLIENT_ID}&client_secret={CLIENT_SECRET}".encode()
    req = urllib.request.Request(f"https://{SHOP}/admin/oauth/access_token", data=data, method="POST")
    with urllib.request.urlopen(req, context=ctx) as resp:
        return json.loads(resp.read())["access_token"]

def graphql(token, query, variables=None):
    payload = json.dumps({"query": query, "variables": variables or {}}).encode()
    req = urllib.request.Request(
        f"https://{SHOP}/admin/api/{API_VERSION}/graphql.json",
        data=payload,
        headers={"Content-Type": "application/json", "X-Shopify-Access-Token": token}
    )
    with urllib.request.urlopen(req, context=ctx) as resp:
        return json.loads(resp.read())

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
        if "duplicate" not in body:
            print(f"  Error: {e.code} {body[:200]}")
        return e.code

CUSTOMERS_QUERY = """
query ($cursor: String) {
  customers(first: 100, after: $cursor, sortKey: UPDATED_AT) {
    edges {
      node {
        id email firstName lastName phone
        defaultAddress { address1 city zip countryCodeV2 }
        numberOfOrders
        amountSpent { amount }
        createdAt
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""

ORDERS_QUERY = """
query ($cursor: String) {
  orders(first: 100, after: $cursor, sortKey: CREATED_AT, query: "created_at:>2025-01-01") {
    edges {
      node {
        id name createdAt
        email
        totalPriceSet { shopMoney { amount } }
        lineItems(first: 20) {
          edges {
            node { title quantity sku originalTotalSet { shopMoney { amount } } }
          }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
"""

print("=== SYNC SHOPIFY → SUPABASE ===")
token = get_token()
print(f"  Token obtained")

# 1. Sync customers
print("\n--- Customers ---")
cursor = None
total_customers = 0

while True:
    result = graphql(token, CUSTOMERS_QUERY, {"cursor": cursor})
    edges = result.get("data", {}).get("customers", {}).get("edges", [])
    page_info = result.get("data", {}).get("customers", {}).get("pageInfo", {})

    batch = []
    for edge in edges:
        c = edge["node"]
        email = (c.get("email") or "").lower().strip()
        if not email:
            continue
        addr = c.get("defaultAddress") or {}
        batch.append({
            "email": email,
            "first_name": c.get("firstName"),
            "last_name": c.get("lastName"),
            "phone": c.get("phone"),
            "address_street": addr.get("address1"),
            "address_city": addr.get("city"),
            "address_zip": addr.get("zip"),
            "address_country": addr.get("countryCodeV2"),
            "source_shopify": True,
            "shopify_customer_id": c.get("id"),
        })

    if batch:
        sb_upsert("audience", batch)
        total_customers += len(batch)

    if total_customers % 500 == 0 and total_customers > 0:
        print(f"  {total_customers} customers...")

    if not page_info.get("hasNextPage"):
        break
    cursor = page_info.get("endCursor")

print(f"  Total: {total_customers} customers synced")

# 2. Sync orders
print("\n--- Orders ---")
cursor = None
total_orders = 0
skipped = 0

while True:
    result = graphql(token, ORDERS_QUERY, {"cursor": cursor})
    edges = result.get("data", {}).get("orders", {}).get("edges", [])
    page_info = result.get("data", {}).get("orders", {}).get("pageInfo", {})

    batch = []
    for edge in edges:
        o = edge["node"]
        email = (o.get("email") or "").lower().strip()
        if not email:
            skipped += 1
            continue

        items = []
        for li in (o.get("lineItems", {}).get("edges", []) or []):
            n = li["node"]
            items.append({
                "sku": n.get("sku") or "",
                "name": n.get("title", ""),
                "qty": n.get("quantity", 0),
                "price": float(n.get("originalTotalSet", {}).get("shopMoney", {}).get("amount", 0)),
            })

        batch.append({
            "email": email,
            "source": "shopify",
            "source_order_id": o["id"],
            "order_date": o["createdAt"],
            "total": float(o.get("totalPriceSet", {}).get("shopMoney", {}).get("amount", 0)),
            "items": json.dumps(items),
        })

    if batch:
        sb_upsert("purchases", batch)
        total_orders += len(batch)

    if total_orders % 500 == 0 and total_orders > 0:
        print(f"  {total_orders} orders...")

    if not page_info.get("hasNextPage"):
        break
    cursor = page_info.get("endCursor")

print(f"  Total: {total_orders} orders synced ({skipped} skipped - no email)")
print(f"\nDone: {total_customers} customers + {total_orders} orders from Shopify")
