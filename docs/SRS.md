# Software Requirements Specification (SRS)
## Viele — Personalized Fashion Discovery App

| | |
|---|---|
| **Document version** | 1.2 (Draft) |
| **Date** | 2026-06-15 |
| **Status** | Draft — **MVP scope confirmed by founder Eugene 2026-06-09** (see §9, §1.6). **v1.2 (2026-06-15) folds in the approved onboarding-flow design** (value-first 3-stage staging, body-type set, Monk-10 skin tone, required-to-post trio, teaser guest mode, layered disclosure) per `docs/superpowers/specs/2026-06-09-onboarding-flow-design.md`. Remaining §10 opens before baselining. |
| **Owners** | **Eugene** (Founder; Body-Scan Engine; product direction), **Akash Suryavanshi** (helping build — engineering/product execution) |
| **Source PRD** | `PRD.docx` |
| **Design reference** | https://annafashion.lovable.app/ |
| **Related docs** | `CLAUDE.md` (engineering conventions), `docs/memory.md` (project memory), `docs/Viele-MVP-Plan.md` (MVP slice), `docs/design.md` (design system — pending) |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [System Architecture](#3-system-architecture)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Requirements](#5-data-requirements)
6. [External Interface Requirements](#6-external-interface-requirements)
7. [Non-Functional Requirements](#7-non-functional-requirements)
8. [AI / ML Requirements](#8-ai--ml-requirements)
9. [Release Plan & Phasing](#9-release-plan--phasing)
10. [Open Questions & Assumptions](#10-open-questions--assumptions)
11. [Appendix](#11-appendix)

---

## 1. Introduction

### 1.1 Purpose
This Software Requirements Specification (SRS) defines the functional and non-functional requirements for **Viele**, a personalized fashion discovery mobile application and its supporting web super-admin dashboard. It translates the product vision captured in `PRD.docx` into structured, traceable, and prioritized requirements suitable for design, planning, implementation, and verification.

### 1.2 Product summary
Viele is a personalized fashion discovery platform that helps users find outfits, creators, and clothing tailored to their **body type, proportions, complexion, aesthetic, and style preferences**. It combines three pillars:

- **Social discovery** — follow creators, browse, post, and save outfits, build a fashion identity.
- **Visual personalization** — a personal profile (body silhouette, sizing, complexion, aesthetics) drives matching to *people who resemble the user*. **At MVP this profile is self-reported in onboarding;** AI body/face analysis is a V2 accuracy upgrade.
- **Fashion inspiration** — a personalized feed of relatable, body-matched outfits (with a swipe-based Discover deck and a "Catwalk" showcase added post-MVP).

### 1.3 Scope
This SRS covers the **full product vision** from the PRD, with every requirement carrying both a **priority** (P0/P1/P2 — full-vision build order) and a **release marker** (MVP / V2 — the actual first-release cut confirmed by Eugene on 2026-06-09). See §1.6. It spans:

- The **Viele mobile app** (Flutter, iOS + Android) — the primary product.
- The **Viele super-admin dashboard** (React web) — internal tooling for user/content management, moderation, and analytics.
- The **backend** (Supabase) and the **AI/ML components** (declared-attribute matching at MVP; on-device body scan, complexion analysis, and vector embeddings at V2).

**Out of scope for v1.x of this document:** detailed visual design system (see `docs/design.md`), the finalized monetization/business model (documented here only as a P2 open question — see §10), and the detailed implementation plan (`docs/Viele-MVP-Plan.md`).

### 1.4 Intended audience
Product, engineering, design, and external collaborators. Each requirement has a stable ID so it can be referenced from plans, tickets, design docs, and test cases.

### 1.5 Definitions, acronyms & glossary
See [Appendix 11.1](#111-glossary) for the full glossary. Key terms used throughout:

- **Aesthetic** — a named style category (e.g., *Old Money*, *Streetwear*, *Y2K*).
- **Body Profile** — the user's structured body data. **MVP:** self-reported (height, weight, body silhouette, sizing, fit preference). **V2:** scan-derived measurements, ratios, body shape, confidence, and a normalized `body_vector` (Appendix 11.4).
- **Color Profile** — complexion attributes (skin tone, hair color, eye color; undertone + derived palette at V2). **MVP:** self-reported categorical values.
- **Embedding / vector** — a numeric representation used for similarity matching (body, style, color, creator). **V2** (MVP matches on declared attributes).
- **Creator** — a user who publishes content and has access to creator analytics (analytics = V2).
- **Look / Outfit** — a styled set of clothing items shown in a post.

### 1.6 Document conventions & priority/release legend
Requirements are identified as `FR-<area>.<n>` (functional), `DR-<n>` (data), `EIR-<n>` (external interface), `NFR-<n>` (non-functional), and `AI-<n>` (AI/ML). Each table carries two columns:

**Priority** (full-vision build importance, unchanged from v1.0):

| Priority | Meaning |
|---|---|
| **P0** | Core — the product is not viable without it (within the full vision). |
| **P1** | Fast-follow — important for a competitive product. |
| **P2** | Later — vision-completing or monetization features. |

**Rel** (release marker — the **confirmed first-release cut**, Eugene 2026-06-09):

| Rel | Meaning |
|---|---|
| **MVP** | In the first release. |
| **V2** | Deferred to a later release (includes the entire AI body/face scan, complexion auto-detection, vector matching, Discover, and Catwalk). |

> **Why Pri and Rel can disagree:** Eugene's confirmed MVP removed the AI scan (a P0 capability → now V2) and pulled complexion *in* as simple self-reported data (a P1 capability → now MVP). The two columns make those moves explicit rather than rewriting the priority scheme. **§9 is the authoritative MVP-vs-V2 map.** Requirements whose *meaning* changed on 2026-06-09 are marked **[CHG]** inline.

"**[OPEN]**" marks a requirement that depends on an unresolved decision tracked in §10.

### 1.7 References
- `PRD.docx` — source product requirements.
- Design reference: https://annafashion.lovable.app/
- Body-scan algorithm specification (provided by Eugene) — reproduced in [Appendix 11.4](#114-body-scan-algorithm-reference) (V2 reference).

---

## 2. Overall Description

### 2.1 Product vision
> *"Discover fashion that actually fits you."* — Find outfit inspiration from people with similar body types, proportions, coloring, and style preferences.

Viele's differentiator is **personalization grounded in the user's actual body and coloring**, not generic trends. Where most fashion apps surface idealized, hard-to-relate-to content, Viele surfaces outfits worn by people who *resemble the user*, addressing a real gap in inclusivity across body types, sizes, and complexions.

### 2.2 Core user problems (from PRD)
- Users don't know what clothing flatters their proportions, body shape, or coloring.
- Most fashion inspiration feels unrealistic or hard to relate to.
- People want to discover outfits on users with similar features and aesthetics.
- Existing apps prioritize trends over personalization.
- Users struggle to organize and save fashion inspiration efficiently.
- The industry advertises to a narrow set of body types, sizes, and complexions — a lack of inclusivity.

### 2.3 Personas
| # | Persona | Primary need |
|---|---|---|
| P1 | Fashion-conscious college women | Relatable, on-trend inspiration that fits their body & budget |
| P2 | Men improving style confidence | Approachable guidance and examples to build confidence |
| P3 | Luxury / designer enthusiasts | Curated high-end looks and creators |
| P4 | Minimalist / capsule-wardrobe users | Cohesive, versatile, low-volume recommendations |
| P5 | Streetwear / trend-focused users | Fast trend discovery and creator exploration |
| P6 | Users dressing for their body type/proportions | Outfits proven to flatter their specific silhouette |
| P7 | Users seeking inspiration from look-alikes | Matching to creators with similar features |
| P8 | Users across a wide range of body types | Inclusive, representative content |

### 2.4 User classes (roles)
- **Guest / Unauthenticated** — limited browsing before account creation. (At MVP, personalization and posting require an account; the V2 body scan may run locally pre-account per Eugene's engine.)
- **Standard User** — full consumer experience: onboarding, feed, save, follow, and **post** (UGC). **Any user can post at MVP** (Eugene, 2026-06-09).
- **Creator** — a Standard User with publishing focus and access to creator analytics (analytics = V2). Creator status criteria are [OPEN] — see §10.
- **Super Admin** — internal staff using the React web dashboard for user/content management, moderation, and analytics. Authorization is enforced via a privileged claim (see §3 and §7).
- **System / AI services** — automated processes (matching/ranking, embedding generation at V2, trending/leaderboard jobs at V2, moderation hooks).

### 2.5 Operating environment
- **Mobile app:** Flutter, targeting **iOS and Android**. At MVP, no camera/GPU pose-detection requirement (self-reported onboarding); media capture/upload for posts only. The V2 body scan requires a device camera and sufficient GPU/CPU for on-device pose detection. Assumed minimum platforms: **iOS 15+** and **Android 8.0 (API 26)+** — [OPEN], to be confirmed against the chosen plugins.
- **Admin dashboard:** React single-page web app for modern evergreen browsers (Chrome, Safari, Edge, Firefox — latest two major versions).
- **Backend:** **Supabase** (managed Postgres, Auth, Storage, Realtime, Edge Functions, pgvector, pg_cron).

### 2.6 Design & implementation constraints
- **C-1 — Mobile-first, Flutter.** The consumer product is a Flutter app; the admin dashboard is a separate React web app. (Decision locked.)
- **C-2 — Body-scan port (V2).** Eugene's body-scan engine is web/TypeScript (MediaPipe Tasks Vision, browser APIs). **It is deferred to V2** (Eugene, 2026-06-09). When built it will be **re-implemented in Dart**, **preserving the measurement algorithm** (Appendix 11.4): user-height-anchored pixel→cm scaling, width/length measurement, BMI-adjusted Ramanujan-II ellipse circumference estimates, outlier rejection, shape classification, and confidence scoring. The capture layer is replaced with native Flutter equivalents (MediaPipe/Google ML Kit Pose Detection).
- **C-3 — Privacy by design.** **[CHG]** At MVP, the personalization attributes are **self-reported and public** (see C-9). The original "raw imagery never leaves the device" rule applies to the **V2 scan**: raw scan video and face photos must never leave the device; only derived, non-reversible profiles and vectors are persisted. On-device processing is mandatory for the V2 scan and complexion capture.
- **C-4 — Backend is Supabase.** Auth (email, Google, Apple), Postgres + RLS, Storage, pgvector, Edge Functions, Realtime, pg_cron.
- **C-5 — Security model.** Row Level Security on every table in exposed schemas; authorization claims stored in `app_metadata` (never user-editable `user_metadata`); the `service_role` key is used only server-side (Edge Functions / admin backend), never shipped in either client.
- **C-6 — App store compliance.** Apple App Store & Google Play policies, including Apple's requirement to offer **Sign in with Apple** when other third-party sign-ins are present, media-usage permission strings, handling of sensitive personal data, and **UGC safety requirements** (moderation, reporting, blocking) — newly relevant because any user can post at MVP.
- **C-7 — Supabase verification.** Supabase APIs and RLS patterns change frequently; implementation must be verified against the live Supabase changelog/docs at build time, not from memory.
- **C-8 — Dedicated, isolated Supabase project (HARD CONSTRAINT).** Viele must be provisioned in its **own brand-new Supabase project**, fully isolated from any other project on the account/organization. **Nothing** is shared with an existing project — no database, schema, tables, Auth configuration, Storage buckets, Edge Functions, API keys, or environment. No tooling (including the Supabase MCP/CLI) may read, modify, or otherwise touch a pre-existing project. Project creation happens only with explicit stakeholder go-ahead.
- **C-9 — Public self-reported attributes (MVP). [CHG]** Height, body silhouette, and hair/skin/eye color are entered in onboarding and are **public profile fields**, shared with others through posts (Eugene, 2026-06-09). **Weight is the carve-out:** it is **optional, used only for matching (as a coarse band), and NEVER publicly displayed** — not on the profile, not on posts (Akash, 2026-06-09; slight deviation from Eugene's "all public," to confirm with Eugene). This relaxes the v1.0 owner-only-sensitive treatment for height/silhouette/coloring while keeping weight private.

### 2.7 Assumptions & dependencies
- **A-1 (V2)** User-entered height is accurate — it is the **only** real-world scale anchor for the body scan (Appendix 11.4).
- **A-2 (V2)** Devices have a camera and adequate compute for on-device pose/face landmarking.
- **A-3 (V2)** The body scan is an **estimate**, not a measurement device; it is explicitly **not a medical device** and must be presented as such.
- **A-4 (V2)** A Dart-compatible MediaPipe/ML Kit pose-detection path exists that yields equivalent landmark data (33 pose landmarks) to drive the ported algorithm.
- **A-5 (V2)** Reference access to Eugene's existing TypeScript implementation is available to guide the Dart port — [OPEN].
- **A-6** Supabase's free/managed tiers are sufficient for MVP scale; scaling of media storage and (V2) vector search is revisited later.
- **A-7 (MVP). [CHG]** Self-reported height, weight, body silhouette, and coloring are **sufficient for a decent matched feed at MVP** (confirmed by Eugene, 2026-06-09).

---

## 3. System Architecture

### 3.1 High-level component view
```
┌──────────────────────────┐        ┌──────────────────────────┐
│   Viele Mobile App        │        │  Viele Super-Admin (Web)  │
│   Flutter (iOS/Android)   │        │  React SPA                │
│                           │        │                           │
│  • Onboarding (self-report)│       │  • User management        │
│    (scan = V2)            │        │  • Content moderation     │
│  • Feed / Post / Profile  │        │  • Analytics (V2)         │
│    (Discover/Catwalk = V2)│        │  • Feature/flag config(V2)│
│  • supabase_flutter SDK   │        │  • @supabase/supabase-js  │
└────────────┬─────────────┘        └────────────┬─────────────┘
             │  HTTPS / Realtime                  │  HTTPS
             ▼                                    ▼
┌─────────────────────────────────────────────────────────────┐
│                          Supabase                             │
│  Auth (email, Google, Apple)   Postgres + RLS                 │
│  Storage (media, signed URLs)  pgvector (embeddings — V2)     │
│  Realtime (feeds/notifs)       Edge Functions (matching, mod, │
│  pg_cron (trending — V2)          aggregation)                │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼  (V2, optional)
        External services: push (FCM/APNs), media CDN/transcode,
        shopping/affiliate partners, dedicated vector store at scale
```

### 3.2 Mobile app (Flutter)
- **MVP surfaces:** Onboarding (self-reported), **Feed**, **Post**, **Profile**. (Discover, Catwalk, and the AI body scan are V2.)
- **On-device AI (V2):** body scan (pose landmarking + measurement algorithm) and complexion capture run locally; raw imagery is discarded after deriving profiles (C-3).
- **Local persistence:** cached personalization/feed data on device; authenticated data syncs to Supabase.
- **Backend access:** `supabase_flutter` for auth, data, storage, and realtime subscriptions.

### 3.3 Admin dashboard (React web)
- A separate React SPA for super-admins only. Accesses Supabase via `@supabase/supabase-js` (with `@supabase/ssr` if built on a server framework — [OPEN] framework choice).
- Authorization gated by an admin claim in `app_metadata`; sensitive operations route through Edge Functions using the `service_role` key (never exposed to the browser).
- **MVP scope:** a minimal moderation console (remove content, suspend/ban users, handle deletion requests). Full dashboard (analytics, queues, config) is V2.

### 3.4 Backend (Supabase) responsibilities
| Concern | Supabase capability |
|---|---|
| Identity & sessions | Auth (email, Google, Apple), JWT |
| Relational data | Postgres (users, profiles, posts, outfits, items, follows, collections, interactions, moderation) |
| Authorization | Row Level Security on all exposed tables; admin via `app_metadata` |
| Matching / recommendations | MVP: declared-attribute scoring (SQL). V2: pgvector (body, style, color, creator embeddings) |
| Media | Storage buckets + signed URLs for images/videos (post media) |
| Live updates | Realtime (feed, notifications — notifications V2) |
| Async compute | Edge Functions (matching/ranking, moderation hooks; embedding generation at V2) |
| Scheduled jobs | pg_cron (trending, leaderboards, feed refresh — V2) |

### 3.5 AI/ML components
- **MVP — declared-attribute matching:** match users to posts on self-reported attributes (silhouette, height/weight band, coloring, aesthetics) + behavioral signals; graceful match-widening so no feed is empty. No on-device CV.
- **V2 — Body scan (on-device):** pose landmarking + ported measurement algorithm → `BodyProfile` + `body_vector`.
- **V2 — Complexion detection (on-device):** face landmarking + skin-tone/undertone/hair/eye extraction → `ColorProfile` + color palette. (MVP captures the same fields as **self-reported** categories.)
- **V2 — Embeddings:** body, style, color, and creator vectors stored in pgvector.
- **V2 — Recommendation engine:** hybrid content-based + behavioral, with explicit exploration via the Discover swipe deck (see §8).

---

## 4. Functional Requirements

> Each requirement: **ID · Pri · Rel · Description.** Grouped by surface. **[CHG]** marks meaning changed on 2026-06-09. PRD gaps are flagged **[OPEN]** and consolidated in §10.

### 4.1 Onboarding & Account

**Purpose (PRD):** Quickly capture physical attributes, style preferences, and aesthetic interests to personalize from first launch. **MVP capture is entirely self-reported** (no camera) and follows a **value-first, three-stage flow** (FR-ON.18): an anonymous **Teaser** earns the matched feed in ~1 min, an **Account** is requested at the first save/post, and the **rest of the profile** is filled in gently afterward and never blocks browsing.

| ID | Pri | Rel | Requirement |
|---|---|---|---|
| FR-ON.1 | P0 | MVP | **Welcome screen** presenting the value proposition ("Discover fashion that actually fits you.") with primary actions: **Create Account**, **Continue with Google**, **Continue with Apple**. |
| FR-ON.2 | P0 | MVP | **Account creation & authentication** via Supabase Auth: email/password, Google OAuth, Apple OAuth. Apple sign-in is mandatory on iOS when other social logins are present (C-6). |
| FR-ON.3 | P0 | MVP | **Basic profile capture. [CHG]** Name, Username (unique) — captured at account creation (Stage 2). Birthday (optional, private), Country/Region (optional), and **Gender identity (optional, Stage 3)** — gender identity is **decoupled from the teaser's body-type set** (FR-ON.19) and never required to browse or post. |
| FR-ON.4 | P0 | MVP | **Username uniqueness & validation** enforced at capture time. |
| FR-ON.5 | P0 | MVP | **Self-reported body profile. [CHG]** Height (ft/in or cm), Weight (lb or kg — **optional; matching-only, never displayed**, C-9), **Body silhouette** (self-selected from illustrated options — the MVP body-shape input replacing the scan; the silhouette set shown is chosen by the body-type set, FR-ON.19), clothing sizes (Tops, Bottoms, Dresses, Shoes), and Fit Preference (Slim, Tailored, Relaxed, Oversized, Mixed). Units user-selectable; normalized internally. **Staging:** silhouette is captured in the Teaser; height/sizes/fit/weight are gentle Stage-3 fields (FR-ON.18) — **height is required only to post** (FR-ON.20). |
| FR-ON.6 | P0 | **V2** | **Body shape & proportions via AI Body Scan. [CHG]** Deferred to V2 (Eugene, 2026-06-09). When built: user records/uploads a front/side video or photo; on-device analysis returns body shape, proportions, ratios, silhouette (Algorithm: Appendix 11.4). **At MVP, replaced by self-reported silhouette in FR-ON.5.** |
| FR-ON.7 | P0 | **V2** | **Editable scan results** — review/edit AI-derived body results before saving. (V2, with FR-ON.6.) |
| FR-ON.8 | P1 | **MVP** | **Self-reported complexion & coloring. [CHG]** User selects **skin tone** from the **Monk 10-tone scale** (single tap; stored as an ordinal 1–10 so matching can use proximity, not just equality), plus **hair color** and **eye color** from simple category lists (Appendix 11.3). Skin tone is a Teaser field; hair/eye are Stage-3 fields **required to post** (FR-ON.20). Public profile fields (C-9), used in matching. (AI auto-detection of these → V2, AI-5/6.) |
| FR-ON.9 | P0 | MVP | **Style preferences (aesthetics):** user selects **3–10** aesthetics from the taxonomy (Appendix 11.2). |
| FR-ON.10 | P1 | V2 | **Favorite brands:** multi-select from a brand list, with search. |
| FR-ON.11 | P0 | **V2** | **Camera consent & disclosure. [CHG]** Before any camera capture (V2 scan/complexion), present explicit consent describing on-device processing, that raw imagery is not uploaded, and that the scan is an estimate / not a medical device (A-3, C-3). **MVP has no camera capture for profiling**; see FR-ON.17 for the MVP public-data disclosure. |
| FR-ON.12 | P0 | MVP | **Skip/return:** optional steps are skippable and resumable later from Profile without blocking first use. |
| FR-ON.13 | P1 | V2 | **Budget range capture.** [OPEN] — needs a defined step/values (see §10). |
| FR-ON.14 | P1 | V2 | **Fashion goals capture.** [OPEN] — needs a defined step/values (see §10). |
| FR-ON.15 | P1 | V2 | **PRD onboarding gap — Step 3 & Step 8.** Intended content undefined; resolve later (see §10). |
| FR-ON.16 | P0 | **MVP** | **Guest mode (anonymous teaser). [CHG]** At MVP, guest mode is the **anonymous Teaser** (FR-ON.18): browse the matched feed and supply the teaser inputs (body-type set, aesthetics, silhouette, skin tone) **with no account**. Teaser answers persist in local storage and **migrate into the profile on sign-up**; if the user bounces without an account, the teaser data is discarded. An account is required only to **save or post** (Stage 2). *(V2 widens this to running the body scan as a guest.)* |
| FR-ON.17 | P0 | **MVP** | **Public-data disclosure — layered (NEW). [CHG]** Disclose that body silhouette, height, and coloring are **public** and shown alongside the user's posts, and that **weight is private** — optional, matching-only, never shown to others (C-9). Disclosure is **layered**: (a) one concise line at sign-up; (b) per-field **Public/Private** tags in Profile edit; (c) a one-line reminder the **first time the user posts** (NFR-9). |
| FR-ON.18 | P0 | **MVP** | **Value-first three-stage onboarding (NEW).** Onboarding is staged: **Stage 1 — Teaser** (anonymous, no account): body-type set (FR-ON.19), aesthetics (FR-ON.9), body silhouette, and skin tone (FR-ON.8) → **matched feed** (the wow). **Stage 2 — Account**: requested at the **first save or post** (FR-ON.2/.3); teaser answers migrate in (FR-ON.16). **Stage 3 — rest of profile** (FR-ON.5/.8 remainder): gentle, always resumable from Profile, and **never blocks browsing**. |
| FR-ON.19 | P0 | **MVP** | **Body-type set (NEW).** The Teaser asks which silhouette chart to show — **women / men / show me both** — solely to select the silhouette options (Appendix 11.3). It is **decoupled from gender identity** (FR-ON.3). For "show me both," the feed draws from both silhouette sets; before the user's **first post**, prompt for a single own-silhouette to stamp their posts (FR-CR.10). |
| FR-ON.20 | P0 | **MVP** | **Required-to-post profile (NEW).** Consumers browse and save with **no required profile fields beyond the Teaser**. **Posting requires height + hair + eye** — which, combined with the Teaser's silhouette + skin tone, form a complete author stamp for matching (FR-CR.10). Tapping Post with an incomplete profile triggers an **inline 3-field mini-form** (height + hair + eye), then publishes — an intercept, not a wall. Sizes, fit, and weight remain optional. |

### 4.2 Feed (Personalized Home)

**Purpose (PRD):** Browse a personalized editorial-style feed of outfit content from people with similar body types, proportions, sizing, coloring, and aesthetics. **MVP tab name: "Feed."**

| ID | Pri | Rel | Requirement |
|---|---|---|---|
| FR-HM.1 | P0 | MVP | **Personalized fashion feed** driven by the user's self-reported profile (silhouette, sizing, coloring, aesthetics) and behavior. |
| FR-HM.2 | P0 | MVP | **Outfit posts** rendered editorial-style with rich media (photos, videos, carousels). |
| FR-HM.3 | P0 | MVP | **Similar-body & aesthetic matching. [CHG]** Feed prioritizes posts whose author attributes match the viewer's declared attributes (see §8, FR-RC.9). |
| FR-HM.4 | P0 | MVP | **Save outfits to collections** from the feed. |
| FR-HM.5 | P0 | MVP | **Follow creators/users** from the feed. |
| FR-HM.6 | P0 | MVP | **Outfit detail view** with tagged clothing items and descriptions. |
| FR-HM.7 | P1 | V2 | **Recommended creators** module. |
| FR-HM.8 | P1 | V2 | **Trending looks within the user's aesthetic.** |
| FR-HM.9 | P1 | V2 | **Recently viewed outfits.** |
| FR-HM.10 | P1 | V2 | **Suggested complementary outfits/items.** |
| FR-HM.11 | P1 | V2 | **"Inspired by your saves" recommendations.** |
| FR-HM.12 | P1 | V2 | **Personalized style categories** surfaced in the feed. |
| FR-HM.13 | P1 | V2 | **Curated seasonal / trend collections.** |
| FR-HM.14 | P1 | V2 | **Feed refresh based on engagement behavior** (re-ranking as signals accumulate). |
| FR-HM.15 | P2 | V2 | **Shop / link tagged products** (monetization-adjacent; see §10). |

### 4.3 Discover (Swipe-based) — **V2**

**Purpose (PRD):** Fast, swipe-based exploration that trains personalization. **Entire surface deferred to V2 (no Discover tab at MVP).**

| ID | Pri | Rel | Requirement |
|---|---|---|---|
| FR-DS.1 | P0 | V2 | **Swipe left/right on outfits** with smooth, native-feeling gestures. |
| FR-DS.2 | P0 | V2 | **Preference learning** from swipe/engagement behavior feeding the recommendation model. |
| FR-DS.3 | P0 | V2 | **Endless discovery feed** (continuous card supply). |
| FR-DS.4 | P0 | V2 | **Like, save, and share** actions on cards. |
| FR-DS.5 | P1 | V2 | **"Why this was recommended" insight** per card. |
| FR-DS.6 | P1 | V2 | **Aesthetic & category filters.** |
| FR-DS.7 | P1 | V2 | **Occasion-based discovery** (casual, formal, gym, nightlife, etc.). |
| FR-DS.8 | P1 | V2 | **New creator exploration** via swipe. |
| FR-DS.9 | P1 | V2 | **Experimental recommendations** outside usual preferences. |
| FR-DS.10 | P1 | V2 | **Smart diversity balancing.** |
| FR-DS.11 | P1 | V2 | **Hidden / "not interested" controls.** |
| FR-DS.12 | P1 | V2 | **Real-time feed improvement** from interactions within a session. |
| FR-DS.13 | P2 | V2 | **Outfit rating / explicit feedback signals** beyond swipe. |
| FR-DS.14 | P1 | V2 | **Trending aesthetic exploration** entry points. |

### 4.4 Post (Upload & Compose) — the **Post** tab

**Purpose (PRD):** Let users and creators upload outfit content and express personal style. **[CHG] Any user can post at MVP** (Eugene, 2026-06-09) — this is the **Post** tab. Reverses the earlier creator-roster-only / no-UGC plan and makes moderation in-scope (§4.9).

| ID | Pri | Rel | Requirement |
|---|---|---|---|
| FR-CR.1 | P0 | MVP | **Upload outfit photos/videos** to a post. |
| FR-CR.2 | P0 | MVP | **Captions & outfit descriptions.** |
| FR-CR.3 | P0 | MVP | **Tag clothing items and brands** within a post. |
| FR-CR.4 | P0 | MVP | **Add aesthetic / style categories** to a post. |
| FR-CR.5 | P0 | MVP | **Visibility / privacy settings** per post (e.g., public/followers/private). |
| FR-CR.6 | P1 | V2 | **Drafts** — save and edit posts before publishing. |
| FR-CR.7 | P1 | V2 | **Image tools** — cropping and basic editing. |
| FR-CR.8 | P1 | V2 | **Creator analytics & engagement stats** for the author. |
| FR-CR.9 | P0 | **MVP** | **Content moderation hook. [CHG]** Submitted content is screened (report + admin review; automated screening optional at MVP) per the moderation policy (§4.9, §10). Now MVP-critical because posting is open to all users. |
| FR-CR.10 | P0 | **MVP** | **Author attribute stamping (NEW).** A post carries the author's public attributes (silhouette, height/weight band unless hidden, coloring) so the feed can match it to similar viewers (FR-RC.9, C-9). |

### 4.5 Catwalk (Showcase) — **V2**

**Purpose (PRD):** A showcase of top creators, trending outfits, and high-performing content. **Entire surface deferred to V2 (no Catwalk tab at MVP).**

| ID | Pri | Rel | Requirement |
|---|---|---|---|
| FR-CW.1 | P1 | V2 | **Daily/weekly trending outfits.** |
| FR-CW.2 | P1 | V2 | **Featured creators.** |
| FR-CW.3 | P1 | V2 | **Viral / top-performing posts.** |
| FR-CW.4 | P1 | V2 | **Leaderboards & rankings** (pg_cron). |
| FR-CW.5 | P1 | V2 | **Seasonal style trends.** |
| FR-CW.6 | P2 | V2 | **Editorial-style featured collections.** |
| FR-CW.7 | P2 | V2 | **Community challenges & spotlights.** |

### 4.6 Profile

**Purpose (PRD):** Manage personal identity, saved content, posts, and fashion preferences.

| ID | Pri | Rel | Requirement |
|---|---|---|---|
| FR-PR.1 | P0 | MVP | **User profile & bio** — including the user's public attributes (height, silhouette, coloring) per C-9. **Weight is never shown** (private, matching-only). |
| FR-PR.2 | P0 | MVP | **Saved outfits & collections** management (create/rename/organize). |
| FR-PR.3 | P0 | MVP | **Uploaded posts** listing. |
| FR-PR.4 | P0 | MVP | **Followers / following** lists. |
| FR-PR.5 | P0 | MVP | **Personal style preferences** (view/edit aesthetics, fit prefs). |
| FR-PR.6 | P0 | MVP | **Body profile & sizing (view/edit). [CHG]** Edit self-reported height/weight/silhouette/sizes. ("Re-run scan" is V2.) |
| FR-PR.7 | P1 | V2 | **Aesthetic tags** management (advanced). |
| FR-PR.8 | P0 | MVP | **Account settings & privacy controls**, including **data export/deletion** (see §7). (No weight-visibility toggle needed — weight is never displayed, C-9.) |
| FR-PR.9 | P1 | V2 | **Engagement & activity history.** |
| FR-PR.10 | P1 | **MVP** | **Color profile (view/edit). [CHG]** View/edit self-reported skin/hair/eye color (pulled into MVP with FR-ON.8). |

### 4.7 Personalization & Matching (cross-cutting)
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| FR-RC.1 | P0 | **V2** | **`body_vector` from the body scan. [CHG]** Generate/maintain a body vector for similarity matching (V2, with the scan). |
| FR-RC.2 | P0 | MVP | Generate/maintain a **style preference signal** seeded from selected aesthetics (cold-start) and refined by behavior. |
| FR-RC.3 | P1 | V2 | Generate a **color palette profile** from complexion (derived palette; V2). MVP uses categorical coloring directly. |
| FR-RC.4 | P1 | V2 | Compute **creator similarity scores** for "creators who resemble you." |
| FR-RC.5 | P0 | **MVP** | **Feed ranking. [CHG]** Rank the Feed using **declared-attribute similarity** (silhouette, height/weight band, coloring, aesthetics) + behavioral signals. (V2 upgrades this to vector-based hybrid ranking; see §8.) |
| FR-RC.6 | P1 | V2 | Provide **"why recommended"** explanations. |
| FR-RC.7 | P1 | MVP | **Cold-start** strategy for new users (profile-seeded) and new content (author-attribute/metadata-seeded). |
| FR-RC.8 | P1 | V2 | **Diversity & exploration** controls. |
| FR-RC.9 | P0 | **MVP** | **Declared-attribute matching (NEW). [CHG]** Match viewers to posts by comparing self-reported attributes on both sides (author-stamped per FR-CR.10), with **graceful match-widening** so no feed is ever empty. This is the MVP matching engine (replaces scan/shape-ratio matching). |

### 4.8 Social Graph & Interactions (cross-cutting)
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| FR-SG.1 | P0 | MVP | **Follow / unfollow** creators and users. |
| FR-SG.2 | P0 | MVP | **Save / unsave** outfits to collections. |
| FR-SG.3 | P0 | MVP | **Like** posts. |
| FR-SG.4 | P0 | MVP | **Share** posts (in-app and via OS share sheet). |
| FR-SG.5 | P1 | **MVP** | **Collections** — create, name, and organize saved content. (Pulled to MVP — core to the save loop.) |
| FR-SG.6 | P1 | V2 | **Notifications** for follows, likes, saves (Realtime + push). |
| FR-SG.7 | P2 | V2 | **Comments / community interaction** on posts. [OPEN] |
| FR-SG.8 | P0 | **MVP** | **Report / block (NEW). [CHG]** Users can **report** a post and **block** a user — baseline UGC-safety controls required now that anyone can post (C-6, feeds the moderation queue §4.9). |

### 4.9 Super-Admin Dashboard (React web)
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| FR-AD.1 | P1 | **MVP** | **Admin authentication & authorization** restricted to super-admins via `app_metadata` claim; sensitive actions via Edge Functions. (MVP: needed to operate moderation.) |
| FR-AD.2 | P1 | **MVP** | **User management (minimal)** — search, view, suspend/ban, and handle data-deletion requests. |
| FR-AD.3 | P1 | **MVP** | **Content moderation (minimal)** — review reported posts, remove content, take user actions. |
| FR-AD.4 | P0 | MVP | **Minimal moderation capability** for launch — remove content and suspend users, sufficient to operate an open-UGC product safely at MVP scale. |
| FR-AD.5 | P1 | V2 | **Analytics dashboards** — growth, engagement, content/creator performance. |
| FR-AD.6 | P2 | V2 | **Feature flags / config** — taxonomies (aesthetics, brands), trending parameters, toggles. |
| FR-AD.7 | P2 | V2 | **Creator program management** — verification, eligibility, spotlights. [OPEN] |

---

## 5. Data Requirements

### 5.1 Core entities (logical model)
| Entity | Key attributes | Notes |
|---|---|---|
| **User** | id, auth identity, name, username (unique), birthday?, gender, region, role, created_at | Backed by Supabase Auth; profile row in `public`. |
| **BodyProfile** | user_id, height_cm, **weight_kg?** (private), **body_silhouette** (self-reported), sizes, fit_preference · *(V2: scan widths/lengths/circumferences, ratios, body_shape, confidence, `body_vector`)* | **MVP: self-reported.** Height/silhouette/sizes **PUBLIC** (C-9); **weight is owner-only/private — matching-only, never returned in public payloads.** V2 adds scan-derived fields. |
| **ColorProfile** | user_id, **skin_tone (Monk ordinal 1–10)**, hair_color, eye_color · *(V2: undertone, color_palette)* | **MVP: self-reported & PUBLIC** (C-9). Skin tone stored as a Monk-10 ordinal for proximity matching (FR-ON.8); hair/eye categorical. |
| **Post** | id, author_id, media[], caption, description, aesthetics[], **author_attr_snapshot** (height, silhouette, coloring — **no weight**; an internal weight-band may be stored for matching but is never exposed), visibility, status, metrics, created_at | UGC; moderated. Author attributes stamped (FR-CR.10). |
| **Outfit / Look** | post_id, items[] | A post showcases an outfit composed of items. |
| **ClothingItem** | id, name, brand_id, category, shop_url? | Tagged in posts; shop link is V2. |
| **Brand** | id, name | Taxonomy; admin-managed. |
| **Collection** | id, owner_id, name, items[] | Saved-outfit grouping. |
| **Follow** | follower_id, followee_id, created_at | Social graph edge. |
| **Like / Save / Share** | user_id, post_id, type, created_at | Interaction events. |
| **SwipeEvent** | user_id, post_id, direction, context, created_at | Discover training signal (V2). |
| **Block** | blocker_id, blocked_id, created_at | UGC-safety (FR-SG.8). |
| **Creator** | user_id, status, analytics refs | Extends User; eligibility [OPEN]; analytics V2. |
| **Embeddings** | owner_ref, kind(body/style/color/creator), vector | Stored via pgvector (V2). |
| **Trending/Leaderboard** | scope, period, ranked_refs, computed_at | Derived by pg_cron jobs (V2). |
| **ModerationReport / AdminAction** | id, target_ref, reporter_id?, reason, status, admin_id, action, created_at | Admin/moderation (MVP minimal). |
| **Notification** | id, user_id, type, payload, read, created_at | Realtime + push (V2). |

### 5.2 Onboarding data dictionary (from PRD "Data Stored During Onboarding")
- **User attributes:** Height, Weight *(private — matching-only)*, Sizes, **Body silhouette**, Skin color, Hair color, Eye color, Gender, Region. *(MVP: all self-reported; all public except weight, per C-9.)*
- **Style attributes:** Aesthetics, Preferred silhouettes, Favorite brands (V2), Budget range (V2), Outfit swipe history (V2), Fashion goals (V2).
- **AI-derived attributes (V2):** Body similarity embeddings, Style preference embeddings, Color palette profile, Creator similarity scores, Outfit recommendation vectors.

| ID | Pri | Rel | Requirement |
|---|---|---|---|
| DR-1 | P0 | MVP | Persist all MVP onboarding attributes against the user record with normalization (units → cm/kg internally). |
| DR-2 | P0 | V2 | **(V2)** Persist **derived** scan/complexion profiles and vectors; **never persist raw scan video or face photos** server-side (C-3). |
| DR-3 | P0 | V2 | Store embeddings in **pgvector** for similarity queries. **(V2** — MVP matches via SQL attribute scoring.) |
| DR-4 | P0 | **MVP** | **Profile-data access model. [CHG]** Self-reported height/silhouette/coloring are **public profile fields** (C-9), readable by others; RLS restricts **writes** to the owner. **`weight_kg` is owner-only** (private) — never included in public profile/post read payloads; used server-side only to derive a non-exposed match band. (The owner-only-sensitive model returns for V2 scan-derived data.) |
| DR-5 | P1 | V2 | Capture **swipe/interaction events** as training signals with retention limits. |
| DR-6 | P1 | V2 | Maintain **budget range** and **fashion goals** once defined ([OPEN], §10). |

### 5.3 Data integrity & retention
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| DR-7 | P0 | MVP | Enforce referential integrity and RLS so users **write** only their own data; public profile fields are readable per C-9; admins access via privileged, audited paths. |
| DR-8 | P0 | MVP | Support **full account & data deletion** (right to erasure), cascading to profiles, posts, collections, and interactions (and V2 vectors). |
| DR-9 | P1 | V2 | Define **retention windows** for interaction logs and analytics aggregates. [OPEN] |

---

## 6. External Interface Requirements

### 6.1 User interfaces
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| EIR-1 | P0 | MVP | The mobile UI follows the visual language in `docs/design.md` (pending), informed by the design reference. |
| EIR-2 | P0 | **MVP** | **Three primary tabs — Feed, Post, Profile — [CHG]** with an onboarding flow preceding first use. (Discover and Catwalk are added in V2, expanding toward the five-tab vision.) |

### 6.2 Hardware interfaces
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| EIR-3 | P0 | **MVP** | **Camera/photo library** access for **post media** (capture/upload). *(Scan/complexion camera capture = V2.)* |
| EIR-4 | P0 | V2 | On-device **GPU/CPU** for pose/face landmarking; graceful degradation on unsupported devices. **(V2.)** |

### 6.3 Software interfaces
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| EIR-5 | P0 | V2 | **Pose detection** — MediaPipe / Google ML Kit (Flutter), 33-landmark equivalent (Appendix 11.4). **(V2.)** |
| EIR-6 | P1 | V2 | **Face/skin analysis** for complexion. [OPEN] **(V2.)** |
| EIR-7 | P0 | MVP | **Supabase Auth** — email/password, Google OAuth, Apple OAuth. |
| EIR-8 | P0 | MVP | **Supabase** — Postgres, Storage (signed URLs), Realtime, Edge Functions, pgvector (vector use V2), pg_cron (jobs V2). |
| EIR-9 | P1 | V2 | **Push notifications** — FCM / APNs. |
| EIR-10 | P1 | **MVP** | **Media handling. [CHG]** Image/video upload, storage, and delivery for posts; CDN/transcoding strategy for video [OPEN] (can start simple at MVP). |
| EIR-11 | P2 | V2 | **Shopping / affiliate** integration for tagged-product links (§10). |
| EIR-12 | P0 | V2 | **Crash reporting & analytics** SDK [OPEN] vendor. (Recommended but not gating MVP.) |
| EIR-13 | P0 | MVP | All client↔backend traffic over **HTTPS/TLS**; Realtime over secure WebSockets. |

### 6.4 Communications interfaces
*(Folded into EIR-13 above.)*

---

## 7. Non-Functional Requirements

### 7.1 Performance
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| NFR-1 | P0 | MVP | Feed interactions feel instant: gesture response < ~100 ms; feed first content visible within ~2 s on a typical connection. |
| NFR-2 | P0 | V2 | Body scan completes on-device within target time; show progress; never block the UI thread. **(V2.)** |
| NFR-3 | P1 | MVP | Media loads progressively with placeholders; videos start quickly. (Basic at MVP; adaptive delivery V2.) |

### 7.2 Scalability
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| NFR-4 | P1 | V2 | Architecture supports growth in users, media, and embeddings; pgvector tuned for similarity queries; dedicated vector store at scale. |

### 7.3 Security & Privacy
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| NFR-5 | P0 | V2 | **On-device processing** of body/face imagery; raw video/photos discarded after deriving profiles and **never uploaded** (C-3). **(V2 — no such imagery at MVP.)** |
| NFR-6 | P0 | MVP | **RLS on every table** in exposed schemas; ownership predicates (`auth.uid() = user_id`) with `TO authenticated` for writes; public profile reads per C-9; admin authorization via `app_metadata`. UPDATE policies need both `USING` and `WITH CHECK`. |
| NFR-7 | P0 | MVP | **Key hygiene** — publishable keys only in clients; `service_role`/secret keys only in Edge Functions/server. |
| NFR-8 | P0 | MVP | **Encryption** in transit (TLS) and at rest (Supabase-managed). |
| NFR-9 | P0 | **MVP** | **Consent & disclosure. [CHG]** MVP: disclose that height/silhouette/coloring are **public** and shown with posts, and that **weight is private** (matching-only, never displayed) — delivered as **layered disclosure**: a sign-up line, per-field Public/Private tags in Profile edit, and a first-post reminder (FR-ON.17, C-9). V2: explicit camera-capture consent + "estimate, not a medical device." |
| NFR-10 | P0 | MVP | **Data subject rights** — export and full deletion (GDPR/CCPA-aligned), cascading to derived data (DR-8). |
| NFR-11 | P1 | V2 | **Minors handling / age gating** — define minimum age and minor-data policy. [OPEN] |
| NFR-12 | P1 | **MVP** | **Audit logging for admin/moderation actions. [CHG]** Log admin actions on user data and content. (Pulled to MVP — open UGC + moderation make this baseline.) |
| NFR-13 | P1 | MVP | **Dependency hygiene** — pin package versions and commit lockfiles. |

### 7.4 Reliability & availability
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| NFR-14 | P0 | V2 | Graceful failure for AI steps — fall back to manual entry/edit. **(V2 — MVP is already manual entry.)** |
| NFR-15 | P1 | V2 | Reasonable offline behavior — cached content viewable; actions queue and sync. |

### 7.5 Usability & accessibility
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| NFR-16 | P0 | MVP | Onboarding is fast and skippable where non-essential; users reach value quickly. |
| NFR-17 | P1 | V2 | Accessibility — contrast, scalable text, screen-reader labels, reduced-motion, inclusive body-positive copy. (Baseline good practice always; formal pass V2.) |
| NFR-18 | P2 | V2 | Internationalization-ready; localization deferred. |

### 7.6 Compatibility
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| NFR-19 | P0 | MVP | Support iOS 15+ and Android 8.0+ (assumed; confirm — §10). |

### 7.7 Observability
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| NFR-20 | P1 | V2 | Crash reporting, performance monitoring, and product analytics for tuning. |

---

## 8. AI / ML Requirements

> **MVP AI/ML is intentionally minimal:** declared-attribute matching (FR-RC.9) — SQL scoring over self-reported fields, no on-device CV. Everything below tagged **V2** is the post-MVP intelligence layer.

### 8.1 Body scan (on-device) — **V2**
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| AI-1 | P0 | V2 | Re-implement Eugene's measurement algorithm in Dart, **preserving** the Appendix 11.4 pipeline (validation, pose landmarking, frame sampling, height-anchored scaling, width/length measurement, BMI-derived waist, Ramanujan-II circumferences, ratios, shape classification, confidence). |
| AI-2 | P0 | V2 | Produce a `BodyProfile` including a normalized **body_vector**. |
| AI-3 | P0 | V2 | Enforce sanity guards (width ≥ circumference invalid; ≥4 valid frames or `NOT_VISIBLE`). |
| AI-4 | P0 | V2 | Present results as **estimates** with confidence, allow edits, discard raw imagery. |

### 8.2 Complexion detection (on-device) — **V2**
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| AI-5 | P1 | V2 | **Auto-detect** skin tone, undertone, hair, and eye color from a face capture → `ColorProfile` + palette. **(MVP captures these as self-reported categories — FR-ON.8.)** [OPEN] method. |
| AI-6 | P1 | V2 | Results user-editable; raw face imagery discarded. |

### 8.3 Embeddings & matching
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| AI-7 | P0 | V2 | **Body similarity** via `body_vector` (pgvector cosine/L2). |
| AI-8 | P0 | MVP | **Style preference signal**: cold-start from selected aesthetics, refined by behavior. (MVP: simple attribute/tag scoring; vectorized at V2.) |
| AI-9 | P1 | V2 | **Color palette** representation usable in ranking. |
| AI-10 | P1 | V2 | **Creator similarity scores.** |
| AI-17 | P0 | **MVP** | **Declared-attribute scoring (NEW).** Score post↔viewer match from self-reported attributes (silhouette, height/weight band, coloring, aesthetics) with weighting + match-widening (implements FR-RC.9). |

### 8.4 Recommendation engine
| ID | Pri | Rel | Requirement |
|---|---|---|---|
| AI-11 | P0 | MVP | **Ranking. [CHG]** MVP: attribute-similarity + behavioral signals power the Feed. V2: hybrid vector ranking powers Feed + Discover. |
| AI-12 | P1 | V2 | **Collaborative signals** as interaction data grows. |
| AI-13 | P1 | V2 | **Exploration vs. exploitation** + diversity balancing (Discover). |
| AI-14 | P1 | V2 | **Explainability** — "why recommended" reasons. |
| AI-15 | P1 | MVP | **Cold-start** — profile-seeded for new users; author-attribute-seeded for new content. |
| AI-16 | P1 | V2 | Server-side recommendation computation (Edge Functions + pgvector), refreshed by pg_cron. |

---

## 9. Release Plan & Phasing

> **Authoritative MVP-vs-V2 map** (Eugene-confirmed 2026-06-09). Where a requirement's `Rel` marker (§4–§8) and this section disagree, **this section wins** and the table should be corrected.

### 9.1 MVP — first release (Eugene-confirmed)
**Shape:** three tabs — **Feed, Post, Profile** — self-reported onboarding, open to everyone, any user can post, declared-attribute matching.

- **Onboarding (self-reported, no camera; value-first 3-stage):** FR-ON.1–5, FR-ON.8, FR-ON.9, FR-ON.12, FR-ON.16 (teaser guest mode), FR-ON.17, **FR-ON.18 (staging), FR-ON.19 (body-type set), FR-ON.20 (required-to-post)**.
  - Captures: height, weight (optional/hideable), **body silhouette**, sizes, fit preference, **skin/hair/eye color** (simple categories), **3–10 aesthetics**; public-data disclosure.
- **Feed:** FR-HM.1–6.
- **Post (UGC, any user):** FR-CR.1–5, FR-CR.9, FR-CR.10.
- **Profile:** FR-PR.1–6, FR-PR.8, FR-PR.10.
- **Matching:** FR-RC.2, FR-RC.5, FR-RC.7, FR-RC.9; AI-8, AI-11, AI-15, AI-17.
- **Social/safety:** FR-SG.1–5, FR-SG.8.
- **Moderation/admin (minimal):** FR-CR.9, FR-AD.1–4; NFR-12.
- **Data:** DR-1, DR-3 (schema only; SQL scoring), DR-4, DR-7, DR-8.
- **Interfaces:** EIR-1, EIR-2 (3 tabs), EIR-3 (post media), EIR-7, EIR-8, EIR-10, EIR-13.
- **NFRs:** NFR-1, NFR-3, NFR-6, NFR-7, NFR-8, NFR-9, NFR-10, NFR-13, NFR-16, NFR-19.
- **Backend:** dedicated isolated Supabase project with RLS (C-8).

### 9.2 V2 — next release (the intelligence + expansion layer)
- **AI body/face scan:** FR-ON.6, FR-ON.7, FR-ON.11; AI-1–6; EIR-4, EIR-5, EIR-6; NFR-2, NFR-5, NFR-14; the body scan port (C-2) and Appendix 11.4. Offered as an **optional accuracy upgrade** over self-reported data.
- **Vector matching:** FR-RC.1, FR-RC.3, FR-RC.4; AI-7, AI-9, AI-10, AI-16; DR-3 (vector use).
- **Discover (swipe):** all FR-DS.*.
- **Catwalk:** all FR-CW.*.
- **Feed/Profile depth:** FR-HM.7–14, FR-PR.7, FR-PR.9; FR-RC.6, FR-RC.8.
- **Post depth:** FR-CR.6–8.
- **Social:** FR-SG.6 (notifications), FR-SG.7 (comments).
- **Admin/analytics:** FR-AD.5; budget/goals FR-ON.13/14, DR-6.
- **Brands:** FR-ON.10.
- **Platform:** EIR-9, EIR-12; NFR-4, NFR-11, NFR-15, NFR-17, NFR-20.

### 9.3 Later (V3+) — vision-completing & monetization
Shop/affiliate links and creator monetization (**[OPEN] business model**, FR-HM.15, EIR-11); editorial featured collections, community challenges (FR-CW.6/7); explicit outfit rating (FR-DS.13); creator program/verification (FR-AD.7); feature-flag/taxonomy admin (FR-AD.6); localization (NFR-18); dedicated vector store at scale.

---

## 10. Open Questions & Assumptions

> Tracked decisions needed from stakeholders (Eugene, Akash). Each links back to the requirements it gates. **Scan-related opens (OQ-10/11/12/16) are now V2** — non-blocking for MVP.

### 10.1 Product & policy (MVP-relevant)
- ~~**OQ-7 — Content moderation policy & tooling**~~ **RESOLVED 2026-06-09 → see `docs/moderation.md`.** Post-moderation (publish immediately), founders review reports ≤24h, no automated pre-screen at MVP, mandatory zero-tolerance EULA, report+block shipped. *Gates FR-CR.9, FR-SG.8, FR-AD.2/3/4, NFR-12.* Remaining follow-ups (EULA copy, abuse contact, CSAM runbook) tracked in that doc.
- **OQ-6 — Creator eligibility/program:** who becomes a "Creator" and how (open to all, application, verification)? At MVP anyone can post; "Creator" status/analytics is V2. *Gates Creator role, FR-AD.7.*
- ~~**OQ-18 — Weight display default**~~ **RESOLVED 2026-06-09:** weight is **matching-only, never publicly displayed** (private/owner-only; used server-side as a coarse match band). See R-6. *Was gating FR-ON.5, FR-ON.17, FR-PR.8, DR-4 — now reflected there.* (Slight deviation from Eugene's "all public" — confirm with Eugene.)

### 10.2 PRD gaps (V2)
- **OQ-1 — Onboarding Step 3 & Step 8 (missing).** *Gates FR-ON.15.*
- **OQ-2 — Budget range** step/values. *Gates FR-ON.13, DR-6.*
- **OQ-3 — Fashion goals** step/values. *Gates FR-ON.14, DR-6.*
- **OQ-4 — Preferred silhouettes** — at MVP this is the **self-reported body silhouette** (FR-ON.5); the V2 question of AI-deriving it remains. *Gates StyleProfile / §8.*

### 10.3 Technical
- **OQ-10 — (V2) Pose detection plugin & min OS versions.** *Gates A-4, EIR-5, NFR-19.*
- **OQ-11 — (V2) Complexion detection method.** *Gates AI-5, EIR-6.*
- **OQ-12 — (V2) Body scan input** (video vs photos). *Gates FR-ON.6.*
- **OQ-13 — Media storage/CDN/transcoding** strategy for post video. *Gates EIR-10, NFR-3.* (Can start simple at MVP.)
- **OQ-14 — Admin web framework** — React SPA vs Next.js. *Gates §3.3, FR-AD.*
- **OQ-15 — Analytics/crash vendor.** *Gates EIR-12, NFR-20.* (V2.)
- **OQ-16 — (V2) Access to Eugene's TypeScript repo** for the port. *Gates A-5, AI-1.*
- **OQ-17 — Data residency/region compliance** for personal data. *Gates DR-9, NFR-10.*
- **OQ-5 — Monetization / business model (later).** *Gates FR-HM.15, EIR-11, §9.3.*
- **OQ-9 — Comments/community (V2).** *Gates FR-SG.7.*
- **OQ-8 — Minors / age gating (V2).** *Gates NFR-11.*

### 10.4 Resolved (2026-06-09, Eugene)
- **R-1** AI body/face scan → **V2** (MVP uses self-reported onboarding).
- **R-2** Complexion → **in MVP**, simple self-reported categories (hair/skin/eye).
- **R-3** Matching → **declared attributes**, both sides; pose-pipeline shape-ratio matching → V2.
- **R-4** Body/coloring attributes → **public**, shared via posts (height, silhouette, coloring).
- **R-5** Any user can post (UGC) at MVP; tabs = **Feed, Post, Profile**.
- **R-6** (2026-06-09, Akash) **Weight → private**: optional, matching-only (coarse band), **never publicly displayed**. Carve-out from R-4; to confirm with Eugene.

### 10.5 Assumptions (carried forward)
A-1 height accuracy (V2); A-2 device capability (V2); A-3 not a medical device (V2); A-4 Dart pose path (V2); A-5 repo access (V2); A-6 Supabase MVP sufficiency; **A-7 self-reported attributes sufficient for a decent MVP feed** (Eugene). (See §2.7.)

---

## 11. Appendix

### 11.1 Glossary
- **Aesthetic** — named style category (Appendix 11.2).
- **Body Profile** — MVP: self-reported body data (height, weight, silhouette, sizing). V2: scan output (measurements, ratios, shape, confidence, `body_vector`).
- **Color Profile** — complexion attributes; MVP self-reported categories, V2 + derived palette.
- **Body silhouette** — the user's self-selected body-shape category (MVP body-shape input; the illustrated pick that replaces the scan).
- **Declared-attribute matching** — MVP matching on self-reported attributes on both viewer and post-author sides (no CV/vectors).
- **Embedding / vector** — numeric similarity representation (V2).
- **Creator** — publishing user with analytics access (analytics V2).
- **Look / Outfit** — styled set of tagged clothing items.
- **RLS** — Row Level Security.
- **pgvector** — Postgres vector similarity extension (V2).
- **Cold-start** — recommending for new users/content with little behavioral data.

### 11.2 Aesthetic taxonomy (from PRD, extensible)
Minimalist · Old Money · Quiet Luxury · Streetwear · Scandinavian · Casual · Vintage · Dark Academia · Coastal · Business Casual · Y2K · Techwear · Athleisure · Boho · Cottagecore · Contemporary Luxury · Preppy · Smart Casual · Edgy. *(Admin-managed; users select 3–10.)*

### 11.3 Onboarding attribute reference (MVP self-reported)
- **Body-type set:** women · men · show me both. *(Teaser selector for which silhouette chart to show; decoupled from gender identity — FR-ON.19.)*
- **Body silhouette (women):** Hourglass, Pear, Rectangle, Apple, Inverted Triangle. **(men):** Athletic, Trapezoid, Triangle, Oval, Rectangle. *(Self-selected from illustrated options; mirrors the V2 scan's `classifyShape` output so the two are interchangeable.)*
- **Skin tone:** **Monk 10-tone scale** — 10 swatches, single tap, stored as an ordinal **1–10** (lightest→deepest) so matching uses proximity rather than equality. *(Exact swatch hex + accessibility labels = design-time, `docs/design.md`. Undertone Cool/Warm/Neutral = V2.)*
- **Hair color:** Black, Brown, Blonde, Red, Gray, Other.
- **Eye color:** Brown, Blue, Green, Hazel, Gray.
- **Fit preference:** Slim, Tailored, Relaxed, Oversized, Mixed.
- **Sizes:** Tops, Bottoms, Dresses, Shoes.

### 11.4 Body-Scan Algorithm Reference — **V2**
*Provided by Eugene; current implementation is web/TypeScript. **Deferred to V2** (Eugene, 2026-06-09); not built for MVP. When ported, the measurement math below is preserved in Dart (C-2, AI-1); the capture layer (camera/frame sampling/pose call) is replaced with native Flutter equivalents. The MVP self-reported `body_silhouette` (Appendix 11.3) maps onto this algorithm's `classifyShape` output so a later scan can upgrade a self-reported profile in place.*

**Inputs**
- Video file — recorded in-app (~10 s clip) or uploaded (MP4/MOV/WEBM, ≤200 MB).
- Height in cm (`heightCm`, 100–230), Weight in kg (`weightKg`, 25–300).
- Gender (female | male | nonbinary | unspecified) — used only for shape classification.

**Libraries / tools (current web implementation)**
- `@mediapipe/tasks-vision` — Pose Landmarker (`pose_landmarker_full.task`, float16, GPU delegate), loaded once and cached.
- Browser APIs — `HTMLVideoElement`, `<canvas>` 2D context, `MediaRecorder` + `getUserMedia`.
- No server, no ML training — everything runs client-side. No external API calls during scanning; video/frames discarded after processing. Guest profile persisted to `localStorage`.

**Pipeline**
1. **Validate inputs** — reject invalid height/weight/file size.
2. **Load pose model** — lazy-load Pose Landmarker (VIDEO mode, 1 pose, min confidences 0.5).
3. **Decode & sample frames** — off-DOM video from blob URL; sample every 0.33 s from t=0.2 up to min(duration, 30 s) → ~30 frames for a 10 s clip.
4. **Per-frame pose detection** — seek, draw to canvas, `detectForVideo`; obtain 33 normalized landmarks (x,y,z,visibility ∈ [0,1]). Keep a frame only if: mean visibility of key joints (nose, shoulders, hips, knees, ankles) > 0.55; all key joints within bounds (x,y ∈ [0.02, 0.98], visibility ≥ 0.4); nose→ankle pixel height > 35% of canvas height. Store landmarks, pixelHeight, `cmPerPx`, orientation, confidence, shoulderXSpan.
5. **Pixel → cm scale (per frame)** — nose-to-ankle = 93% of stature (`NOSE_HEIGHT_FRACTION = 0.93`): `cmPerPx = heightCm / (pixelHeight / 0.93)`. User height is the only real-world anchor.
6. **Orientation classification** — heuristic from shoulder/ear x-span, nose visibility, shoulder z-depth → front / left / right / back.
7. **Frame quality filters** — need ≥4 valid frames (else `NOT_VISIBLE`); reject frames whose `cmPerPx` deviates from the median by more than max(12% of median, 2σ); select front frames sorted by shoulderXSpan (widest = most front-facing), keep top 8; if <3 front frames, fall back to top-5 by confidence.
8. **Width measurements** — per front frame: `shoulderCm = ‖L_SHOULDER − R_SHOULDER‖ · frameW · cmPerPx · 1.16`; `hipCm = ‖L_HIP − R_HIP‖ · frameW · cmPerPx · 1.18` (surface-inflation constants 1.16, 1.18). Aggregate via `robustMean` (median → MAD → drop outliers >2.5·MAD → mean the rest) → `shoulder_width`, `hip_width`.
9. **Waist width (BMI-derived)** — `bmi = weightKg / (heightCm/100)²`; `bmiAdj = clamp((bmi − 22)·0.018, −0.08, 0.22)`; `waist_width = hip_width · (0.82 + bmiAdj·0.6)`.
10. **Lengths (primary front frame)** — `torso_length = ‖shoulderMid − hipMid‖ · frameH · cmPerPx`; `leg_length = (hipMid→kneeMid + kneeMid→ankleMid) · frameH · cmPerPx`; `arm_length = (L_shoulder→L_elbow + L_elbow→L_wrist) · frameW · cmPerPx`.
11. **Circumference estimates (Ramanujan II ellipse)** — model each cross-section as an ellipse (width w, depth w·depthRatio); `hipDepthRatio = clamp(0.74 + bmiAdj, 0.62, 0.98)`, `waistDepthRatio = clamp(0.68 + bmiAdj, 0.55, 1.00)`, `chestDepthRatio = clamp(0.62 + 0.9·bmiAdj, 0.55, 0.95)`, `chest_width_est = shoulder_width · 0.92`. For each (a=w/2, b=w·depthRatio/2): `h = (a−b)²/(a+b)²`; `C = π(a+b)(1 + 3h/(10 + √(4 − 3h)))`. Yields estimated chest/waist/hip circumferences. Sanity guard: width ≥ circumference → `MEASUREMENT_VALIDATION` error.
12. **Ratios & shape classification** — `shoulder_to_hip_ratio`, `waist_to_hip_ratio`, `leg_to_torso_ratio`, `torso_to_height_ratio`. `classifyShape(...)` → BodyShape + base confidence via gender-specific thresholds (women: Hourglass / Pear / Rectangle / Apple / Inverted Triangle; men: Athletic / Trapezoid / Triangle / Oval / Rectangle).
13. **Confidence** — `confidence_score = min(99, baseConfidence·100 + min(frontSet/8, 1)·12)`.

**Outputs — `BodyProfile`**
- Identity: `height_cm`, `weight_kg`.
- Widths (cm, direct): `shoulder_width`, `hip_width`, `waist_width`.
- Lengths (cm): `torso_length`, `leg_length`, `arm_length`.
- Estimated circumferences (cm, BMI-informed ellipse): `estimated_chest_circumference`, `estimated_waist_circumference`, `estimated_hip_circumference`.
- Ratios: shoulder-to-hip, waist-to-hip, leg-to-torso, torso-to-height.
- Classification: `body_shape`, `confidence_score`.
- `body_vector`: normalized features for downstream recommendation/matching.
- `debug`: frames analyzed/used, scale median + σ, per-frame orientation/widths/confidence/used flag.

**Key assumptions / limits**
- User-entered height is accurate (only scale anchor).
- Camera distortion negligible at typical phone distances.
- Nose-to-ankle = 93% of stature is a population average.
- Waist and circumferences are modeled estimates, not direct measurements; clothing/posture/body composition affect accuracy. **Not a medical device.**

---

*End of SRS v1.2 (Draft). MVP scope confirmed by Eugene 2026-06-09; onboarding-flow design folded in 2026-06-15 (FR-ON.18/.19/.20, Monk-10, teaser guest mode, layered disclosure). Remaining §10 opens before baselining.*
