# Viele — MVP Build Plan

**Confirmed scope**

| | |
|---|---|
| **Status** | **Confirmed by Eugene (2026-06-09).** This is the agreed MVP we build. |
| **Date** | 2026-06-08 → updated 2026-06-09 |
| **From** | Akash |
| **Purpose** | The features and functionality of the first build (MVP), agreed before we start building. |
| **Companion docs** | `PRD.docx` (original), `docs/SRS.md` (full long-term vision, MVP vs V2 tagged), `docs/moderation.md` (UGC moderation policy) |

> This document is the **MVP slice**. The full product vision (Discover, Catwalk, the AI body/face scan, etc.) still lives in the SRS and is not cancelled — it's marked **V2** there. We build the core first and add the rest in phases.

---

## 1. What we're building, in one sentence
**Open the app, tell us a few things about yourself, and see real outfits worn by people built like you, in your style — then save the ones you love and post your own.** Open to everyone, every body type and gender, from day one.

That single moment — *"these are outfits on people who actually look like me"* — is the whole bet of the MVP.

---

## 2. What changed from the first draft (Eugene's confirmation, 2026-06-09)
The original plan leaned on an AI body scan and on auto-tagging content with the pose pipeline. Eugene simplified the MVP:

- **No AI body/face scan in the MVP.** Users **type in** their info during onboarding (height, weight, body silhouette, and coloring). The AI scan becomes an **optional V2 upgrade**.
- **Complexion is in** — but **simple and self-reported** (skin / hair / eye color from short lists, e.g. brown/black/blonde), not an AI detection step.
- **Three tabs: Feed, Post, Profile.** No Discover or Catwalk at MVP.
- **Any user can post** (the Post tab) — real UGC. This brings a **lightweight moderation** requirement (`docs/moderation.md`).
- **Matching is on declared attributes** both people supply (the user's, and the poster's) — not on pose-pipeline body vectors.
- **Profile info is public** (height, silhouette, coloring) and shown with posts. **Weight is the exception:** optional, used only to improve matching, and **never shown to anyone**.

This is a **smaller, faster** MVP — the hardest part (the on-device scan) is deferred without losing the core "people like me" wedge.

---

## 3. Why this scope works
Two patterns kill apps like this:

1. **Too much onboarding before any value.** A camera-first body + face scan loses 25–60% of users. **Our fix:** the MVP has **no camera step for profiling at all** — just a few quick taps and entries, then the feed. The scan returns later (V2) as an optional accuracy boost.
2. **No content on day one.** A "people like you" feed is empty without a body-diverse library. **Our fix:** see Section 6 — seed early posters and let UGC fill the catalog, with graceful match-widening so the feed is never empty.

We win on **body-relatable matching** — outfits on people who actually resemble the user — which is the gap competitors (Mys-Tyler, Glance AI) leave open.

---

## 4. The core experience (MVP user flow)
```
1. Open app  →  create account (Google / Apple / email)
      ▼
2. Quick onboarding (no camera):
      • pick 3+ aesthetics
      • height, weight (optional), body silhouette (illustrated pick)
      • skin / hair / eye color (simple lists)
      ▼
3. SEE THE FEED  ◀── the wow
      outfits on people with a similar body + coloring, in your aesthetics
      ▼
4. Tap an outfit → see the tagged clothing items
      ▼
5. Save outfits to a collection  ·  follow people you like
      ▼
6. POST your own outfits (Post tab) → others built like you discover them
```

---

## 5. Features IN the MVP

| Feature | What it does |
|---|---|
| **Account & auth** | Google, Apple, and email sign-in (Supabase). |
| **Self-reported onboarding** | Aesthetics (3–10), height, weight (optional), body silhouette (illustrated pick), and skin/hair/eye color. No camera. |
| **Feed tab** | The home experience. Ranks outfits by how well the poster's attributes match yours (body silhouette, sizing, coloring, aesthetics). This is the product. |
| **Outfit detail** | Tap any outfit to see the clothing items tagged in it. |
| **Save + collections** | Save outfits into named collections. |
| **Follow** | Follow people whose style you like. |
| **Post tab (UGC)** | **Any user can post** their own outfits — photos/videos, caption, item/brand tags, aesthetics, visibility. Each post is stamped with the author's public attributes so the feed can match it. |
| **Moderation (minimal)** | Report a post, block a user; founders review reports ≤24h and can remove content / suspend / ban via a minimal admin console. (Full policy: `docs/moderation.md`.) |
| **Profile tab** | Identity & bio, saved/collections, your posts, followers/following, edit your attributes & aesthetics, settings with data export/deletion. |
| **Declared-attribute matching** | Match on the info both sides supply, with tolerance that **widens** where the catalog is thin so no feed is empty. |
| **Open to everyone** | Any body type, gender, or aesthetic gets a useful feed day one. |
| **Public-by-design profile** | Height, silhouette, and coloring are public and shown with posts. **Weight is private** — matching-only, never displayed. |

---

## 6. How the matching works (MVP)
```
POSTER SIDE (supply)                          VIEWER SIDE (demand)
posts an outfit                               onboarding info
        │                                              │
 post stamped with the poster's      ──▶  similarity  ◀──  viewer's attributes
 public attributes (silhouette,         scoring          (silhouette, sizing,
 height, coloring) + aesthetics           │               coloring, aesthetics)
                                feed ranked by attribute match × aesthetic,
                                tolerance WIDENS where the catalog is thin
                                              │
                            a populated, body-aware feed for ANY body, day one
```

**The key idea:** both the **viewer** and every **poster** declare the same attributes in onboarding. The feed scores how closely a post's author matches the viewer (silhouette, sizing, coloring, aesthetic) and ranks by that. Where a viewer sits in a thin part of the catalog, we relax the body tolerance and lean on aesthetic so the feed is never empty — then precision improves as more people post. (No computer vision in the MVP; the AI scan + vector matching is the V2 upgrade.)

> **Weight note:** weight feeds the match as a *coarse band* only and is never shown to anyone.

---

## 7. Content & cold-start plan
A body-matched feed needs a body-diverse library on day one. Since the MVP is **UGC-first**, content comes from people posting — so we prime the pump:

- **Seed an initial body-diverse set of posters/creators** so day-one feeds aren't empty across body types.
- **Every post is attribute-stamped**, so new posts immediately become matchable supply.
- **Graceful match-widening** keeps every feed populated while the catalog fills.
- **Moderation is in place from day one** (`docs/moderation.md`) — the cost of opening posting to everyone.

---

## 8. Technology
| Layer | Choice |
|---|---|
| **Mobile app** | Flutter (iOS + Android) — three tabs: Feed, Post, Profile. |
| **Backend** | Supabase: Auth, Postgres with Row Level Security, Storage (post media), Edge Functions (matching, moderation actions). A **brand-new, fully isolated** project — nothing shared with any other Supabase project. |
| **Matching** | Declared-attribute scoring in SQL/Edge Functions at MVP. (pgvector + the body scan = V2.) |
| **Moderation** | Minimal React admin console (remove content, suspend/ban, handle deletion); report + block in the app. |
| **Privacy** | Public profile fields (height/silhouette/coloring); **weight private, never returned in public payloads**. Full export/deletion supported. |
| **Body scan** | **Deferred to V2.** When built: Dart port of the existing engine, measurement algorithm preserved (`docs/SRS.md` Appendix 11.4). |

---

## 9. Explicitly NOT in the MVP (deferred to V2, not cancelled)
| Deferred | Why it can wait |
|---|---|
| **AI body/face scan** | Self-reported onboarding proves the wedge; the scan returns as an optional accuracy upgrade. |
| **AI complexion detection** | Coloring is captured as simple self-reported categories at MVP. |
| **Vector matching (pgvector)** | MVP matches on declared attributes; vectors come with the scan. |
| Discover swipe deck | The feed proves the core loop first. |
| Catwalk, leaderboards, trending | Needs scale and content that doesn't exist yet. |
| Notifications, comments | Beyond the core loop. |
| Full admin dashboard & analytics | MVP ships only the minimal moderation console. |
| Advanced recommendations ("why recommended", collaborative filtering, exploration) | Earn the complexity with real data. |
| Brands, budget range, fashion goals capture | Not needed for the first wow. |

All of these remain in `docs/SRS.md`, tagged **V2**.

---

## 10. Confirmed by Eugene (2026-06-09) — and what's left
**Confirmed:** no AI scan at MVP; complexion in (simple self-reported); height/weight/silhouette/coloring sufficient for a decent feed; auto-tagging keys off onboarding info; attributes public/shared via posts; any user can post.

**Decided with Akash:** post-moderation with founders reviewing ≤24h (`docs/moderation.md`); weight is private/matching-only.

**Still to do before/around build:**
- **Confirm with Eugene:** weight kept **private** (a small deviation from "everything public").
- Draft the user-facing **Community Guidelines / EULA** (zero-tolerance clause is required for App Store), provision an **abuse contact**, and a **CSAM reporting runbook** (`docs/moderation.md` §9).
- Seed plan for the **initial poster/creator roster** (terms TBD).

---

## 11. Not being decided yet
- **Monetization / business model** (shopping links, creator monetization) — a later-phase question.
- **Creator-program terms** (who, how paid, rights) — defined as we line up the initial roster.

---

*Confirmed MVP scope. `docs/SRS.md` (v1.1) is reconciled to match (MVP vs V2 tagged); `docs/moderation.md` holds the UGC policy.*
