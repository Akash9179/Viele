# Viele — Matching Algorithm Design

**Status:** research synthesized 2026-06-19; proposed design pending Akash/Eugene sign-off.
**Supersedes:** the placeholder `feed()` weighted-point formula (silhouette 30 / height 20 / skin 15 / undertone 10 / aesthetic 25).
**Source:** deep-research run (22 sources, 25 claims adversarially verified, 0 refuted). Citations inline.

Core product promise (Eugene): **"outfits on people like you"** — show a user real looks worn by people who share their declared body + complexion, kept *transparent*. Matching is **similarity** (suitability through real-world similarity), not a stylist-theory engine. This doc keeps that promise and makes it principled + evolving.

---

## TL;DR

1. **Cold-start ranker = Gower similarity** (with Podani's ordinal extension) over the declared attributes — replaces the invented weights with a principled, bounded [0,1], missing-value-tolerant score, implementable as deterministic SQL.
2. **Don't hand-tune weights.** Equal/arbitrary weights let categorical fields silently dominate. Use IQR normalization + categorical scaling now; auto-balance weights later.
3. **Evolving layer = implicit feedback, done right.** Decompose every signal into *preference + confidence* (Hu-Koren `c = 1 + α·r`): saves/follows = high confidence, likes/swipes = low, **passes/unseen are NOT hard negatives**. Re-rank the similarity candidates by this.
4. **Then graduate to pairwise learning-to-rank (BPR)** once engagement accrues — this is also how we learn *which attributes matter to each user*.
5. **Presentation: conservative, qualitative, honest.** Bands ("Great match"), badge only strong matches, **hide low/uncertain scores**. Never present it as an outcome predictor. (This directly answers the "don't make the app feel broken" concern.)
6. **Validate on engagement** with full-candidate ranking metrics (NDCG/MAP/recall@k — never sampled negatives); save-rate + follow-rate as north-star, swipe-right/like/dwell as cold-start leading proxies.

---

## Phase 0 — Cold-start content ranker (build now)

### Similarity engine: Gower (+ Podani ordinal)
Gower's coefficient combines mixed feature types into one bounded [0,1] score as a (weighted) average of per-feature scaled dissimilarities, and natively handles missing values — a direct fit for Viele's attribute set. [arXiv 2401.17041; BMC Med Res Methodol 2024 12874-024-02427-8]

Per-feature dissimilarity:
| Attribute | Type | Per-feature measure |
|---|---|---|
| Body silhouette | categorical | exact match → 0/1 |
| Undertone | categorical | exact match → 0/1 |
| Skin tone (Monk 1–10) | **ordinal** | Podani graded: `1 − |rᵢ − rⱼ| / (max−min)` — *graded*, not all-or-nothing |
| Height | ordinal/continuous | `|hᵢ − hⱼ| / range` |
| Weight band (private) | ordinal | graded band distance |
| Aesthetics | **set** | Jaccard overlap (see open Q1) |

Podani (1999) is the key upgrade for skin tone and height: a Monk-4 viewer should score *closer* to Monk-5 than Monk-9, which the current exact-match/linear mix does crudely. [Podani 1999, Extending Gower to Ordinal Characters]

### Fix the weighting bias
The current formula reproduces a known Gower flaw: a categorical mismatch instantly hits max distance 1, while graded terms only approach 1 at extremes → **categoricals silently dominate**. [BMC 2024] Remedies, in order of effort:
- **Now:** scale continuous features by IQR (Q3−Q1), not full range (outlier-robust); scale categorical contribution to match the average continuous contribution. [BMC 2024]
- **Later (with data):** automatic weighting that equalizes each variable's correlation with the final score (gawdis / de Bello 2021) — a reproducible recipe to *derive* weights instead of guessing them. [arXiv 2401.17041]

> No source validates any specific numeric weighting for *fashion/body suitability* — so we derive weights data-drivenly and let behavior (Phase 1+) learn per-user importance, rather than asserting weights a priori.

### Feed composition (the cold-start "mix")
Keep the feed full **without faking scores**:
- **Tier 1:** genuine high-similarity matches first (badged).
- **Tier 2 fill:** honestly-labeled "Popular on Viele" / "New looks" — *never* stamped with an unearned match %.
- Inject diversity/exploration so the feed isn't repetitive.

(Exact thresholds = open Q2.)

---

## Phase 1 — Implicit-feedback re-ranking (as engagement starts)

Log every interaction with a **confidence** reflecting intent strength (Hu-Koren, ICDM 2008, the canonical implicit-feedback scheme): `c = 1 + α·r`. [Hu, Koren & Volinsky]

| Signal | Preference | Relative strength `r` |
|---|---|---|
| Save | + | highest |
| Follow | + | high |
| Like | + | medium |
| Swipe-right | + | low |
| Swipe-left (pass) | weak − | low, **noisy** (observed dismissal, not hard negative) |
| Unseen | unlabeled | baseline confidence only |

**Critical:** implicit feedback gives *no reliable negative signal* — unseen posts are unlabeled, not negative; even a deliberate pass is a noisy/exposure-biased negative, never a hard one. [Hu-Koren; arXiv 2302.03472] Re-rank the Phase-0 Gower candidate set by confidence-weighted signal.

---

## Phase 2 — Pairwise learning-to-rank + lifelong loop (enough data)

- **BPR** (Rendle, UAI 2009): optimize a pairwise objective ranking observed > unobserved items — outperforms non-ranking objectives for implicit-feedback personalized ranking, and its learned per-user factors are how we infer *which attributes/aesthetics each user actually responds to*. [arXiv 1205.2618]
- **Lifelong loop:** Lambda-style batch (pg_cron refresh) + realtime stream so the model updates continuously vs retrain-from-scratch. [J. Supercomputing 2022] *(medium confidence — single source)*
- **Guardrails:** popularity bias and filter bubbles must be *actively* countered (diversity/exploration injection, per-user popularity debiasing), not hoped away. [CausalEPP, KDD 2025] *(medium confidence)*

---

## Match-score presentation (answers the trust concern directly)

The dating-app evidence is a clear warning, and it backs Akash's instinct:
- **Trust is the weakest UX dimension** across dating apps; only ~11% of users feel well-matched; all benchmarked apps had negative NPS. [MeasuringU 2024, n=280]
- A raw confidence/match number is **not a guaranteed win** and is often **ignored or misunderstood by novice users** — exactly Viele's cold-start userbase. [McNee et al., INTERACT 2003]
- OkCupid **deliberately shows the lowest (most conservative)** percentage under uncertainty. [JSTOR Daily]
- High match % has **no demonstrated correlation with real outcomes** — never over-claim. [JSTOR Daily; Finkel et al. 2012]

**→ Viele rules:**
- Prefer **qualitative bands** ("Great match," "Strong match") over raw percentages.
- **Badge only strong matches**; **hide** low or low-data scores entirely.
- Err **conservative** under uncertainty.
- Frame strictly as *"people like you"* — a positive similarity signal, never a predictive guarantee.

(Exact band cutoffs + hide-threshold = open Q4.)

---

## Validation (engagement-based)

- **Offline:** full-candidate-set ranking metrics — NDCG / MAP / recall@k. **Never sampled negatives** — they correlate only weakly with full metrics and rank recommenders unreliably. [Krichene & Rendle, KDD 2020] Cheap here because the item set is small.
- **Online north-star:** save-rate + follow-rate (strongest intent).
- **Cold-start leading proxies:** swipe-right-rate, like-rate, dwell (higher frequency → more statistical power than rare saves).
- **Guardrails:** diversity / popularity-bias / trust regressions.
- Empirical metric-power selection (Jeunen, RecSys 2024) is a *future-phase* tool — needs an experiment corpus Viele won't have yet.

---

## Open decisions (need Viele-specific calls)

1. **Aesthetic-set similarity:** plain Jaccard vs a learned pgvector embedding that captures adjacency (Quiet Luxury ≈ Minimal Chic, ≠ Streetwear). Gower has no native set term. Likely a small embedding experiment.
2. **Cold-start thresholds + fill policy:** the exact tiered/widening cutoffs and labeled-fill rules.
3. **Content→hybrid flip point:** at what engagement volume to introduce BPR, and how to blend during transition.
4. **Band scheme + hide-threshold:** exact bands, the floor below which we show nothing, and whether bands are calibrated to actual save-rate so the label stays honest.

---

## Caveats
- None of the sources are Supabase-specific — verify pgvector / SECURITY DEFINER / pg_cron against the live changelog before coding (per CLAUDE.md hard rule).
- Gower/Podani, Hu-Koren, BPR, sampled-metrics findings = high confidence (canonical). Lifelong-learning + per-user popularity = medium (single source each). Dating-app lessons are design precedent, not transferable math (OkCupid's formula needs symmetric Q&A data Viele lacks).
