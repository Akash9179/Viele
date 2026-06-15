# Viele — Post Flow (Upload & Compose, MVP) — Design Spec

| | |
|---|---|
| **Date** | 2026-06-15 |
| **Status** | Design — approved (Akash, 2026-06-15). **§8 deltas folded into `docs/SRS.md` v1.3 on 2026-06-15** (FR-CR.1/3/4/5/10 reworked; FR-CR.11/.12 added; Post entity + §4.4 purpose updated). **AMENDMENT 2026-06-15 (Eugene, SRS v1.6):** v1 = **all posts public** — the Public/Followers/Private selector (§2, §4) is **deferred to V2**; v1 compose shows a single Public state. Sections §4 (visibility RLS) and §1 first-post copy apply to V2; v1 has no visibility choice. |
| **Scope** | MVP Post tab only — the path from tapping **Post** to a published outfit, plus post-publish management. |
| **Authors** | Akash (decisions), with Claude |
| **Related** | `docs/SRS.md` v1.2 (FR-CR.1–10, FR-ON.18/.19/.20, FR-RC.9, FR-SG.1/.8, C-9, DR-4/8, NFR-6/9), `docs/moderation.md` (M-1/4/5, §5), `docs/superpowers/specs/2026-06-09-onboarding-flow-design.md`, `docs/design.md` (pending) |

> **Goal of the Post flow:** let any signed-in user publish an outfit in a few taps, stamped with enough of the author's public attributes to be matched to similar viewers — while staying inside the MVP moderation floor. This spec defines **what the flow collects, in what order, and with what gating** — not pixels (those wait for `docs/design.md`).

---

## 1. Shape: gated entry → single-screen compose → immediate publish

Posting is **single-screen compose** behind a set of **entry gates** that fire *before* the compose screen opens, so no composed work is ever lost. The author's matching attributes are completed at the gate (not mid-compose); the compose screen is then purely about the post's content.

```
Tap "Post" tab
   │
   ├─ (a) not signed in?            → Stage-2 account creation (FR-ON.16/.18);
   │                                   teaser answers migrate; return here
   │
   ├─ (b) profile incomplete?       → inline mini-form (FR-ON.20):
   │       missing height/hair/eye     height + hair + eye, then continue
   │
   ├─ (c) body-type set = "both"    → one-tap own-silhouette pick (FR-ON.19),
   │       & no own silhouette yet     used to stamp the author's posts
   │                                                                  │
   └──────────────────────────────────────► SINGLE-SCREEN COMPOSE ◄──┘
                                                  │
   photos (1–8) · caption(opt) · aesthetics(prefilled, ≥1)
   item rows(opt) · visibility(Public/Followers/Private, default Public)
                                                  │
                       first post ever? → one-line Community Guidelines
                                          reminder (FR-ON.17 layer c / NFR-9)
                                                  │
                                            [ Publish ]
                                                  │
        publishes immediately (M-1) → author profile grid
        + matched feed if Public/Followers (FR-RC.9)
```

**Why gates-first:** the FR-ON.20 required-to-post trio and the FR-ON.19 "show me both" silhouette pick are *author-stamp* prerequisites, not post content. Resolving them before compose opens keeps compose a single, lossless surface and matches the onboarding spec's "intercept, not a wall."

**EULA:** accepted at sign-up (M-5); posting does **not** re-prompt for consent — only the lightweight *first-post* guidelines reminder (§5).

---

## 2. Compose screen — field specification

Single scrollable screen; **Publish** at the bottom.

| Field | Required? | Visibility | Feeds | Values / notes |
|---|---|---|---|---|
| Photos (carousel) | **≥1** | public-with-post | feed/profile media | Camera or library (EIR-3). **Cap 8.** **No video at MVP.** Order = upload order. |
| Caption | optional | public-with-post | display | Free text. |
| Aesthetics | **≥1** | public-with-post | matching (FR-RC.9), feed | Chips **prefilled from the author's profile aesthetics** (editable); taxonomy Appendix 11.2. |
| Item rows | optional | public-with-post | "shop the look" | Repeatable list; each row = **item name** (free text) + **brand** (optional, free text) + **link** (optional URL). **No image pins, no brand catalog** (→ V2, FR-CR.3/.10/ON.10). |
| Visibility | required (default **Public**) | — | read scope | **Public / Followers / Private** (FR-CR.5). |

**Minimum valid post = ≥1 photo + ≥1 aesthetic.** Everything else is optional. Because aesthetics are prefilled from the profile, the required set is effectively zero-friction.

**Out of scope at MVP (→ V2):** drafts (FR-CR.6), in-app image cropping/editing (FR-CR.7), tap-on-image item pins, brand catalog/search (FR-ON.10), creator analytics (FR-CR.8), video.

---

## 3. Author attribute stamp (FR-CR.10) — snapshot at publish

Every post carries a **snapshot** of the author's public attributes taken **at publish time**:

- **Stamped & public (rendered with the post):** body silhouette, height, coloring (skin tone, hair, eye).
- **Weight:** the coarse **match band is derived server-side and is NEVER included in the post payload** (C-9, DR-4). It exists only to inform matching. *(This corrects the stale FR-CR.10 wording "height/weight band unless hidden" — weight is never displayed and not "hideable," it is simply never exposed.)*
- **Immutability:** editing the author's profile later does **not** rewrite past posts. A post is a historical artifact. (Onboarding spec default: not retroactive.)
- The stamp is what FR-RC.9 declared-attribute matching scores the post on for viewers, alongside the post's aesthetics.

---

## 4. Visibility & access model (RLS)

| Visibility | Who can read | Feed eligibility |
|---|---|---|
| **Public** (default) | anyone | matched feed + author profile + direct link |
| **Followers** | author + confirmed followers (FR-SG.1) | matched feed for followers; author profile |
| **Private** | author only | none (parked / personal) |

- **Writes:** `INSERT`/`UPDATE`/`DELETE` policies `TO authenticated` with ownership predicate `(select auth.uid()) = author_id`; `UPDATE` carries both `USING` and `WITH CHECK` (NFR-6).
- **Reads:** policy branches on `visibility` — `public`; **or** `visibility = 'followers'` **and** a follow row links the reader to the author; **or** reader is the owner.
- **Blocks (FR-SG.8):** a `Block` row hides the blocked user's posts from the blocker regardless of visibility (enforced in the read path).
- Public stamped attributes are readable per C-9; `weight_kg` / derived band are never in any read payload (DR-4).

---

## 5. Moderation & disclosure hooks

- **Publishes immediately** (M-1); **no automated pre-screening** at MVP (M-4).
- **Report + block** are consumption-side (FR-SG.8) and feed the moderation queue (§4.9, `docs/moderation.md` §5). Reasons: Sexual, Harassment, Violence, Illegal, Spam, IP, Other.
- **Optional auto-hide at N = 3** distinct reports before review (moderation §5) — ship if cheap, else V2.
- **First-post disclosure:** the first time a user publishes, show a **one-line Community Guidelines + public-data reminder** (FR-ON.17 layer c, NFR-9). EULA itself was accepted at sign-up (M-5) and is not re-prompted.
- Removal/takedown is an admin action (FR-AD.4); not part of the author compose flow.

---

## 6. Post-publish management

- **Delete:** author can delete a published post; deletion cascades (DR-8) — removes media, item rows, the stamp, and the post's interactions (likes/saves/collection entries).
- **Edit metadata:** caption, aesthetics, item rows, and visibility are editable after publish.
- **No media swap** (add/remove/reorder photos = effectively a new post → V2) and **no re-stamp** (the author snapshot is immutable, §3).
- Editing visibility re-applies the read scope (§4) immediately.

---

## 7. Data model

**`Post`** (new logical entity; RLS per §4):
- `id`, `author_id` (FK user)
- `media[]` — ordered photo references (Storage), 1–8
- `caption` (nullable)
- `aesthetics[]` — taxonomy keys (≥1)
- `items[]` — rows of `{ name, brand?, link? }` (0–N)
- `visibility` — `public | followers | private`
- `author_stamp` — snapshot `{ silhouette, height_cm, skin_tone (Monk 1–10), hair, eye }` taken at publish (no weight)
- `created_at`, `updated_at`
- *(server-side / not in public payload: the author's coarse weight match-band is read from the author's private profile at match time, never copied into a readable column.)*

Relations: `Post.author_id → User`; interactions (`Like`, save/`CollectionItem`) and `ModerationReport` reference `Post.id`; `Block` is evaluated in the read path.

---

## 8. Deltas to fold back into the SRS (v1.2 → v1.3)

Apply after spec approval:

- **FR-CR.1** — annotate: photo **carousel 1–8**, **no video** at MVP (camera/library, EIR-3).
- **FR-CR.3** — narrow to **lightweight item list** (name + optional brand + optional link); image pins + brand catalog → V2.
- **FR-CR.4** — note aesthetics are **prefilled from the author's profile** and **≥1 required** to publish.
- **FR-CR.5** — confirm **Public / Followers / Private** with the §4 read-RLS model.
- **FR-CR.10** — **fix wording:** stamp is a **publish-time snapshot** of silhouette + height + coloring; **weight band is server-side only, never in the post payload** (remove "height/weight band unless hidden").
- **New FR-CR.11** — **post-publish management:** delete (cascade, DR-8) + edit metadata (caption/aesthetics/items/visibility); no media swap, no re-stamp.
- **New FR-CR.12** — **entry gates:** account (FR-ON.16/.18), required-to-post mini-form (FR-ON.20), and "show me both" silhouette pick (FR-ON.19) fire before compose; first-post guidelines reminder (FR-ON.17c/NFR-9).
- **Data Requirements** — add the **`Post`** entity (§7) and its RLS to §5.1 / DR rows.

---

## 9. Open (non-blocking) follow-ups

- Exact carousel cap is set to **8** — confirm against design once `docs/design.md` exists.
- Auto-hide threshold **N = 3** — confirm "ship if cheap" call at build time (moderation §5).
- Link field on item rows: whether to validate/normalize URLs or store as-is (default: store as-is, render as external link) — build-time detail.
- Aesthetic chips prefill: cap on how many a single post may carry (default: reuse onboarding 3–10 bound, but allow as few as 1 on a post) — confirm.

---

## 10. Out of scope (this spec)

Feed ranking internals (FR-RC.9 mechanics), the admin/moderation console UX (`docs/moderation.md` §7), visual design (`docs/design.md`), comments (FR-SG.7, V2), notifications (FR-SG.6, V2), and any V2 item listed in §2.
