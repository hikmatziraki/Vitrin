# VOIDRUN

Server-authoritative, mobile-first sci-fi exploration/management game. Free entry, no staking, no profit promises, wallet features disabled by default.

## Stack
Next.js App Router + TypeScript + Tailwind v4 + Supabase Postgres/Auth + optional Upstash Redis + Vercel.

## Local setup
1. Copy `.env.example` to `.env.local`.
2. Add Supabase URL and publishable key. Never expose a service-role key to the browser.
3. Run `db/migrations/0001_voidrun_core.sql` in Supabase SQL Editor or via Supabase CLI.
4. `npm install && npm run dev`.
5. `npm run typecheck && npm test && npm run build`.

## Admin
Set `VOIDRUN_ADMIN_EMAIL` to the development admin email. Admin routes compare the authenticated email server-side.

## Vercel
Import this repository, set environment variables, and use `npm run build`. Add Upstash variables when provisioned. Wallet routes intentionally return disabled until Phase 4.

## Economy safeguards
All mutations are server-side. Market buys use PostgreSQL row locks. Balance values live in `balance_config`. Ledger entries are append-only. Withdrawals are disabled until Phase 4.
