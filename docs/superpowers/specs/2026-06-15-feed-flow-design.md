# Viele — Feed Flow (Personalized Home, MVP) — Design Spec

| | |
|---|---|
| **Date** | 2026-06-15 |
| **Status** | Design — approved (Akash, 2026-06-15). **§10 deltas folded into `docs/SRS.md` v1.4 on 2026-06-15** (FR-HM.1/2/3/6/7/8 reworked; FR-HM.16–19 added; FR-RC.4 + AI-17 annotated; §9.1/§9.2 updated). **AMENDMENT 2026-06-15 (Eugene, SRS v1.6):** v1 = **all posts public**, so §5's visibility access reduces to: all active posts are candidates, read path enforces **Block only** (no public/followers/private branching). Visibility filtering returns in V2. |
| **Scope** | MVP **Feed** tab (the "Home" screen) — what it serves, how it's ranked, and how it behaves. Outfit-detail view included. |
| **Authors** | Akash (decisions), with Claude. Visual reference: **Eugene's Home mockup** (2026-06-15). |
| **Related** | `docs/SRS.md` v1.3 (FR-HM.*, FR-RC.5/7/9, AI-8/11/15/17, FR-SG.1–4/8, C-9, DR-3/4), Post-flow spec (`2026-06-15-post-flow-design.md`), onboarding spec (`2026-06-09-onboarding-flow-design.md`), `docs/design.md` (pending) |

> **Goal of the Feed:** open the app and immediately see real outfits worn by people built like you, in your aesthetic, each with a visible **match %** — the wedge made visible. This spec defines **what the Feed serves, how it ranks, and how it behaves** — not pixels (those wait for `docs/design.md`). The visual language follows Eugene's Home mockup.

---

## 0. Scope decision (2026-06-15)

Eugene's mockups show the **full 5-tab vision** (Home, Discover-swipe, Catwalk, Post `+`, Profile) plus modules we had deferred. **Decision (Akash, 2026-06-15): treat the mockups as the visual north star and build the 3-tab MVP subset** — **Feed (Home) + Post + Profile** — in that exact visual language. **Discover-swipe (FR-DS.*) and Catwalk remain V2.** The bottom nav shows **3 tabs at MVP**, growing to the 5-tab bar at V2. This preserves the Eugene-confirmed 2026-06-09 scope lock while adopting the mockup's look.

**Pulled lightly into MVP from V2** (cheap on declared-attribute scoring): the **Recommended-people row** (was FR-HM.7 / FR-RC.4) and a **light Trending chip** (was FR-HM.8). **Deferred / V2 chrome:** header **search** (no spec yet) and the **notification bell** (FR-SG.6).

---

## 1. Screen structure (Home mockup)

```
FOR YOU / Viele                         [search → V2] [bell → V2]
[ For You ]  Most Similar  Your Aesthetic  Trending      ← filter chips
RECOMMENDED                                       See all
( ◯94%  ◯91%  ◯88%  ◯96%  ◯89%  ◯92% … )         ← similar-people row
CURATED FEED — "Outfits on people like you"      94% match avg
┌───────────┐ ┌───────────┐
│ ●94% match│ │ ●91% match│   two-column masonry cards
│   photo   │ │   photo   │   match% badge · save · photo
│ ML Mara   │ │ EJ Ella   │   author · "aesthetic · height · size" · ♡ count
│ Quiet·5'6·S│ │ Off-Duty… │   tap → outfit detail
└───────────┘ └───────────┘
            … infinite scroll …
[ HOME ]   DISCOVER(V2)   ( + )   CATWALK(V2)   PROFILE     ← 3 tabs live at MVP
```

---

## 2. The match score (engine — FR-RC.9 / AI-17)

A weighted blend of declared-attribute similarities, each normalized to `[0,1]`, summed, and scaled to a **0–100% badge**.

| Signal | Similarity | Default weight |
|---|---|---|
| Body silhouette | graded match within the body-type set | 0.30 |
| Aesthetics | overlap of viewer↔post aesthetic sets | 0.30 |
| Skin tone | Monk-10 proximity: `1 − |Δ| / 9` | 0.15 |
| Height | band proximity | 0.15 |
| Weight band | band proximity — **server-side only, never in payload** (C-9, DR-4) | 0.10 |

- **Weights are config-tunable**, not hard-coded (admin/config surface is later; MVP ships sane defaults above).
- **Missing-signal handling:** if a signal is absent (e.g., a guest with no height, or a post whose author left weight blank), its weight is **redistributed** across present signals so the % stays honest and comparable.
- Sizes and fit preference are **not** in the MVP score (fine-grained, often blank); they may inform a later tiebreaker — out of scope here.
- The post side reads from the **author snapshot** stamped at publish (Post-flow §3); the viewer side reads the live viewer profile.
- **No "why recommended" explanation** at MVP (FR-RC.6 / AI-14 stay V2). The badge is the only surfaced signal.

---

## 3. Filter chips = sort modes over the same score

| Chip | Ranking |
|---|---|
| **For You** (default) | blended match score + light freshness boost, minus already-seen |
| **Most Similar** | pure match score, descending |
| **Your Aesthetic** | aesthetic overlap first, match score as tiebreak |
| **Trending** | top recent engagement (likes in a trailing window), **gated to the viewer's body-type set / aesthetics** — "trending among people like you," not a global firehose |

All four draw from the same candidate pool and respect the access rules in §5.

---

## 4. Never-empty: match-widening ladder (FR-RC.9, FR-RC.7)

When high-match candidates run low, widen in order until the page fills:

1. **Exact** — silhouette match (within body-type set) + aesthetic overlap ≥ 1.
2. **Relax silhouette** — any silhouette within the same body-type set.
3. **Widen skin-tone window** — larger Monk-Δ tolerance.
4. **Aesthetic-only** — drop body signals; rank by aesthetic overlap.
5. **Floor** — recent **public** posts globally, so the feed is never empty. The match % is still computed honestly (it will simply read lower).

Every tier excludes: the viewer's own posts, blocked users (either direction), and — best-effort, **session-scoped** — already-seen posts. **Persistent seen-history = V2** (DR-5).

---

## 5. Serving model & access

- **On-the-fly SQL scoring** over a recent candidate window, **keyset-paginated**, computed per request (in the query or a thin Edge Function). **No pgvector, no pg_cron precompute** — those are the V2 ranking upgrade (AI-16). Consistent with DR-3 ("schema only; SQL scoring" at MVP).
- **Visibility (Post-flow §4):** Public posts are eligible for any viewer's feed; Followers-only posts appear only for confirmed followers; Private never appears.
- **Blocks (FR-SG.8):** enforced in the read path — blocked-either-direction content is excluded.
- **Infinite scroll** with keyset pagination; **pull-to-refresh** re-runs the query.

---

## 6. Recommended-people row (lightweight MVP pull of FR-HM.7 / FR-RC.4)

- Top-N **authors** ranked by **viewer↔author** attribute similarity (the §2 score applied profile-to-profile), excluding self, already-followed, and blocked.
- Each entry: avatar + `NN%`. Tap → that user's profile; **follow** inline (FR-SG.1). **See all** → a ranked similar-people list.
- Reuses the §2 engine — no new scoring logic.

---

## 7. Card & outfit-detail content

**Feed card:**
- First photo of the post's carousel, `NN% match` badge, **save** toggle (FR-SG.2 → collections, FR-SG.5).
- Author avatar + name; one attribute line: `aesthetic · height · size`; **like count** (FR-SG.3).
- Tap → outfit detail.

**Outfit detail (FR-HM.6):**
- Full photo **carousel**; author + full **public** attribute line (incl. silhouette); caption; aesthetic chips.
- **Item rows** — `name · brand? · link?` (Post-flow §2; **no price** at MVP).
- Actions: **like, save, follow, share** (FR-SG.1–4); overflow → **report / block** (FR-SG.8).

---

## 8. Guest feed

- The teaser attributes (body-type set, aesthetics, silhouette, skin tone) feed the same §2 scoring → a matched masonry feed **with no account** (the wow). Missing height/weight redistribute per §2.
- Tapping **save** or **follow** triggers **Stage-2 account creation** (FR-ON.16 / FR-ON.18); teaser answers migrate in.

---

## 9. Data model

**No new entity.** The Feed is a read-time query over existing entities:
- `Post` (+ embedded `author_attr_snapshot`) — candidate content.
- `User` / `BodyProfile` / `ColorProfile` — the viewer's live attributes (and authors', for the people row).
- `Like` / `Save`(→`Collection`) / `Follow` / `Block` — interactions, engagement counts, access filtering.

Session-scoped "seen" exclusion is **not persisted** at MVP (a `SeenEvent`/swipe-history store is V2, DR-5).

---

## 10. Deltas to fold back into the SRS (v1.3 → v1.4)

Apply after spec approval:

- **FR-HM.1 / FR-HM.3** — confirm: **two-column masonry** of match-cards, ranked by declared-attribute similarity, with the visible **match %**.
- **FR-HM.2** — **fix:** posts render as a **photo carousel** (reconcile with FR-CR.1; **remove "videos"** at MVP).
- **New FR-HM.16** — **Match-% display:** each card/detail shows a 0–100% match from the §2 weighted attribute score (weights config-tunable; missing-signal redistribution). No "why" text (FR-RC.6 = V2).
- **New FR-HM.17** — **Feed filter chips:** For You / Most Similar / Your Aesthetic / Trending as sort modes (§3).
- **New FR-HM.18** — **Match-widening ladder** (§4) guarantees a never-empty feed (implements FR-RC.9 widening; relates FR-RC.7 cold-start).
- **New FR-HM.19** — **On-the-fly SQL serving**, keyset pagination, visibility + block enforcement (§5); pgvector/pg_cron precompute remains V2 (AI-16).
- **FR-HM.7 / FR-RC.4** — **partial MVP:** lightweight **Recommended-people row** (similar authors by attribute score) ships at MVP; richer creator-similarity stays V2.
- **FR-HM.8** — **light MVP Trending** chip (recent-likes, relevance-gated); richer trending stays V2.
- **AI-17** — add the **%-normalization** detail (weighted sum → 0–100, tunable weights, redistribution).
- **§9 / nav** — reaffirm **Discover (FR-DS.*) + Catwalk = V2**; record **3-tab nav at MVP → 5-tab at V2**; note header search + notification bell are V2.
- **Guest** — note the guest feed path (FR-ON.16/.18) is matched via the same engine.

---

## 11. Open (non-blocking) follow-ups

- Default match-score **weights** (§2) — ship the defaults above; expose tuning when an admin/config surface exists (FR-AD.6, V2).
- **Trending window** length and the exact relevance gate — build-time tuning.
- **Candidate window** size for the on-the-fly query (recency cap / row budget) — build-time, sized to early catalog volume.
- Whether the Recommended-people row appears for **guests** (default: yes, same scoring) — confirm at build.

---

## 12. Out of scope (this spec)

Discover-swipe (FR-DS.*, V2), Catwalk (V2), header search + notifications (V2 chrome), vector/precomputed ranking (AI-16, V2), persistent seen-history & swipe training (DR-5, V2), "why recommended" explanations (FR-RC.6, V2), shop/price links (FR-HM.15, V2), and visual design (`docs/design.md`).
