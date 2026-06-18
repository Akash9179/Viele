# Viele — Real‑User Readiness Audit

| | |
|---|---|
| **Date** | 2026-06-18 |
| **Method** | Multi-agent audit (9 dimensions + completeness critic) against the live code, the committed migrations, and the live Supabase project `mdgublyyxcgpwvnmnlxe` (read-only). |
| **Question** | What remains before Viele can be tested with **actual users** (closed TestFlight beta)? |
| **Totals** | **29 P0**, ~24 P1, ~18 P2 (deduped below). |

> **Verdict:** Not yet. The UI is complete and polished and the **database security posture is genuinely strong**, but the app is a **front‑end prototype on mock data — only auth is wired to Supabase, and auth itself can't complete on a real device.** Everything a tester does (post, save, follow, edit profile, report, block) is in‑memory and resets on restart; every user sees the same six fake people. The remaining work is real: wire the data layer, create real profiles, seed content, make posting + safety real, add legal pages, and brand the build.

---

## The 6 ranked blockers (fix in this order)

1. **Auth dead‑ends before a session exists.** "Confirm email" is ON and there's no `viele://` deep link, so signup never reaches a signed‑in session on device (the one real auth user is unconfirmed). **Until this is fixed, nothing else is testable.**
2. **No profile is created on signup, and onboarding answers are discarded.** No trigger, no username collected (`profiles.username` is `NOT NULL UNIQUE`), no client insert. Live DB: **1 auth user / 0 profiles.** Without a `profiles` row every real read/write FK‑fails and there is no "me" to match against — personalization is impossible.
3. **Entire content layer is mock + the DB is empty + the feed RPCs don't exist.** `feed()`/`recommended_people()`/`match_pct` are referenced everywhere but **were never written** (live DB has only `is_admin`, `set_updated_at`). Match % is a hardcoded constant. Once wired, all 11 tables have **0 rows** and there's **no seed script** → blank feed for everyone.
4. **Posting persists nothing.** No `image_picker` dependency, **no iOS camera/photo permission strings (first real picker call hard‑crashes iOS)**, no Storage upload, no `posts` insert. "Any user can post" is untestable and the catalog can never grow.
5. **UGC safety is a facade.** Report writes nothing to `moderation_reports`; block mutates an in‑memory **name‑keyed** Set (resets, never enforced); **0 admins exist**; no EULA/guidelines acceptance gate. Only acceptable if beta posting is limited to trusted operators.
6. **No reachable Privacy Policy / EULA** while collecting body/coloring/**weight** PII — blocks **external** TestFlight review & App Store; deferrable only for a strictly‑internal (≤100‑device) TestFlight.

---

## P0 — blocks any real‑user test

### Data layer (only auth is wired; 18 files on mock providers)
- **Feed/Discover/Search/Profile/Connections all read `mock_feed.dart`** — same 6 fabricated Unsplash people for everyone; nothing reads the DB. *(feed_screen.dart:22, discover_screen.dart:42, search_screen.dart, connections_screen.dart:35, profile_screen.dart:79/169)*
- **`feed()` / `recommended_people()` RPCs don't exist** and **real match % isn't computed** (hardcoded in mock). Need a feed query/RPC over active+public, non‑blocked posts joined to author public attrs + an MVP `match_pct` against the viewer.
- **Profile + Edit Profile are in‑memory only** (`profile.dart` hardcoded "Maya Chen"; `save()` writes nothing). Every user sees the same identity.
- **Saves/likes/follows/blocks/collections are in‑memory** (`interactions.dart`, `collections.dart`) → reset on restart, invisible to others.

### Auth & onboarding
- **Email confirmation ON, no deep‑link / resend** → no session on device. **Fix:** disable Confirm‑email for beta (simplest) or register `viele://` + `emailRedirectTo`. Delete the orphan `viele-smoketest@gmail.com` user.
- **No `profiles` row on signup**; **onboarding attributes (shape/height/weight/coloring/aesthetics) collected then thrown away** at `context.go('/home')`. Must collect a username + persist public fields to `profiles` and weight to `profiles_private` (convert ft/in→cm, lb→kg, Monk index→1‑10).

### Posting & media
- **No image/video picker dependency**; compose appends mock images (`_addMedia` "Mock picker").
- **Missing `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription`** → crash on first picker call.
- **Share/"Save & publish" do no upload and no insert.** Need: pick → upload to `post-media` (owner‑prefixed path the RLS expects) → insert `posts` + `posts_private` band, attribute‑stamped.

### Content / cold‑start
- **0 rows in every table + no seed script** → blank feed once wired. Need ~30–60 **body‑diverse** poster profiles (genders, silhouettes, Monk‑10 range, height/weight band) × 2–4 real posts with uploaded media.

### UGC safety & compliance
- **Report is a no‑op** (never inserts `moderation_reports`); **block is in‑memory & name‑keyed** (won't map to UUID tables, never enforced).
- **No admin exists** — no one can action reports within the 24h SLA. Provision ≥1 `app_metadata.role='admin'` operator + a dashboard runbook (interim) or build the React admin console.
- **No EULA/Community‑Guidelines acceptance gate**; compose says "Posting agrees to the Community Guidelines" with no link.
- **No reachable Privacy Policy/Terms** while collecting PII.
- **Account deletion & data export are mocked** (delete only signs out) — a privacy exposure. Make real (Edge Function w/ service_role cascade) or clearly disable for beta.

### Branding / build
- **App icon is the default Flutter logo** (iOS + Android) and **iOS launch screen is a blank 68‑byte placeholder.** First impression reads as an unconfigured template. Add `flutter_launcher_icons` + `flutter_native_splash`.

### Cross‑cutting prerequisites (do once, unblock many)
- **Identity refactor: display‑name keys → UUIDs** across `FeedPost`, `interactions`, profiles. Prerequisite for *all* persistence and for block safety.
- **Lock ONE Storage path convention** consistent with the existing insert policy (`(storage.foldername(name))[2] = auth.uid()` — 1‑indexed; the proposed read‑policy `[3]` is only right if a literal `posts/` prefix exists). Decide delivery: **make `post-media` public‑read** (simplest for all‑public v1) or generate signed URLs.
- **Add loading/error/empty/retry states** (AsyncNotifier + `.when`) *before* swapping mocks — there are currently **none** (mocks can't fail).

---

## P1 — needed soon after the core loop works
- Wire **collections / discover / search / connections** to real queries.
- **Password reset** (no flow today) + handle `passwordRecovery`.
- **Auth‑based routing**: a signed‑in returning user still lands on `/onboarding` (no `redirect`).
- **Tighten Storage read policy** so removed/private media stops being fetchable (currently any authed user can read the whole bucket).
- **Finish/hide visible‑but‑dead controls**: outfit Share (no‑op), Copy link (no‑op), profile Share (no handler), notifications bell (inert + fake unread dot, no screen), Settings → Change password / Help & support (no‑op).
- **Avatar `Image.network` has no errorBuilder** (`edit_profile_screen.dart:103`) → red error box on flaky network. Use `CachedNetworkImage`.
- **Publish an abuse/support contact**; wire the dead Privacy/Guidelines/Help rows.
- **`Add video` is fake and out of MVP scope** — remove it (or commit to real video, a large lift).

## P2 — polish / hardening
- Enable **leaked‑password protection** (Supabase advisor WARN); consider min‑strength.
- `revoke` anon write grants on `*_private` (defense‑in‑depth; not exploitable today).
- **Pin exact dep versions** for `supabase_flutter` etc. (lockfile is committed — minor).
- **Accessibility**: no `Semantics` anywhere; save/icon tap targets < 44pt; test at 1.3× text.
- Add **errorWidget** to the 16/18 `CachedNetworkImage` sites lacking one.
- **Strengthen tests** — the lone widget test passes only because it never touches Supabase; it'll crash once a tested screen does.
- iOS: add `ITSAppUsesNonExemptEncryption=false` (smooths every TestFlight upload); normalize `CFBundleName` to "Viele".
- Optional moderation **auto‑hide at N reports**; vary other‑user profile mock attributes; decide on the **Catwalk** dead tab; fix stale comment in `app_shell.dart:9`.

## De‑scoped for an **iOS‑only** closed beta (revisit before Android/public)
- **Android release is debug‑signed** (no keystore) — fine if iOS‑only.
- **SF Pro is iOS‑only** → Android renders in Roboto (off‑brand) — fine if iOS‑only.
- **Google/Apple OAuth** stubs — email‑only is acceptable for a closed beta (Apple Sign‑In becomes required for public if any social login is offered).

---

## What's already strong ✅
- **Database security is the standout.** RLS on all 11 tables (verified live); owner‑scoped writes with USING+WITH CHECK; **weight/birthday privacy structurally enforced** (`profiles_private` owner‑only; `posts_private` has **no SELECT policy** → universally unreadable — empirically confirmed). Admin claim via `app_metadata` (correct).
- **Auth code quality** is good where it exists (busy state, `AuthException` handling, validation, `mounted` guards).
- **Complete, on‑brand UI** across every surface; **isolated Supabase project**; no `service_role` key in the client (only the publishable key).

---

## Minimal critical path to a safe closed beta (ordered)
1. **Unblock auth** — disable Confirm‑email (or wire `viele://`); delete the orphan test user; verify sign‑up → persistent session on device.
2. **Create profile on signup** — collect username; thread + write onboarding answers to `profiles` (+ `profiles_private` weight).
3. **Identity refactor** — display‑name keys → profile/post UUIDs across the app.
4. **Storage + posting** — lock path convention + bucket delivery; add `image_picker` + iOS permission strings; pick → upload → insert `posts`/`posts_private`; remove the fake video affordance.
5. **Real feed/profile/search** as AsyncNotifiers with loading/error/empty/retry; replace `mock_feed`.
6. **Seed** ~30–60 body‑diverse posters × 2–4 posts (media uploaded); verify they render via the real query.
7. **Safety** — report → `moderation_reports`; block/unblock → `blocks`; grant one admin + a runbook to action within 24h.
8. **Legal** — mandatory EULA/Guidelines acceptance in onboarding (persist `tos_version`+`accepted_at`); host + link Privacy/Guidelines (wire the dead rows + compose copy).
9. **Branding & safety‑of‑claims** — real app icon + launch screen; `ITSAppUsesNonExemptEncryption=false`; make Delete/Export real or clearly disable.
10. **Scope iOS/TestFlight‑only**; device smoke‑test the whole loop: sign up → profile → seeded feed → post → see own post → save → follow → block → report.
