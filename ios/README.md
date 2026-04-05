# Teatower iOS App

Native SwiftUI app — Tea Profile, purchase history, Claude recommendations, Gowalla-style badges.

## Requirements

- Xcode 16+
- iOS 17+
- Swift 5.9+

## Setup

1. Open `ios/Teatower/` in Xcode
2. Add Supabase package: `https://github.com/supabase-community/supabase-swift.git` (v2.0+)
3. Build & run on simulator or device

## Configuration

The app connects to Supabase (configured in `SupabaseManager.swift`).

For Claude recommendations, set `ANTHROPIC_API_KEY` in your Xcode scheme environment variables.

## Deep Link

Magic Link auth uses the `teatower://` URL scheme (configured in Info.plist).

## TestFlight

1. Set your Team & Bundle ID in Xcode signing
2. Archive → Distribute → App Store Connect
3. In App Store Connect → TestFlight → add testers

## Architecture

```
TeatowerApp (entry)
├── Auth: Magic Link (Supabase)
├── Tea Profile: view + edit + onboarding quiz
├── Purchase History: unified POS + Shopify
├── Badges: Gowalla-style collectibles (29 badges)
├── Recommendations: Claude API (Trevor sommelier)
├── Store Locator: MapKit (3 stores)
└── Settings: account, notifications, RGPD
```

## Backend

- **Supabase** (PostgreSQL): `audience` table, email as PK
- **Sync scripts**: `scripts/sync_shopify.py`, `sync_odoo.py`, `sync_mailchimp.py`
- **50,848 profiles** unified from 3 sources
