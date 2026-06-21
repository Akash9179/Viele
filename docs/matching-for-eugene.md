# Viele Matching — How It Works

*A plain-language overview of the matching approach. Full technical design: `docs/matching-algorithm.md`.*

---

## The core idea

**"Outfits on people like you."** A match measures how closely another person's
**declared body, complexion, and aesthetic** resemble yours — so you're seeing real looks
on people built and coloured like you. Suitability through real-world similarity, kept
transparent.

We deliberately did **not** build a stylist / "what flatters you" engine. Matching on
declared attributes — simpler and more transparent — was the original intent, and it's
the right one.

---

## What's live now (Phase 0)

We replaced the old hand-picked point weights with a proper similarity model over the
onboarding attributes, grouped into three pillars — **body-led**:

| Pillar | Attributes | Weight |
|---|---|---|
| **Body** | silhouette + height | ~45% |
| **Complexion** | skin tone + undertone | ~30% |
| **Aesthetic** | overlap of style tags | ~25% |

It scores everyone 0–100, but with three real improvements over the old version:

- **Graded comparison** — skin-tone 4 is treated as *closer* to 5 than to 9 (the old
  version was crude all-or-nothing).
- **Handles missing answers** gracefully — a skipped field just drops out, no penalty.
- **Fair across attributes** — no single field silently dominates.

Verified spread on our demo users: **100 / 75 / 68 / 41 / 32 / 30** — a believable
gradient, not everyone clustered together.

---

## How we show it — and why

We **don't** show raw percentages.

Research on dating and match apps is clear: low numbers ("29% match") erode trust and make
an app feel broken. So instead we:

- Badge only strong matches — **"Great match"** / **"Strong match"**
- Show **no badge at all** below a threshold (the look still appears in the ranked feed,
  just unlabeled)

The score is only ever a **positive** signal. It's never presented as a guarantee of
outcome — just "this is someone like you."

---

## Where it goes next (Phase 1+)

As people **like, save, follow, and swipe**, those signals progressively personalize the
feed and learn *which* attributes matter most to each individual — the app gets smarter
the more it's used. Saves and follows are the strongest signals.

We'll measure "is it working?" by **real engagement** (save / follow rate), not by guessing.

---

## Open product calls for you

- The exact band thresholds (what counts as "Great" vs "Strong" vs hidden).
- How aggressively to fill a thin feed at cold-start, while it's early and content is sparse.
- When to flip from pure similarity toward behaviour-driven ranking.
