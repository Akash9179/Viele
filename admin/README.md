# Viele Admin Console

Super-admin / ops console for Viele (Next.js App Router + TypeScript, Supabase). This slice ships moderation review; users / posts / analytics / content+audit are follow-on plans.

## Prerequisites
- Node ≥ 20
- A Supabase account flagged admin: `app_metadata.role = 'admin'` (the console is admin-gated)

## Setup
```bash
npm install
cp .env.local.example .env.local   # fill in the two NEXT_PUBLIC_* values
npm run dev                         # http://localhost:3000 → /login
```

## Env vars
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`

(Client-safe publishable key only — no service-role key in this app.)

## Scripts
- `npm run dev` — local dev server
- `npm test` — Vitest suite
- `npm run build` — production build

## Deploy (Vercel)
Import the `admin/` directory as a Vercel project. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` in the project's environment variables. Non-admins are redirected to `/unauthorized`; unauthenticated users to `/login`.
