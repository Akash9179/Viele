# Viele — Project Memory

Living context & decision log for Viele. Complements `docs/SRS.md` (full vision), `docs/Viele-MVP-Plan.md` (the locked MVP slice), and `CLAUDE.md` (engineering rules). **Update this file whenever a decision is made or status changes.**

---

## Snapshot
- **Product:** personalized fashion discovery app — matches users to outfits, creators, and clothing by body type, proportions, complexion, and aesthetic. (Full vision in `docs/SRS.md`.)
- **Stage:** documentation + planning. No application code yet. MVP scope locked **and confirmed by Eugene (2026-06-09)** — material changes absorbed (no AI scan, complexion in, UGC posting in). Docs reconciled (**SRS v1.5**, MVP plan, moderation). **All three core flows + the data-architecture/schema designed + folded into the SRS** (2026-06-15). Next: **start building the app** (scaffold Flutter + React admin, provision the isolated Supabase project on explicit go-ahead, apply schema as first migration), with design system (`docs/design.md`) alongside.
- **People:** **Eugene** (**founder**; built the body-scan engine; owns product direction), **Akash Suryavanshi** (helping build the app — engineering/product execution).

## Status — as of 2026-06-09
- [x] PRD read & understood (`PRD.docx`)
- [x] SRS authored (`docs/SRS.md`) — full vision, prioritized P0/P1/P2
- [x] `CLAUDE.md` authored (engineering rules) — **hard rules reconciled to Eugene's 2026-06-09 confirmation** (scan→V2, attrs public, scan-privacy section scoped to V2)
- [x] `docs/memory.md` authored (this file)
- [x] CEO review of the SRS (`/plan-ceo-review`, SCOPE REDUCTION) → MVP scope locked
- [x] `docs/Viele-MVP-Plan.md` (+ PDF) authored for Eugene to confirm
- [x] **Eugene confirmed the MVP plan (2026-06-09)** — with changes: no AI scan, complexion in, any-user posting in
- [x] **Reconciled `docs/SRS.md` → v1.1** (2026-06-09): added a **Rel (MVP/V2)** column across all requirement tables, kept P0/P1/P2 priorities, reworded changed reqs ([CHG] tags), added new reqs (FR-ON.17 public-data disclosure, FR-CR.10 author-attr stamping, FR-RC.9/AI-17 declared-attribute matching, FR-SG.8 report/block), and rewrote §9 as the authoritative MVP-vs-V2 map. Resolved log in §10.4.
- [x] **Updated `docs/Viele-MVP-Plan.md`** to the confirmed scope (2026-06-09): reframed from "for Eugene's confirmation" → "Confirmed"; rewrote flow/features/matching/content/tech for self-reported onboarding, 3 tabs, UGC+moderation, declared-attribute matching, weight-private. **PDF NOT regenerated** (Akash's call) — `docs/Viele-MVP-Plan.pdf` is now stale vs the .md.
- [x] **Onboarding flow designed + APPROVED** (Akash, 2026-06-09) → spec at `docs/superpowers/specs/2026-06-09-onboarding-flow-design.md`. Memory: [[viele-onboarding-design]].
- [x] **Git repo initialized** (2026-06-09) — local, branch `main`, no remote yet; initial commit `38924e3`.
- [x] **SRS v1.1 → v1.2** (2026-06-15) — folded the approved onboarding-flow §5 deltas into `docs/SRS.md`: new FR-ON.18/.19/.20; amended FR-ON.3/.5/.8/.16/.17, NFR-9, ColorProfile, Appendix 11.3, §9.1.
- [x] **Post flow designed + APPROVED** (Akash, 2026-06-15) → spec at `docs/superpowers/specs/2026-06-15-post-flow-design.md`. Single-screen compose: gated entry (account / required-to-post mini-form / show-me-both silhouette) → photo carousel 1–8 + prefilled aesthetics + lightweight item list + Public/Followers/Private → publish immediately. Author stamp = publish-time snapshot (weight band server-side only). Post-publish = delete + edit-metadata (no media swap, no re-stamp).
- [x] **SRS v1.2 → v1.3** (2026-06-15) — folded the Post-flow §8 deltas into `docs/SRS.md`: reworked FR-CR.1/3/4/5/10, added FR-CR.11 (delete + edit-metadata) and FR-CR.12 (entry gates), updated the `Post` data entity + §4.4 purpose + §9.1.
- [x] **Feed flow designed + APPROVED** (Akash, 2026-06-15) → spec `docs/superpowers/specs/2026-06-15-feed-flow-design.md`. Driven by **Eugene's Home + Discover mockups** (shared 2026-06-15). Two-column masonry of match-cards w/ visible **match %**; chips For You/Most Similar/Your Aesthetic/Trending; recommended-people row; never-empty widening ladder; on-the-fly SQL serving; guest feed. **Scope call (Akash): mockups = visual north star, build the 3-tab subset (Feed/Post/Profile); Discover-swipe + Catwalk stay V2 — worth an Eugene confirm.**
- [x] **SRS v1.3 → v1.4** (2026-06-15) — folded the Feed-flow §10 deltas: reworked FR-HM.1/2/3/6/7/8, added FR-HM.16–19 (match-% display, filter chips, widening ladder, on-the-fly serving), annotated FR-RC.4 + AI-17, updated §9.1/§9.2 + headers. Note: FR-HM.2 "videos" → photo carousel (reconciled w/ FR-CR.1); FR-HM.7/.8 pulled to partial-MVP.
- [x] **Data architecture & schema designed + APPROVED** (Akash, 2026-06-15) → spec `docs/superpowers/specs/2026-06-15-data-architecture-design.md`. Tables (`profiles` public + owner-only `profiles_private` for weight/birthday; `posts` + `posts_private` weight-band; follows/likes/collections/collection_items/blocks; moderation_reports/admin_actions). RLS matrix. **Matching = `SECURITY DEFINER` `feed()`/`recommended_people()` Postgres RPCs** (read private weight, return public + match% only). **Media = single PRIVATE `post-media` bucket + signed URLs**, Storage read policy enforces visibility. Admin = `app_metadata.role='admin'`. Soft-remove moderation; cascade erasure w/ legal-hold carve-out. Realizes SRS §5 (no scope change).
- [x] **SRS v1.4 → v1.5** (2026-06-15) — folded schema concretizations: §5.1 split note, DR-4 table-split clarification, §3.4 feed() RPC + private media bucket rows, headers/footer. No new FRs.
- [ ] `docs/design.md` (reference: https://annafashion.lovable.app/)
- [ ] Scaffold Flutter app + React admin
- [ ] Provision **dedicated, isolated** Supabase project (only with explicit go-ahead)

## The MVP (current build target)
Locked via CEO review, **confirmed + amended by Eugene 2026-06-09.** `docs/Viele-MVP-Plan.md` still needs updating to match.

**Wedge:** open the app and within ~1 minute see real outfits worn by people built like you, in your aesthetic, and save them.

- **Three tabs only: Feed, Post, Profile.** No Discover, no Catwalk.
- **Open to everyone**, all body types/genders/aesthetics, day one. (Audience narrowing was explicitly rejected.)
- **No AI body/face scan at MVP.** Onboarding is self-reported form entry: height, weight, body silhouette, + hair/skin/eye color (simple categorical, e.g. brown/black/blonde). AI scan = optional V2 accuracy upgrade.
- **Complexion IS in MVP** (was deferred) — simple self-reported categorical, not AI detection.
- **Matching = declared attributes on both sides.** Auto-tagging keys off the poster's onboarding info (height/weight/silhouette/coloring); posters self-tag those same fields. The pose-pipeline-on-content shape-ratio idea moves to V2 with the scan.
- **Attributes are public**, shared via posts (height, silhouette, coloring). **Weight is the carve-out:** optional, **private/matching-only, never displayed** (resolved 2026-06-09; deviates slightly from Eugene's "all public" — confirm with Eugene).
- **Any user can post (UGC) at MVP** — the Post tab. Reverses the earlier creator-roster-only / no-UGC decision → **re-adds a moderation need** (see open decisions).
- **Deferred to later phases (still in SRS):** Discover swipe, Catwalk, AI body/face scan + complexion detection, pose-pipeline shape-ratio matching, full social graph, full admin, recommendation sophistication, brands/budget/goals.

## Decision log
| Date | Decision | Rationale |
|---|---|---|
| 2026-06-08 | Mobile app = **Flutter** (iOS + Android) | User prioritized UI polish; accepted rewriting the body-scan engine over React Native's reuse advantage |
| 2026-06-08 | Separate **React web** super-admin dashboard | Web admin tooling kept distinct from the mobile product |
| 2026-06-08 | Backend = **Supabase** | pgvector for recommendation embeddings in the same Postgres; unifies app + admin; Auth matches onboarding; RLS for sensitive data |
| 2026-06-08 | **Dedicated, isolated** Supabase project | User runs another project on the same account — zero cross-contamination required (hard rule) |
| 2026-06-08 | Body scan **ported to Dart**, algorithm preserved | Eugene's measurement math is DOM-independent; only the capture layer is rebuilt natively |
| 2026-06-08 | **Client-side-first** AI; raw imagery never uploaded | Privacy by design for body/face data |
| 2026-06-08 | SRS scope = **full vision, phased P0/P1/P2** | Complete spec with a realistic build order |
| 2026-06-08 | Monetization = **P2 + open question** | No business model defined yet |
| 2026-06-08 | **CEO review → SCOPE REDUCTION → sharp wedge MVP** | Market research: these apps die from onboarding friction + content cold-start; build the core loop first |
| 2026-06-08 | **Open to everyone** (no segment narrowing) | Product call: anyone can install and get a useful feed day one |
| 2026-06-08 | Body scan placed **value-first** (after the wow) | Defuses the camera-first onboarding wall (25-60% abandonment) while keeping the moat |
| 2026-06-08 | **Cold-start = auto-tag content with the pose pipeline** + graceful widening | Reuses the moat tech to body-tag the catalog by shape ratios; no audience restriction needed |
| 2026-06-08 | Content via **recruited body-diverse creators**; no UGC at MVP | Real body diversity needs real people; dropping UGC removes moderation burden — *superseded 2026-06-09 ↓* |
| 2026-06-09 | **Eugene confirmed MVP scope** with amendments (below) | Partner sign-off on the build target |
| 2026-06-09 | **No AI body/face scan at MVP**; self-reported onboarding instead (height, weight, silhouette, coloring) | Eugene: scan is V2-optional; avoids camera-first abandonment, big scope cut |
| 2026-06-09 | **Complexion back IN at MVP** — simple self-reported categorical (hair/skin/eye) | Eugene wants coloring in the match; kept simple (dropdowns), not AI detection |
| 2026-06-09 | **Matching = declared attributes** both sides; pose-pipeline shape-ratio matching → V2 | Follows from dropping the scan; simpler & more transparent (Akash accepted) |
| 2026-06-09 | **Attributes public** (height/silhouette/coloring) | Eugene: shared via posts. No raw imagery exists → low risk |
| 2026-06-09 | **Weight = private, matching-only, never displayed** | Akash (OQ-18): most sensitive field; used as a coarse match band, not shown. Slight deviation from Eugene's "all public" — confirm with Eugene |
| 2026-06-09 | **Any user can post (UGC)** at MVP — Post tab; reverses no-UGC | Eugene's 3-tab spec (Feed/Post/Profile); Akash: "any users can post for now" → moderation now needed |
| 2026-06-09 | **Tabs = Feed, Post, Profile** only | Eugene: no Discover, no Catwalk at MVP |
| 2026-06-09 | **Moderation = post-moderation; founders review ≤24h; no auto-screen at MVP** | Akash's calls; scale-appropriate + meets Apple 1.2 / Play UGC floor. Full policy in `docs/moderation.md` |
| 2026-06-09 | **Onboarding = 3-stage value-first** (anon teaser → account at first save/post → gentle Stage-3) | Brainstorm; camera gone so value-before-account is the strongest wedge. Spec on disk; see `[[viele-onboarding-design]]` |
| 2026-06-09 | Onboarding specifics: **Monk-10 skin tone; req-to-post = height+hair+eye; body-type-set ≠ gender identity; layered public disclosure** | Inclusive + low-friction + UGC-stamping needs; Akash's calls in brainstorm |

## Open decisions / gates
- ~~GATE — Eugene to confirm MVP plan Section 9~~ **RESOLVED 2026-06-09** (see decision log). The pose-pipeline cold-start is moot for MVP — matching is now on declared attributes, scan→V2.
- ~~NEW — moderation for UGC~~ **RESOLVED 2026-06-09 → `docs/moderation.md`.** Post-moderation (publish immediately), founders (Eugene/Akash) review reports ≤24h, no automated pre-screen at MVP, mandatory zero-tolerance EULA, report+block ship at MVP. Follow-ups: EULA/Guidelines copy, abuse-contact address, CSAM/NCMEC runbook.
- ~~"Post" tab semantics~~ **RESOLVED 2026-06-09:** "Post" = **users posting their own outfits** (true UGC), confirmed by Eugene via Akash.
- Longer-term (SRS §10): onboarding steps, budget/fashion-goals capture, age gating, monetization (P2), admin framework (React SPA vs Next.js).

## Environment notes
- gstack upgraded to **1.57.6.0** (2026-06-08).
- `make-pdf` / `browse` need `bun`, which is at `~/.bun/bin/bun` but not on the non-interactive shell PATH. Prepend `export PATH="$HOME/.bun/bin:$PATH"` before running. gstack network/upgrade commands need the sandbox disabled.

## Next steps
1. ~~Reconcile `docs/SRS.md`~~ **DONE (v1.1).**
2. ~~Update `docs/Viele-MVP-Plan.md`~~ **DONE** (text only; PDF intentionally stale).
3. ~~MVP **moderation** policy~~ **DONE → `docs/moderation.md`.**
4. ~~Weight-display default (OQ-18)~~ **DONE** — private/matching-only.
5. ~~Onboarding spec~~ **APPROVED.** ~~git init~~ **DONE** (`main`, commit `38924e3`).
6. ~~Fold onboarding §5 deltas into `docs/SRS.md` (v1.1→v1.2)~~ **DONE 2026-06-15.** Added FR-ON.18 (value-first 3-stage staging), FR-ON.19 (body-type set, decoupled from gender), FR-ON.20 (required-to-post = height+hair+eye); amended FR-ON.3/.5/.8 (Monk-10 ordinal)/.16 (guest=teaser, now MVP)/.17 (layered disclosure), NFR-9, ColorProfile data model, Appendix 11.3, §9.1, headers. Committed `cff1d89`.
7. ~~Finalize the Post flow~~ **DONE 2026-06-15** — spec `docs/superpowers/specs/2026-06-15-post-flow-design.md` (committed `1fa5e33`), folded into SRS v1.3 (FR-CR.11/.12 added, FR-CR.1/3/4/5/10 reworked, Post entity).
8. ~~Brainstorm the Feed flow~~ **DONE 2026-06-15** — spec `docs/superpowers/specs/2026-06-15-feed-flow-design.md` (committed `b47cd65`), folded into SRS v1.4 (FR-HM.16–19 + reworks). Driven by Eugene's mockups; 3-tab subset.
9. **← RESUME HERE: start building the app.** All three MVP flows (onboarding, Post, Feed) **and the data-architecture/schema** are specced + in the SRS (v1.5). Recommended order: (a) **design system** (`docs/design.md`, ref `annafashion.lovable.app` + Eugene's mockups) — can run in parallel; (b) **scaffold Flutter + React admin**; (c) **provision the dedicated, isolated Supabase project** (HARD RULE — explicit go-ahead only) + apply the schema spec as the **first migration**; (d) build screens, **Feed/Home wedge first**. Optional: GitHub remote (`viele`).
10. Pre-launch follow-ups: confirm weight-private with Eugene; **confirm 3-tab-subset MVP with Eugene** (mockups show full 5-tab vision); EULA/Community Guidelines copy; abuse-contact; CSAM/NCMEC runbook; initial poster/creator seed plan.
