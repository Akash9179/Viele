# Viele App Depth — Design Spec

*Date: 2026-06-22 · Status: approved design, pending implementation plan(s)*

## 1. Purpose

Five enhancements that deepen the existing (working) mobile app for real-user testing: pagination, server-side search, image compression, guest-interaction persistence, and Discover swipe-learning. Each is built and shipped independently, simplest → hardest.

These are the app's remaining build items besides **password-reset completion** and **app icon/splash** (tracked separately).

## 2. Global constraints (carried from CLAUDE.md)

- Flutter (Effective Dart, null-safety) for the app; Supabase Postgres + RLS for the backend.
- **RLS on every new table** (`TO authenticated` + ownership predicate); UPDATE policies need USING + WITH CHECK.
- Authorization claims in `app_metadata` only. `service_role` server-side only.
- **Never expose `weight_kg`** in any read payload.
- Pin package versions; commit lockfiles.
- Supabase project `mdgublyyxcgpwvnmnlxe`. Migrations in `supabase/migrations/` (next: 0012+). Apply to live as each feature is built (additive/backward-safe; coordinate with Eugene).
- `flutter analyze` clean; `flutter test` green before each commit.

## 3. Feature 1 — Image compression (client-only)

**Problem:** `post_compose_screen` calls `pickMultiImage()` / `pickImage(camera)` with no quality/resize → full-resolution multi-MB uploads.

**Design:** Pass the picker's built-in params: `imageQuality: 80, maxWidth: 1440, maxHeight: 1440` to both calls (avatar upload already compresses at q85/1024 — leave it). No new dependency.

**Files:** `app/lib/features/post/presentation/post_compose_screen.dart`.

**Done when:** picked post images are resized/compressed (verify a multi-MP source yields a few-hundred-KB upload); analyze + tests green.

## 4. Feature 2 — Pagination (Home feed)

**Problem:** `feed()` hardcodes `limit 100`; the client loads one batch.

**Design:**
- Migration recreates `public.feed(p_limit int default 20, p_offset int default 0)` — identical ranking, stable total order `match_pct desc, created_at desc, id` (add `id` as final tiebreak so offset paging is deterministic), `limit p_limit offset p_offset`. SECURITY DEFINER + grants unchanged.
- `feed_repository.fetch({int limit = 20, int offset = 0})` passes the params; maps as today.
- `feed_screen`: infinite scroll — a `ScrollController` triggers loading the next page when near the bottom; append to the list; track `hasMore` (a short page = end). Keep pull-to-refresh (resets to page 0).

**Files:** `supabase/migrations/0012_feed_pagination.sql`; `app/lib/features/feed/data/feed_repository.dart`; `app/lib/features/feed/presentation/feed_screen.dart`.

**Done when:** scrolling loads additional pages; a feed larger than one page is fully reachable; pull-to-refresh still works; analyze + tests green.

## 5. Feature 3 — Server-side search (pg_trgm)

**Problem:** `search_screen` filters the first ~50 `peopleProvider` rows + the current feed page client-side; deep users/looks are unfindable.

**Design:**
- Migration: `create extension if not exists pg_trgm`; GIN trigram indexes on `profiles (username gin_trgm_ops)`, `profiles (display_name gin_trgm_ops)`, `posts (caption gin_trgm_ops)`.
- Two SECURITY DEFINER RPCs (anon+authenticated, like feed): 
  - `search_people(q text, p_limit int default 20, p_offset int default 0)` → public profile fields (id, username, display_name, avatar_url — never weight), excludes caller + blocked pairs, ordered by `greatest(similarity(username,q), similarity(display_name,q))` desc.
  - `search_looks(q text, p_limit int default 20, p_offset int default 0)` → active+public posts whose caption/aesthetics match, ordered by similarity; same public shape the feed returns (no weight), blocked-pair excluded.
- Client: a `searchRepository` (or providers) calling the RPCs with a **debounced** query (~300 ms); `search_screen` people/looks tabs render server results with paging; aesthetics stay the static taxonomy chips.

**Files:** `supabase/migrations/0013_search_trgm.sql`; `app/lib/core/data/search_repository.dart` (new); `app/lib/features/search/presentation/search_screen.dart`.

**Done when:** searching a name/caption not in the first page returns matches; typo/partial queries work; weight never present; analyze + tests green.

## 6. Feature 4 — Guest persistence + migrate-on-signup

**Problem:** guest likes/saves/follows live only in memory (`interactions.dart` early-returns for guests) → lost on relaunch.

**Design:**
- Add `shared_preferences` (pinned).
- A small `GuestStore` (wraps shared_preferences) holding three id sets: `guest_liked`, `guest_saved`, `guest_following`.
- `interactions` for a guest (`_uid == null`): read/write the `GuestStore` instead of memory-only; load it on launch so state survives relaunch. (Signed-in path unchanged — server-backed.)
- **Migration on account creation:** after the profile is created at signup, a `migrateGuestInteractions()` step inserts the buffered sets to the server (likes rows, "Saved" collection items, follows — reusing existing repo methods / RPCs), de-duping against anything already there, then clears the `GuestStore`.

**Files:** `app/lib/core/data/guest_store.dart` (new); `app/lib/core/state/interactions.dart`; `app/lib/core/data/profile_repository.dart` (or session) for the post-signup migration hook; `app/pubspec.yaml`.

**Done when:** a guest likes/saves/follows, relaunches, and the state persists; on signup those carry to the server and the local buffer clears; analyze + tests green.

## 7. Feature 5 — Discover swipe-learning + seen-exclusion

**Problem:** Discover left-swipes are discarded, the deck loops (no seen-exclusion), and swipes don't influence ranking.

**Design:**
- Migration: `create table public.swipes (user_id uuid references profiles(id) on delete cascade, post_id uuid references posts(id) on delete cascade, direction text check (direction in ('left','right')), created_at timestamptz default now(), primary key (user_id, post_id))`. RLS owner-only (select/insert/update/delete `TO authenticated` with `user_id = (select auth.uid())`, insert/update WITH CHECK same).
- New `public.discover_deck(p_limit int default 20, p_offset int default 0)` RPC: same Gower ranking as `feed()`, **plus**:
  - excludes posts the caller has already swiped (`not exists (select 1 from swipes s where s.user_id = auth.uid() and s.post_id = po.id)`) and the caller's own posts;
  - **aesthetic-affinity nudge:** from the caller's right-swipes, compute the set of aesthetics they favor (`select distinct unnest(po2.aesthetics) from swipes s join posts po2 ... where s.user_id = auth.uid() and s.direction = 'right'`); add a bounded bonus to a post's score for overlap with that set (e.g. `+ 0.10 * least(overlap_count, 3)/3` on the 0–1 score before scaling), so favored aesthetics rank higher without dominating.
  - excludes blocked pairs; SECURITY DEFINER; granted authenticated (guests get the plain deck — no swipe history).
- Client: `discover_screen` records BOTH swipe directions into `swipes` (right still also calls `toggleLike`); loads the deck from `discover_deck` with pagination; the real empty state ("You're all caught up") shows when the RPC returns nothing. Home `feed()` is unchanged (browse feed may repeat).

**Files:** `supabase/migrations/0014_swipes_discover.sql`; `app/lib/core/state/interactions.dart` (record swipe) or a small `swipe_repository.dart`; `app/lib/features/discover/presentation/discover_screen.dart`.

**Done when:** swiped looks don't reappear; the deck ends honestly; right-swiping a style surfaces more of it; analyze + tests green.

## 8. Build sequence & decomposition

One implementation plan **per feature**, executed in order (each independently shippable, with its own migration + tests):
1. Image compression
2. Home-feed pagination
3. Server-side search
4. Guest persistence + migration
5. Discover swipe-learning + seen-exclusion

## 9. Testing

- Dart unit/widget tests where logic warrants (repos, GuestStore, migration helper); existing `flutter test` stays green.
- Migrations verified with read-only SQL after apply (function runs, returns expected shape, weight absent); `get_advisors` after DDL.
- A self-cleaning integration check (throwaway account, like the existing `qa_smoke_test`) for the swipe + guest-migration paths where practical.

## 10. Out of scope (this batch)

Password-reset completion (deep link), app icon/splash, real Catwalk (rising creators), full implicit-feedback/BPR recommender, keyset/cursor pagination (offset is sufficient at test scale).
