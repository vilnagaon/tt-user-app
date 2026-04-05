import os
"""Sync Mailchimp members → Supabase audience table."""
import json
import urllib.request
import ssl
from base64 import b64encode

# Config
MC_API_KEY = os.environ["MAILCHIMP_API_KEY"]
MC_DC = "us13"
MC_LIST = "3c28234aea"
SB_URL = "https://lmqzufwcoyojsyrvkegh.supabase.co"
SB_KEY = os.environ["SUPABASE_SERVICE_KEY"]

ctx = ssl.create_default_context()

def mc_get(path):
    auth = b64encode(f"anystring:{MC_API_KEY}".encode()).decode()
    req = urllib.request.Request(
        f"https://{MC_DC}.api.mailchimp.com/3.0{path}",
        headers={"Authorization": f"Basic {auth}"}
    )
    with urllib.request.urlopen(req, context=ctx) as resp:
        return json.loads(resp.read())

def sb_upsert(table, records):
    data = json.dumps(records).encode()
    req = urllib.request.Request(
        f"{SB_URL}/rest/v1/{table}",
        data=data,
        method="POST",
        headers={
            "apikey": SB_KEY,
            "Authorization": f"Bearer {SB_KEY}",
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

# Sync
print("=== SYNC MAILCHIMP → SUPABASE ===")
offset = 0
count = 100
total = 0
created = 0
batch_num = 0

while True:
    data = mc_get(f"/lists/{MC_LIST}/members?count={count}&offset={offset}&fields=members.email_address,members.merge_fields,members.status,members.id,members.stats,members.tags,members.member_rating&status=subscribed")
    members = data.get("members", [])
    if not members:
        break

    batch = []
    for m in members:
        email = m["email_address"].lower().strip()
        batch.append({
            "email": email,
            "first_name": m.get("merge_fields", {}).get("FNAME") or None,
            "last_name": m.get("merge_fields", {}).get("LNAME") or None,
            "status": m.get("status", "subscribed"),
            "source_mailchimp": True,
            "mailchimp_member_id": m.get("id"),
            "custom_fields": json.dumps({
                "mc_rating": m.get("member_rating"),
                "mc_open_rate": m.get("stats", {}).get("avg_open_rate"),
                "mc_click_rate": m.get("stats", {}).get("avg_click_rate"),
                "mc_tags": [t["name"] for t in m.get("tags", [])],
            }),
        })

    status = sb_upsert("audience", batch)
    total += len(batch)
    batch_num += 1

    if batch_num % 10 == 0:
        print(f"  Batch {batch_num}: {total} members synced...")

    offset += count
    if len(members) < count:
        break

print(f"\nDone: {total} Mailchimp members synced to Supabase")
