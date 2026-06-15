# Viele — Data Architecture & Schema (MVP) — Design Spec

| | |
|---|---|
| **Date** | 2026-06-15 |
| **Status** | Design — approved (Akash, 2026-06-15). **§10 concretizations folded into `docs/SRS.md` v1.5 on 2026-06-15** (§5.1 split note, DR-4 table-split clarification, §3.4 feed() RPC + private media bucket). No new FRs. |
| **Scope** | MVP Postgres schema, RLS, matching RPCs, Storage, admin/moderation, and erasure — the data foundation for the three feature flows. Becomes the **first Supabase migration**. |
| **Authors** | Akash (decisions), with Claude. |
| **Related** | `docs/SRS.md` v1.4 (§5 data, §3.4 backend, §7.3 security, C-5/C-8/C-9, NFR-6/7/8, DR-1/4/7/8); flow specs: onboarding (`2026-06-09`), Post (`2026-06-15`), Feed (`2026-06-15`); `CLAUDE.md` hard rules. |

> **Goal:** make concrete the schema, RLS, and queries the three MVP flows imply, so we build the app against a designed spine. This **realizes** SRS §5 — it does not change MVP scope. Supabase APIs/RLS change often; **verify against live docs at build time** (C-7). The project is a **dedicated, isolated** Supabase project created only on explicit go-ahead (C-8).

---

## 1. Conventions

- **All tables live in `public` with RLS enabled on every one** (NFR-6). No table is exposed without policies.
- UUID PKs via `gen_random_uuid()` (`pgcrypto`); `created_at` / `updated_at` are `timestamptz default now()`.
- **Write policies** are `TO authenticated` with an ownership predicate `(select auth.uid()) = <owner_col>`. **UPDATE policies carry both `USING` and `WITH CHECK`** (NFR-6).
- Extensions at MVP: **`pgcrypto`** (UUIDs), **`citext`** (case-insensitive usernames). **`pgvector` and `pg_cron` are V2** (DR-3, AI-16) — not enabled now.
- Keys: publishable key in clients, **`service_role` only in Edge Functions** (NFR-7, C-5).
- Authorization claims live in **`app_metadata`**, never `user_metadata` (C-5).

---

## 2. Entity overview

```
auth.users (Supabase-managed identity)
  └─1:1─ profiles                      public-readable profile  (id FK → auth.users, ON DELETE CASCADE)
          └─1:1─ profiles_private      OWNER-ONLY: weight_kg, birthday
  posts ── author_id → profiles
   └─1:1─ posts_private                author_weight_band (publish-time; never exposed)
  follows(follower_id, followee_id)
  likes(user_id, post_id)
  collections ─< collection_items(post_id)        "save" = add to a collection
  blocks(blocker_id, blocked_id)
  moderation_reports(post_id, reporter_id, reason, status)
  admin_actions(admin_id, target_type, target_id, action, reason)   append-only audit
```

---

## 3. Tables

### 3.1 `profiles` (public-readable; one row per user)
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | FK → `auth.users.id`, `ON DELETE CASCADE` |
| username | citext unique | validated at capture (FR-ON.4) |
| display_name | text | |
| avatar_url | text null | |
| bio | text null | |
| region | text null | public (FR-ON.3) |
| gender_identity | text null | public, optional, **decoupled** from body_type_set (FR-ON.3/.19) |
| body_type_set | text | `women` \| `men` \| `both` (FR-ON.19) |
| body_silhouette | text null | from the set's list (Appendix 11.3); required to post |
| height_cm | numeric null | **public**; required to post (FR-ON.20) |
| skin_tone | smallint null | **Monk ordinal 1–10** (FR-ON.8); required to post |
| hair_color | text null | required to post |
| eye_color | text null | required to post |
| sizes | jsonb null | `{tops,bottoms,dresses,shoes}` (optional) |
| fit_preference | text null | optional |
| aesthetics | text[] | taxonomy keys (Appendix 11.2); **GIN-indexed** for overlap |
| created_at / updated_at | timestamptz | |

### 3.2 `profiles_private` (owner-only; sensitive fields)
| Column | Type | Notes |
|---|---|---|
| profile_id | uuid PK | FK → `profiles.id`, `ON DELETE CASCADE` |
| weight_kg | numeric null | **owner-only, matching-only, never in any payload** (C-9, DR-4) |
| birthday | date null | private (age-gating = V2) |

> **Why split:** Postgres RLS is **row-level, not column-level**. Because `profiles` is readable by others (public attrs, C-9), a `select *` would leak any sensitive column. Isolating `weight_kg`/`birthday` in an owner-only table is the correct way to keep them private (DR-4).

### 3.3 `posts` (RLS by visibility)
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| author_id | uuid | FK → `profiles.id`, `ON DELETE CASCADE` |
| caption | text null | |
| aesthetics | text[] | ≥1 at publish (FR-CR.4); GIN-indexed |
| items | jsonb | array of `{name, brand?, link?}` (FR-CR.3; no price/catalog at MVP) |
| media | jsonb | ordered storage paths, **1–8** (FR-CR.1) |
| visibility | text | `public` \| `followers` \| `private`, default `public` (FR-CR.5) |
| status | text | `active` \| `removed`, default `active` (moderation soft-remove) |
| author_snapshot | jsonb | publish-time **public** stamp: `{silhouette, height_cm, skin_tone, hair, eye}` — **no weight** (FR-CR.10) |
| created_at / updated_at | timestamptz | metadata editable post-publish; snapshot immutable (FR-CR.11) |

### 3.4 `posts_private` (matching-only; never exposed)
| Column | Type | Notes |
|---|---|---|
| post_id | uuid PK | FK → `posts.id`, `ON DELETE CASCADE` |
| author_weight_band | smallint null | publish-time coarse band; read **only** by the matching RPC (DEFINER). Keeps the band off the public `posts` payload and consistent with snapshot immutability. |

### 3.5 Interactions & safety
- **`follows`** — `(follower_id, followee_id)` composite PK, both FK → profiles CASCADE; `created_at`.
- **`likes`** — `(user_id, post_id)` composite PK; FKs CASCADE.
- **`collections`** — `id`, `owner_id` FK, `name`, timestamps. A default "Saved" collection per user; **save = `collection_items` row** (FR-SG.2/.5).
- **`collection_items`** — `(collection_id, post_id)` PK; FKs CASCADE.
- **`blocks`** — `(blocker_id, blocked_id)` PK; owner-only (FR-SG.8).
- **`moderation_reports`** — `id`, `post_id` FK, `reporter_id` FK, `reason` (`sexual|harassment|violence|illegal|spam|ip|other`), `status` (`open|actioned|dismissed`), `created_at` (FR-CR.9, moderation §4).
- **`admin_actions`** — `id`, `admin_id`, `target_type` (`post|user`), `target_id`, `action` (`dismiss|warn|remove|suspend|ban|escalate`), `reason`, `created_at`. **Append-only** audit (NFR-12, moderation §6).

---

## 4. RLS matrix

| Table | SELECT | INSERT / UPDATE / DELETE |
|---|---|---|
| `profiles` | any authenticated (public attrs, C-9) | owner (`id = auth.uid()`) |
| `profiles_private` | **owner only** | owner |
| `posts` | `status='active'` AND [ `public` → any · `followers` → confirmed follower · `private` → author ] AND **not blocked either direction** | author (`author_id = auth.uid()`) |
| `posts_private` | **no client access** (DEFINER RPC only) | — (written by the publish path) |
| `follows` | any authenticated | owner = `follower_id` |
| `likes` | any authenticated (counts) | owner = `user_id` |
| `collections` / `collection_items` | owner only | owner |
| `blocks` | owner only | owner = `blocker_id` |
| `moderation_reports` | reporter or admin | reporter INSERTs; admin UPDATEs status |
| `admin_actions` | admin only | admin INSERT only (no update/delete) |

Helper: `is_admin()` reads the `app_metadata.role` claim, used in admin policies and Edge-Function guards.

---

## 5. Matching — `SECURITY DEFINER` RPCs

### 5.1 `feed(chip, cursor, limit)`
- **`SECURITY DEFINER`**, owned by a role that can read `profiles_private` and `posts_private` (so it computes the weight band server-side without exposing it).
- **Candidates:** `posts` where `status='active'`, visibility allows the viewer (public / followers-if-following), author ≠ viewer, neither side blocked.
- **Score (0–100%)** — weighted similarity (defaults, **config-tunable**): silhouette 0.30, aesthetics overlap 0.30, skin-tone Monk proximity `1−|Δ|/9` 0.15, height band 0.15, weight band 0.10 (from `posts_private` vs viewer's `profiles_private`). **Missing signals redistribute** their weight (FR-HM.16 / AI-17).
- **Chip sort** (FR-HM.17): For You (blended + freshness − seen) · Most Similar (score desc) · Your Aesthetic (aesthetic-overlap first) · Trending (recent likes, relevance-gated).
- **Widening ladder** (FR-HM.18): exact → relax silhouette to body-type set → widen skin window → aesthetic-only → floor (recent public), so never empty.
- **Pagination:** keyset (`cursor`).
- **Returns:** public post fields + `author_snapshot` + `match_pct` + media paths. **Never returns weight.**

### 5.2 `recommended_people(limit)`
Same engine applied **profile-to-profile**; returns top-N authors (excluding self/followed/blocked) with avatar + `match_pct` (FR-HM.7 / FR-RC.4 lightweight).

### 5.3 Guests
No `auth.uid()`. The RPCs are overloaded to accept **teaser attributes as JSON args** (body_type_set, aesthetics, silhouette, skin_tone); absent height/weight redistribute. Powers the guest matched feed (FR-ON.16/.18).

---

## 6. Storage & signed URLs

- One **private** bucket **`post-media`**; object paths `posts/{author_id}/{post_id}/{n}`.
- **Write:** Storage RLS allows insert only under the caller's own `{author_id}` prefix.
- **Read:** a Storage `SELECT` policy joins the object path → its `post` → the **same visibility check as §4** (public → any authenticated; followers → confirmed follower; private/removed → author). The client mints short-lived **signed URLs**; the policy decides who may.
- **Fallback** (if the path-join policy is awkward in practice): an Edge Function mints signed URLs after a visibility check with `service_role`.

---

## 7. Admin, moderation, erasure

- **Admin auth:** `app_metadata.role = 'admin'` (C-5, FR-AD.1); `is_admin()` in RLS. Privileged actions (remove, suspend, ban) run in **Edge Functions with `service_role`**, never the client.
- **Moderation:** removal = `posts.status='removed'` (soft; hidden from all reads, recoverable, auditable). Reports → `moderation_reports`; every action → `admin_actions` (append-only, NFR-12). **Optional** auto-hide trigger at **N=3** distinct open reports (moderation §5; ship if cheap).
- **Erasure (DR-8):** deleting `auth.users` cascades via FKs through `profiles` → `posts` → `posts_private`/interactions; a Storage cleanup step removes the user's `post-media` objects. **Legal-hold carve-out:** records we must preserve (e.g., CSAM evidence, moderation §6) are exempt from cascade.

---

## 8. Indexes (initial)

`profiles(username)` unique; **GIN** on `profiles.aesthetics` and `posts.aesthetics`; `posts(created_at desc)` and `posts(status, visibility, created_at desc)` for the candidate window; `follows(followee_id)`, `follows(follower_id)`; `likes(post_id)` (counts/trending); `collection_items(post_id)`; `blocks(blocker_id)`, `blocks(blocked_id)`; `moderation_reports(status, created_at)`.

---

## 9. Explicitly V2 (not in this schema)

`pgvector` + all embeddings/vectors (body/style/color/creator), `pg_cron` precompute (trending/leaderboards/feed refresh), persistent seen-events & swipe history (DR-5), notifications table (FR-SG.6), structured brand/clothing-item catalog (MVP keeps item rows as `posts.items` jsonb), creator/analytics tables, comments (FR-SG.7).

---

## 10. SRS impact (v1.4 → v1.5, concretization only — no scope change)

- **§5.1** — note the **`profiles` / `profiles_private`** split and the **`posts_private`** band table; reaffirm the `Post` entity matches §3.3.
- **DR-4** — clarify weight isolation is implemented by **table-split** (owner-only `profiles_private`), since RLS can't hide a column.
- **§3.4 / FR-HM.19 / AI-17** — record the **`feed()` `SECURITY DEFINER` RPC** as the MVP matching mechanism (not an Edge Function), and the **private `post-media` bucket + signed URLs** as the media model.
- **No new FRs.**

---

## 11. Open (non-blocking) follow-ups

- Exact **match-score weights** ship as §5.1 defaults; expose tuning when an admin/config surface exists (FR-AD.6, V2).
- Storage read policy: confirm the **path-join select policy** vs the **Edge-Function signing fallback** at build time (§6).
- `body_silhouette` and color fields: store as `text` at MVP (app-validated) vs Postgres `enum` — default `text` + a CHECK constraint, revisit if churn.
- Default "Saved" collection: auto-created on first save vs at signup — default lazy (first save).

---

## 12. Out of scope (this spec)

App/UI code, the React admin build, Edge-Function source, the actual migration SQL (this is the design the migration implements), pgvector/V2 ranking, and visual design (`docs/design.md`).
