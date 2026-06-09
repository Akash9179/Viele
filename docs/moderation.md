# Viele — MVP Content Moderation Policy

| | |
|---|---|
| **Version** | 1.0 |
| **Date** | 2026-06-09 |
| **Status** | Decided (resolves SRS §10 **OQ-7**). Operational details (EULA copy, contact address) to finalize before store submission. |
| **Owners** | Eugene (founder), Akash (build) |
| **Related** | `docs/SRS.md` §4.4/§4.9/§7 (FR-CR.9, FR-CR.10, FR-SG.8, FR-AD.1–4, NFR-12), `CLAUDE.md` (C-6 app-store compliance) |

> **Why this exists:** Eugene's confirmed MVP lets **any user post** (the Post tab). That re-introduces a moderation obligation we'd previously designed out. This policy defines the **minimum, scale-appropriate** moderation for MVP launch — enough to operate an open-UGC app safely and to pass App Store / Play review.

---

## 1. Decisions (locked 2026-06-09)

| # | Decision | Rationale |
|---|---|---|
| M-1 | **Post-moderation model** — posts publish **immediately**; we act reactively on reports + founder spot-checks. | Keeps posting frictionless and the feed growing; acceptable to Apple/Google when reports are actioned promptly (M-3). |
| M-2 | **Reviewers = founders (Eugene/Akash)**, directly, via the minimal admin console. | Right for launch scale; no staffing cost. Revisit when report volume outgrows ad-hoc review. |
| M-3 | **Response target ≤ 24 hours** for actionable reports. | Meets Apple's stated expectation for UGC apps; sets a concrete SLA. |
| M-4 | **No automated pre-screening at MVP** — report-driven + spot-check only. | Avoids a moderation-vendor integration at MVP. Automated image-safety screening is a **V2** upgrade (see §8). |
| M-5 | **Mandatory agreement to a EULA / Community Guidelines** at sign-up, with **zero tolerance for objectionable content and abusive users**. | Required by Apple Guideline 1.2; is also our primary "filter" mechanism in lieu of automated screening. |

---

## 2. Store & legal floor (non-negotiable)

These are requirements, not choices — the app is rejected or unlawful without them.

**Apple App Store — Guideline 1.2 (User-Generated Content).** A UGC app **must** provide:
1. A method for **filtering objectionable material** from being posted — satisfied at MVP by the mandatory EULA (M-5) + reactive moderation; automated filtering is the V2 upgrade.
2. A **mechanism to report** offensive content, with **timely responses** (our ≤24h SLA, M-3).
3. The ability to **block abusive users** (FR-SG.8).
4. **Published contact information** so users can reach us.

**Google Play — User Generated Content policy.** Equivalent: in-app reporting + blocking, content standards, and a process to remove objectionable content.

**Illegal content (overrides the 24h SLA — act immediately):**
- **CSAM (child sexual abuse material):** In the US, providers must report apparent CSAM to the **NCMEC CyberTipline** (18 U.S.C. §2258A) and preserve per legal requirements. **Never** download/forward; remove, suspend the account, preserve identifiers, and report. This is a hard legal duty, not discretionary.
- Other clearly illegal content (credible threats, non-consensual intimate imagery, terrorism) → immediate removal + account suspension + escalation.

---

## 3. Content standards (Community Guidelines — what's prohibited)

Posts and profiles must not contain:
- Sexually explicit content / nudity (Viele is a fashion app, not adult content).
- Child endangerment or any CSAM.
- Harassment, bullying, hate speech, or targeted abuse.
- Violence, threats, or incitement.
- Illegal goods/services, fraud, or spam/scams.
- Non-consensual intimate imagery; doxxing / others' private information.
- Impersonation or misrepresented identity.
- IP infringement (posting others' content as your own).

> The authoritative, user-facing version lives in the **Community Guidelines** (linked from onboarding and the EULA). This section is the engineering reference; keep the two in sync.

**Note on public attributes (C-9):** body silhouette, height, and coloring are **public** by design (weight is **private** — matching-only, never displayed). Moderation does **not** treat self-reported attributes as violations; it governs **posted media, captions, tags, and conduct**.

---

## 4. User-facing mechanisms (MVP — must ship)

| Mechanism | SRS ref | Behavior |
|---|---|---|
| **Report a post** | FR-CR.9, FR-SG.8 | Any authenticated user can report a post with a reason (Sexual, Harassment, Violence, Illegal, Spam, IP, Other). Creates a `ModerationReport`. |
| **Block a user** | FR-SG.8 | Blocking hides the blocked user's content from the blocker and prevents interaction, **immediately and without review**. A `Block` row is created. |
| **Per-post visibility** | FR-CR.5 | Author controls public / followers / private at post time. |
| **EULA / Guidelines acceptance** | M-5 | Mandatory agreement at sign-up; re-acceptance on material change. |
| **Published contact** | §2 | A reachable support/abuse contact (email) surfaced in-app and on the store listing. |

---

## 5. Review flow (post-moderation)

```
        ┌─────────────────────────────────────────────┐
Post ───┤ Publishes immediately (M-1)                  │
        └─────────────────────────────────────────────┘
                    │
   ┌────────────────┴───────────────┐
   │ Report filed (user)            │   Founder spot-check (proactive)
   └────────────────┬───────────────┘                 │
                    ▼                                  │
        ┌───────────────────────────┐                 │
        │ Moderation queue          │◄────────────────┘
        │ (admin console, FR-AD.3)  │
        └────────────┬──────────────┘
                     ▼  reviewed by founder ≤24h (M-2, M-3)
   ┌───────┬─────────┬──────────┬──────────┬──────────┐
   ▼       ▼         ▼          ▼          ▼          ▼
 Dismiss  Warn   Remove post  Suspend    Ban     Escalate
 (keep)          (FR-AD.4)    user       user    (illegal →
                                                  §2, immediate)
```

- **Triage priority:** illegal/CSAM and sexual/violent reports first; spam/IP next.
- **Auto-hide-on-threshold (optional MVP nicety):** if a post accrues **N distinct reports** before review, auto-hide pending review (fail-safe). Default **N = 3**; configurable. *(Mark optional — ship if cheap, else V2.)*
- **All actions are logged** (audit, §6).

---

## 6. Actions, audit & appeals

**Action ladder (`AdminAction`):**
1. **Dismiss** — no violation; report closed.
2. **Warn** — notify the author; content stays or is edited.
3. **Remove post** — content taken down (FR-AD.4); author notified with reason.
4. **Suspend user** — temporary loss of posting/login (FR-AD.2/4).
5. **Ban user** — permanent; repeat or severe violations.
6. **Escalate** — illegal content path (§2): remove + suspend + preserve + report to authorities/NCMEC.

**Audit (NFR-12 — MVP):** every moderation action records `admin_id`, `target_ref`, `action`, `reason`, `timestamp` in `AdminAction`. Immutable/append-only.

**Appeals (MVP):** lightweight — a user may reply to the support/abuse contact to contest an action; founders re-review. A formal in-app appeals UI is **V2**.

**Data on removal/deletion:** removed content is hidden from all users; full account deletion (DR-8) cascades and erases the user's posts, profiles, collections, and interactions — except records we are legally required to preserve (e.g., CSAM evidence per §2).

---

## 7. Admin console — MVP requirements (maps to FR-AD)

The React super-admin (minimal) must support:
- **Moderation queue** of open reports, sorted by severity/recency (FR-AD.3).
- **Post actions:** view post + context, **remove**, dismiss, warn (FR-AD.4).
- **User actions:** view user, **suspend**, **ban**, handle **data-deletion** requests (FR-AD.2/4).
- **Admin auth** via `app_metadata` claim; privileged actions via Edge Functions / `service_role` server-side only (FR-AD.1, C-5).
- **Audit log** view of actions taken (NFR-12).

Everything else (analytics, queues-by-assignee, automated rules) is **V2** (FR-AD.5/6).

---

## 8. Explicitly deferred to V2

- **Automated pre-screening** (image-safety / CSAM hash-matching vendor, e.g. on upload) — M-4.
- **Formal in-app appeals workflow** and status tracking.
- **Reputation / trust scoring**, rate-limiting heuristics, repeat-offender automation.
- **Moderator roles & assignment / SLA dashboards** (beyond founders-direct).
- **Keyword/caption filters** and ML text classification.

> Trigger to revisit: report volume that founders can't clear within the 24h SLA, or an App Store reviewer requiring active filtering — whichever comes first.

---

## 9. Open follow-ups
- **Community Guidelines + EULA copy** — draft the user-facing text (zero-tolerance clause is mandatory for Apple).
- **Support/abuse contact address** — provision before store submission.
- **CSAM reporting runbook** — confirm the exact NCMEC reporting steps + evidence-preservation handling before launch (legal review recommended).
- **OQ-18 (separate)** — weight-display default; tracked in SRS §10, not part of this policy.

---

*Resolves SRS OQ-7. Update this file and the SRS together if the model or SLA changes.*
