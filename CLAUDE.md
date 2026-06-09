# CLAUDE.md — Viele

Viele is a **personalized fashion discovery mobile app** that matches users to outfits, creators, and clothing based on their body type, proportions, complexion, and aesthetic.

- **Full requirements:** `docs/SRS.md` (the source of truth — requirement IDs, P0/P1/P2 priorities)
- **Source PRD:** `PRD.docx`
- **Project memory / decision log:** `docs/memory.md`
- **Moderation policy:** `docs/moderation.md` (MVP UGC moderation — required because any user can post)
- **Design system:** `docs/design.md` (pending; reference: https://annafashion.lovable.app/)

---

## Stack (locked)
| Layer | Choice |
|---|---|
| Mobile app (primary product) | **Flutter** (iOS + Android) |
| Admin | **React web** super-admin dashboard (separate app) |
| Backend | **Supabase** — Postgres + RLS, Auth (email/Google/Apple), Storage, Realtime, Edge Functions, **pgvector**, pg_cron |
| Body scan | **V2 (deferred — not in MVP).** When built: **Dart port** of Eugene's TS/MediaPipe algorithm — measurement math preserved (see `docs/SRS.md` Appendix 11.4). **MVP uses self-reported onboarding** instead (height, weight, body silhouette, hair/skin/eye color). |

---

## Hard rules — do not violate

### Supabase
- **DEDICATED, ISOLATED PROJECT.** Viele uses its **own brand-new Supabase project**. Never read, modify, migrate, or share anything with any other project on the account (no DB, schema, tables, Auth, Storage, Edge Functions, keys, or env). **Create the project only with explicit user go-ahead.**
- **Verify before implementing.** Supabase APIs/RLS/config change often — check the live changelog/docs at build time; don't rely on memory.
- **RLS on every table** in exposed schemas. Combine `TO authenticated` with an ownership predicate `using ( (select auth.uid()) = user_id )`. UPDATE policies need **both** `USING` and `WITH CHECK`.
- **Authorization claims in `app_metadata` only** — never the user-editable `user_metadata`.
- **Key hygiene.** `service_role`/secret keys live server-side only (Edge Functions). Publishable keys in clients. Never ship `service_role` in the app or the admin browser bundle.
- **Pin package versions and commit lockfiles** (`supabase_flutter`, `@supabase/*`, etc.).

### Privacy by design (sensitive data)
- **MVP attributes are self-reported and PUBLIC.** Height, body silhouette, and hair/skin/eye color are entered in onboarding and shared with others through posts (Eugene, 2026-06-09). These are public profile fields — not owner-only. **Weight is the carve-out: optional, owner-only/private, used only for matching (as a coarse band), and NEVER publicly displayed** (Akash's call, 2026-06-09; slight deviation from Eugene's "all public" — to confirm). Never include `weight_kg` in public profile/post read payloads.
- Still support full account **data export + deletion** (cascading to posts, derived data, and vectors).
- **V2 scan (when built):** raw body-scan video and face photos **NEVER leave the device** — process on-device, persist **only** derived profiles (`BodyProfile`, `ColorProfile`) and vectors. **Always show consent** before any camera capture. The scan is an **estimate, not a medical device** — state this in-product.

### Body scan (V2 — deferred)
- Not in MVP. When porting or changing the scan, **preserve the measurement algorithm** in `docs/SRS.md` Appendix 11.4 (height-anchored pixel→cm scaling, surface-inflation constants, BMI-adjusted Ramanujan-II circumference estimates, `robustMean` outlier rejection, gender-specific shape classification, confidence scoring) and keep its sanity guards (`NOT_VISIBLE`, width ≥ circumference → invalid).

---

## Repo structure (intended)
```
Viele/
├── CLAUDE.md            ← this file (engineering rules)
├── PRD.docx             ← source PRD
├── docs/
│   ├── SRS.md           ← requirements (source of truth)
│   ├── memory.md        ← decision log & living context
│   └── design.md        ← design system (pending)
└── (to scaffold) Flutter app + React admin app
```

## Conventions
- **Phasing:** respect the SRS P0/P1/P2 tags — build **P0 first**.
- **Flutter/Dart:** null-safety, Effective Dart style, feature-first folder structure. (Detail once scaffolded.)
- **React admin:** TypeScript, `@supabase/supabase-js` (+ `@supabase/ssr` if SSR), pinned deps.

## Working norms
- **One deliverable at a time**; keep the user (Akash) in the loop on decisions.
- **Do not auto-launch multi-agent Workflows** — offer and wait for explicit go-ahead.
- People: **Eugene** (**founder**; authored the body-scan engine; owns product direction), **Akash Suryavanshi** (helping build the app — engineering/product execution).

## Commands
- _None yet — no code scaffolded. Update this section with build/test/run commands after scaffolding the Flutter app and React admin._
