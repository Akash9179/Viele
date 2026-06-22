# Viele Admin Console — Design Spec

*Date: 2026-06-21 · Status: approved design, pending implementation plan*

## 1. Purpose & goals

A web-based **super-admin / ops console** for the Viele founders. Its first job is
to unblock public TestFlight: give founders a real **moderation review path**
(today `moderation_queue()` / `moderate_post()` exist but have no UI). Beyond
that it is a **full ops console** — users, posts, analytics, and content/seed
management — so the team can run the product during testing.

Success criteria:
- A founder can sign in, see open reports, and **remove / dismiss / restore** a
  post or **suspend** a user in a couple of clicks.
- Real, accurate operational metrics at a glance.
- No privileged secret ever reaches the browser; weight is never displayed.
- Looks best-in-class (Linear/Vercel-grade), recognizably Viele.

## 2. Scope

**In (v1):**
1. Login + admin authorization gate
2. Overview / analytics (KPIs + simple trends)
3. Moderation queue (posts + users) with actions
4. Users browser (search, inspect, suspend/unsuspend/ban)
5. Posts browser (filter, force remove/restore)
6. Content & seed management (tear down seed bots; danger-zone ops)
7. Audit log (read of `admin_actions`)

**Out (later):** granting admin role via UI, push/notifications, in-app comms to
users, A/B/experiment tooling, billing.

## 3. Architecture

- **Location:** new app at `admin/` in the repo (sibling to `app/`). Separate
  package, separate Vercel project. Does **not** share code with the Flutter app.
- **Framework:** Next.js (App Router) + TypeScript. Deployed to **Vercel**.
- **Supabase clients (pinned versions, lockfile committed):**
  - `@supabase/supabase-js` + `@supabase/ssr` for cookie-based auth (browser +
    server components/route handlers).
  - **Two data paths:**
    1. **Admin-as-user** — the admin's JWT calls the existing `is_admin()`-gated
       RPCs (`moderation_queue`, `moderate_post`) and RLS-readable tables.
    2. **Privileged server tier** — Next.js **route handlers only** (`app/api/*`),
       using the **service role from server env** (`SUPABASE_SERVICE_ROLE_KEY`,
       never in the client bundle) for actions RLS can't express: suspend/ban an
       auth user, cross-table analytics aggregates, seed teardown. Each handler
       re-verifies the caller is an admin before acting.
- **Why a server tier:** suspension and analytics exceed RLS-gated RPC
  capabilities; doing them server-side keeps the service role off the client.

## 4. Auth & authorization

- Email/password sign-in via Supabase Auth (`@supabase/ssr`, cookie session).
- Authorization source of truth: **`app_metadata.role === 'admin'`** (per
  CLAUDE.md — claims live in `app_metadata`, never `user_metadata`). Mirrors the
  DB `is_admin()` helper.
- **Middleware** (`middleware.ts`) checks the role claim on every route except
  `/login`; non-admins get a "not authorized" page and a sign-out.
- Every privileged `app/api/*` route independently re-checks admin before using
  the service role (defense in depth — never trust the middleware alone).
- Admins are flagged manually (SQL/Management API) for v1; no UI to grant admin.

## 5. Screens

1. **Login** — email/password; redirect to Overview on success; clear error on
   non-admin.
2. **Overview** — KPI cards (open reports, auto-removed 24h, new signups, posts
   today, total users/posts) + simple trend lines (signups/day, posts/day,
   reports/day). Tabular numerals. Data from analytics RPCs / server aggregates.
3. **Moderation queue** — rows from `moderation_queue()` (post + user targets),
   reason chips, distinct-reporter counts, status (open / auto-removed). Row
   actions: **Remove / Restore** (post → `moderate_post`), **Dismiss**, and
   **Suspend** (user). Clicking a row opens a detail drawer (the post media +
   caption, or the user's profile + their posts/reports).
4. **Users** — search by username/name; list of public profile fields only
   (**weight never shown**); detail view with their posts, reports against them,
   follower/following counts; actions **Suspend / Unsuspend / Ban**.
5. **Posts** — browse/filter all posts (status, author, date); force
   **Remove / Restore**; jump to author. Thumbnails from `post-media`.
6. **Content & seed** — one-click **tear down seed demo bots** (the TestFlight
   gate), with a typed confirmation; danger-zone for destructive ops.
7. **Audit log** — reverse-chronological `admin_actions` (who did what, when).

## 6. Backend additions (migrations — write + apply to live)

Mostly additive (new columns/RPCs/edge function) to `mdgublyyxcgpwvnmnlxe`, plus
**predicate extensions to existing reads** (`profiles_select`, `posts_select`,
`feed()`, `recommend_people()`) so suspended/banned users drop out — backward-safe
(only adds an exclusion; no column/shape changes). Verify with the integration
test after applying.

- **User suspension/ban:**
  - `profiles.suspended_at timestamptz null`, `profiles.banned_at timestamptz null`.
  - RLS: hide suspended/banned users' profiles + posts from non-admin reads
    (extend `profiles_select` / `posts_select` and `feed()` / `recommend_people()`
    predicates to exclude `suspended_at`/`banned_at` not null).
  - An `is_suspended()` helper or inline predicate.
  - Edge function `admin-suspend-user` (service role): sets the flag, records an
    `admin_actions` row, and **revokes the user's sessions** (auth admin
    `signOut`/`deleteSessions`) so suspension takes effect immediately. Admin-gated.
- **Analytics:** admin-only aggregate RPCs (SECURITY DEFINER, `is_admin()`-guarded)
  — e.g. `admin_overview()` returning counts (users, posts, open reports,
  signups/posts last 24h/7d) and `admin_timeseries(metric, days)` for the trend
  charts. Revoke from anon; grant authenticated (guarded internally).
- Reuse existing: `moderation_queue()`, `moderate_post()`, `admin_actions`,
  `is_admin()`. Run `get_advisors` after DDL.

## 7. Design system (Linear/Vercel-grade, Viele-tinted — approved via mockup)

- **Palette:** canvas `#FAF8F4`, surface `#FFFFFF`, ink `#1E1A14`, ink-2
  `#766C5C`, ink-3 `#A89C88`, hairline `#ECE4D6` / `#E2D8C6`, accent (primary /
  active) Viele **match-green `#1F7D4A`** (+ soft `#E7F2EA`), danger `#C0392B`,
  warning `#B9772A`, sand fill `#F3EEE4`.
- **Type:** SF Pro (Display for headings, Text for body); **tabular numerals**
  wherever numbers matter (metrics, counts, dates).
- **Layout:** fixed left sidebar (Overview · Moderation · Users · Posts · Content
  & seed · Audit) + main area with page header, optional KPI strip, dense data
  tables. Radius 8–10px, soft shadows, hairline separators. Keyboard-friendly.
- **Components:** Sidebar, PageHeader, KpiCard, DataTable (sortable, hover rows),
  ReasonChip, StatusPill, ActionButton (default/danger/ghost), DetailDrawer,
  ConfirmDialog (typed confirm for destructive), Toast. Component-first, each with
  one clear responsibility.
- **Principle:** no generic-admin-template look; restrained, one accent, real
  density. Reference specs: Vercel / Stripe / Linear.

## 8. Security & conventions (CLAUDE.md)

- `service_role` only in server env (route handlers / edge functions); never in
  the client bundle. Publishable key for browser.
- RLS on every new column/table; UPDATE policies carry both USING and WITH CHECK.
- **Never** expose `weight_kg` in any admin read payload.
- Pin all package versions; commit the lockfile.
- Re-verify admin server-side on every privileged call.

## 9. Build sequence (each slice shippable)

1. Scaffold `admin/` (Next.js + TS + @supabase/ssr) + design tokens + shell
   (sidebar, page header) + login + admin gate.
2. **Moderation queue** + detail drawer + `moderate_post` actions (TestFlight
   unblock).
3. Suspension migration + edge function; **Users** browser + suspend/ban.
4. **Posts** browser + force remove/restore.
5. Analytics migrations + **Overview**.
6. **Content & seed** (seed teardown) + **Audit log**.
7. Deploy to Vercel; smoke-test each screen with a real admin account.

## 10. Testing

- Component tests for table/actions/auth-gate logic.
- A throwaway **admin** account (flag `role=admin`) to verify the gated flows
  end-to-end against live (mirrors the app's self-cleaning QA pattern).
- Verify non-admins are fully locked out (middleware + per-route).
- `get_advisors` clean after migrations; confirm weight never appears in payloads.

## 11. Open/assumed

- Admin role granted manually for v1 (no UI). ✓ assumed.
- Vercel as host. ✓ decided.
- Suspension hides content + revokes sessions; ban = stronger/permanent flag
  (same enforcement, separate field for clarity).
