# Viele — Onboarding Flow & Features (MVP) — Design Spec

| | |
|---|---|
| **Date** | 2026-06-09 |
| **Status** | Design — approved in brainstorm; pending written-spec review |
| **Scope** | MVP onboarding only (the path from app-open to a usable, matched profile). |
| **Authors** | Akash (decisions), with Claude |
| **Related** | `docs/SRS.md` v1.1 (FR-ON.*, C-9), `docs/Viele-MVP-Plan.md` §4, `docs/moderation.md` |

> **Goal of onboarding:** collect *just enough* to make the first feed feel like "people like me," with the least friction, while being honest about what's public. The AI scan is gone at MVP, so onboarding is pure typed/tapped input — the only real friction left is the account wall and the number/feel of fields.

---

## 1. Shape: a three-stage, value-first flow

Onboarding is **teaser-then-signup**: a tiny anonymous teaser earns the wow, the account is requested at the first save/post, and the rest of the profile is filled in gently afterward.

```
┌─ STAGE 1: TEASER (anonymous, no account) ──────────────────┐
│  1. Body-type set   "Which body chart fits you?"            │
│                     → women / men / show me both           │
│  2. Aesthetics      pick 3+ from the taxonomy               │
│  3. Silhouette      illustrated pick (from chosen set)      │
│  4. Skin tone       single tap — Monk 10-tone swatches      │
└────────────────────────────────────────────────────────────┘
              ↓
        ★ MATCHED FEED — the wow, ~1 min in
          outfits on people with similar body + vibe + complexion
              ↓
        browse · tap outfit → tagged items   (all free, no account)
              ↓
        tap SAVE or POST
              ↓
┌─ STAGE 2: ACCOUNT ─────────────────────────────────────────┐
│  Google / Apple / email (Supabase)                          │
│  + name, username (unique)                                  │
│  + brief disclosure: "your style profile is public &        │
│    shown with your posts; weight stays private"             │
│  → teaser answers migrate into the new profile              │
└─────────────────────────────────────────────────────────────┘
              ↓
        Save succeeds / continue browsing
              ↓
┌─ STAGE 3: REST OF PROFILE (gentle; never blocks browsing) ──┐
│  nudged: hair, eye, height, sizes, fit, weight(optional)    │
│  REQUIRED only when they tap Post:                          │
│    inline mini-form → height + hair + eye, then publish     │
└─────────────────────────────────────────────────────────────┘
```

**Why this shape:** with the camera cliff removed, value-before-account is the strongest expression of the wedge ("see relatable outfits within ~1 min"). The account is deferred to the moment the user wants to *keep* something. Consumers are never blocked; only *posters* must complete a minimum profile, because every post is stamped with its author's attributes for matching.

---

## 2. Field specification

| Field | Stage | Required? | Visibility | Feeds | Values |
|---|---|---|---|---|---|
| Body-type set | Teaser | required | — (selects chart) | which silhouette options to show | women · men · show me both |
| Aesthetics | Teaser | **3 min** (3–10) | public | matching + feed | Taxonomy (SRS App. 11.2) |
| Body silhouette | Teaser | required | public | matching | gender-set list (SRS App. 11.3) |
| Skin tone | Teaser | required | public | matching | **Monk 10-tone** swatches |
| Email/OAuth | Account | required | — | identity/auth | Google · Apple · email |
| Name | Account | required | public | identity | free text |
| Username | Account | required (unique) | public | identity | unique, validated |
| Hair color | Stage 3 | **req to post** | public | matching | Black/Brown/Blonde/Red/Gray/Other |
| Eye color | Stage 3 | **req to post** | public | matching | Brown/Blue/Green/Hazel/Gray |
| Height | Stage 3 | **req to post** | public | matching | ft/in or cm (normalized cm) |
| Sizes | Stage 3 | optional | public | sizing match | Tops/Bottoms/Dresses/Shoes |
| Fit preference | Stage 3 | optional | public | matching | Slim/Tailored/Relaxed/Oversized/Mixed |
| **Weight** | Stage 3 | optional | **private** | match **band** only — never rendered | lb or kg (normalized kg) |
| Birthday | Account/St.3 | optional | private | (age gating = V2) | date |
| Region | Account/St.3 | optional | public | future locale | country/region |
| Gender identity | Stage 3 | optional | public | profile (distinct from body-type set) | identity options |

**Two deliberate calls:**
1. **Required-to-post trio = height + hair + eye.** Combined with the teaser's silhouette + skin tone, that's a complete enough author stamp for good matching. Sizes/weight stay optional (fine-sizing and private-band, not the "looks like me" signal).
2. **Body-type set is decoupled from gender identity.** The teaser only needs to know *which silhouette chart* to show; gender identity is an optional profile field later. Faster teaser, more inclusive.

---

## 3. Rules & edge cases
- **Guest → account migration:** teaser answers persist in local storage and fold into the profile on signup. If the user bounces without an account, the teaser data is discarded.
- **Skip / resume:** Stage 3 is always resumable from Profile; the "complete your profile" nudge lives there and at contextual moments.
- **Incomplete-profile post attempt:** tapping Post with an incomplete profile triggers an **inline 3-field mini-form** (height + hair + eye), then publishes — an intercept, not a wall.
- **Nonbinary / "show me both":** the feed draws from both silhouette sets; the user's own silhouette pick still stamps their posts. (If they pick "both," prompt a single silhouette for their own stamp before first post.)
- **Weight handling:** optional everywhere; stored owner-only; converted server-side to a coarse match band; **never returned in any public profile/post payload** (C-9).
- **Disclosure (layered):** (a) one concise line at signup; (b) per-field **Public/Private** tags in Profile edit; (c) a one-line reminder the first time the user posts.
- **Re-editing:** every field is editable anytime from Profile; changes re-stamp future posts (not retroactive on past posts — TBD-not-blocking, default: not retroactive).

---

## 4. Data & matching notes
- Teaser answers map onto `BodyProfile` (silhouette, height later) and `ColorProfile` (skin tone now; hair/eye in Stage 3), plus `StyleProfile` (aesthetics).
- **Skin tone = Monk 10** stored as an ordinal (1–10) so matching can use proximity, not just equality.
- **Body silhouette** stored as the categorical shape (mirrors the V2 scan's `classifyShape` output so a later scan upgrades the value in place).
- Matching at MVP is **declared-attribute scoring** (SRS FR-RC.9 / AI-17): silhouette match, skin-tone proximity, aesthetic overlap, height/weight band, with **graceful widening** when the catalog is thin.

---

## 5. Deltas to fold back into the SRS (v1.1 → v1.2)
This design refines several FR-ON requirements; update the SRS after spec approval:
- **FR-ON (new staging):** split onboarding into Teaser (pre-account) vs Stage-3 (post-account); account prompt at first save/post (was implicitly account-first).
- **FR-ON.3 / new:** introduce **body-type set** as distinct from gender identity.
- **FR-ON.8:** skin tone uses the **Monk 10-tone** scale (not the 6-category set); hair/eye unchanged.
- **FR-ON (new):** **required-to-post** rule = height + hair + eye; everything else optional/skippable for consumers.
- **FR-ON.16:** guest mode at MVP is the **anonymous teaser** (browse + teaser inputs), migrating on signup — narrower than the V2 "run the scan as guest."
- **FR-ON.17 / NFR-9:** disclosure is **layered** (signup line + per-field tags + first-post reminder).

---

## 6. Out of scope (this spec)
Feed ranking internals, the Post/compose flow, moderation UX, visual design (`docs/design.md`), and the V2 AI scan onboarding path. This spec defines **what onboarding collects, in what order, with what gating** — not pixels.

---

## 7. Open (non-blocking) follow-ups
- Exact Monk swatch hex values + accessibility labels (design-time).
- Whether re-editing attributes re-stamps *past* posts (default: no).
- "Show me both" users: prompt for a single own-silhouette before first post (confirm copy).
