# VOIDRUN

VOIDRUN is a server-authoritative, mobile-first sci-fi exploration/management strategy game. Free entry. No staking. No profit promises. Wallet features are disabled by default.

## Architecture
- Next.js 16 App Router + TypeScript + Tailwind CSS v4
- Supabase Postgres + Auth as persistence/authentication
- Next.js Route Handlers as the only mutation authority
- Optional Upstash Redis for rate limits and distributed locks
- Vercel-ready production build
- PWA manifest included

## Repository map
```text
app/                 Next.js routes and screens
components/          shared UI/navigation
lib/server/          authentication, Redis, rate limiting, authority helpers
lib/balance/         server-safe balance formulas
db/migrations/       Supabase schema + seed data
tests/               economy formula tests
```

## Local setup
1. `git clone` the repository.
2. Copy `.env.example` to `.env.local`.
3. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`.
4. For admin routes set `VOIDRUN_ADMIN_EMAIL`.
5. Run both SQL migrations in order: `db/migrations/0001_voidrun_core.sql`, then `db/migrations/0002_voidrun_complete.sql`.
6. Enable Anonymous Sign-Ins in Supabase Authentication because the guest flow uses `signInAnonymously()`.
7. `npm install`.
8. `npm run dev`.
9. Verify with `npm run typecheck && npm test && npm run build`.

Never put `SUPABASE_SERVICE_ROLE_KEY` in client code or `NEXT_PUBLIC_*` variables.

## Supabase
The database contains the core player state, four modules, energy, explorers, items, crafting, missions, decision events, P2P market, atomic trades, ledger, guilds, raids, seasons, leaderboard snapshots, achievements, balance configuration, audit logs, risk scores, economy metrics and launch content.

`balance_config` is the source of truth for balancing. Change balance values there rather than hard-coding production values in UI components.

## Vercel
Import the GitHub repository and keep the project root at `/`. Build command: `npm run build`. Add these environment variables in Vercel:

```text
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
SUPABASE_SERVICE_ROLE_KEY       # server-only, if used by server helpers
UPSTASH_REDIS_REST_URL          # optional until Redis is provisioned
UPSTASH_REDIS_REST_TOKEN        # optional until Redis is provisioned
VOIDRUN_ADMIN_EMAIL
```

Deploy after the Supabase migrations have succeeded. Wallet endpoints intentionally return disabled until Phase 4.

## Security model
- Clients send intents, not authoritative outcomes.
- Sensitive mutations execute through server-side Supabase RPCs.
- Market purchase uses `SELECT ... FOR UPDATE` inside a PostgreSQL function.
- Ledger writes are server-controlled and the table is documented as append-only.
- Rate limiting and distributed locking can be enabled with Upstash.
- Admin routes require the configured authenticated admin email.
- Wallet is never required to play.

## Economy
Credit is the abundant, non-tradable soft currency. Void Shards are scarce off-chain utility units. No staking yield, no pay-to-enter, no pay-to-win, and no withdrawal before Phase 4.

Market tax: 5% total = 2% burn + 2% treasury + 1% reward pool. Listing fee = 2 Credit.

Module cost: `C0 × 1.35^(L−1)`.
Module time: `T0 × 1.25^(L−1)`.
Mission probability: `clamp(0.15, 0.95, 0.75 + 0.15×StatMatch + 0.10×GearScore − 0.9×HazardEffective − Fatigue)`.

## Launch content
- 5 exploration tiers + Raid
- 60 recipes
- 40 learnable decision events
- 12 explorer catalog entries
- 30 cosmetics
- 8-week season configuration

## Legal copy
Void Shards are in-game utility items, not investments. No profit is promised. Regional restrictions may apply. Minimum age requirements depend on jurisdiction.
