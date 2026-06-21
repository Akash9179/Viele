export const meta = {
  name: 'viele-qa',
  description:
    'Full QA pass for Viele: self-cleaning interactive device test + parallel read-only verification across QA dimensions + adversarial confirmation of every finding + synthesized report',
  phases: [
    { title: 'Interactive', detail: 'run self-cleaning integration test on the iOS simulator' },
    { title: 'Verify', detail: 'parallel read-only verification per QA dimension (code + live backend)' },
    { title: 'Confirm', detail: 'adversarially verify each reported finding is real' },
  ],
}

const APP = '/Users/akashsuryavanshi/Projects/Viele/app'
const PROJECT_ID = 'mdgublyyxcgpwvnmnlxe'

const INTERACTIVE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['passed', 'summary', 'tests', 'leftoverAccounts'],
  properties: {
    passed: { type: 'boolean' },
    summary: { type: 'string' },
    tests: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['name', 'passed'],
        properties: {
          name: { type: 'string' },
          passed: { type: 'boolean' },
          note: { type: 'string' },
        },
      },
    },
    leftoverAccounts: { type: 'integer', description: 'qa.viele.* users still in auth.users after the run (should be 0)' },
  },
}

const FINDINGS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['dimension', 'checks', 'bugs'],
  properties: {
    dimension: { type: 'string' },
    checks: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['name', 'passed', 'evidence'],
        properties: {
          name: { type: 'string' },
          passed: { type: 'boolean' },
          evidence: { type: 'string', description: 'file:line or query result proving the check' },
        },
      },
    },
    bugs: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['title', 'severity', 'detail'],
        properties: {
          title: { type: 'string' },
          severity: { enum: ['low', 'medium', 'high', 'critical'] },
          location: { type: 'string', description: 'file:line, RPC, or table' },
          detail: { type: 'string' },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['isReal', 'reason'],
  properties: {
    isReal: { type: 'boolean' },
    reason: { type: 'string' },
    severity: { enum: ['low', 'medium', 'high', 'critical'] },
  },
}

// ── Phase 1: interactive device test (single agent owns the simulator) ────────
phase('Interactive')
const interactive = await agent(
  `Run Viele's self-cleaning integration test on the booted iOS simulator and report results.
Steps:
1. Find a booted sim: \`xcrun simctl list devices booted | grep iPhone\`. If none, boot "iPhone 16 Pro" (xcrun simctl boot then open -a Simulator).
2. Run (timeout 600000ms): \`cd ${APP} && flutter test integration_test/qa_smoke_test.dart -d <UDID> --dart-define=ROUTE=/home\`.
3. Parse per-test pass/fail from the output (tests: publish path, matching RPCs, weight privacy, avatar upload, report persists, signed-in UI).
4. The test self-cleans (tearDownAll deletes its throwaway account via the delete-account edge function). Confirm cleanup using the Supabase MCP tool execute_sql on project ${PROJECT_ID}: \`select count(*) as n from auth.users where email like 'qa.viele.%@example.com'\` — report that count as leftoverAccounts (expect 0).
Return the structured result. If the build fails or no sim is available, set passed=false and explain in summary.`,
  { label: 'integration-test', phase: 'Interactive', schema: INTERACTIVE_SCHEMA },
)

// ── Phase 2: parallel read-only verification per QA dimension ─────────────────
phase('Verify')

const common = `You are QA-verifying the Viele app (Flutter + Supabase). Repo: /Users/akashsuryavanshi/Projects/Viele. App code under app/lib, migrations under supabase/migrations, edge functions under supabase/functions. Supabase project id: ${PROJECT_ID} (use the Supabase MCP tools via ToolSearch for read-only execute_sql / list_migrations / get_advisors; use Bash curl for edge-function probes). READ-ONLY: do not write/insert/update/delete any data, do not create accounts. Return checks (each with file:line or query evidence) and any real bugs.`

const DIMENSIONS = [
  {
    key: 'auth-onboarding',
    prompt: `${common}
Dimension: Auth & onboarding. Verify in app/lib:
- Email sign-up/sign-in wired to Supabase (core/state/session.dart, onboarding email_auth_sheet.dart).
- "Forgot password?" present in email_auth_sheet.dart (sign-in mode) and calls sendPasswordReset.
- Settings "Change password" sends a reset (settings_screen.dart).
- Apple/Google sign-in buttons are GONE from onboarding_flow.dart (no _oauthSoon, no "coming soon"); only "Sign up with email".
Report each as a check with evidence.`,
  },
  {
    key: 'matching-rpcs',
    prompt: `${common}
Dimension: Matching RPCs. Using execute_sql (read-only SELECTs) and reading supabase/migrations/0006_feed_gower.sql + 0007_recommend_people.sql:
- feed() exists, SECURITY DEFINER, granted anon+authenticated; returns ranked posts; excludes blocked pairs; weights body 0.45/complexion 0.30/aesthetic 0.25.
- recommend_people() exists; excludes the caller (auth.uid()); guest path (auth.uid() null) returns rows with match 0, not an error.
- Run \`select count(*) from public.recommend_people()\` and \`select count(*) from public.feed()\` to confirm they execute without error.
Report checks + any bugs (e.g. self in recommendations, SQL error).`,
  },
  {
    key: 'moderation',
    prompt: `${common}
Dimension: Moderation. Read supabase/migrations/0008_moderation.sql and query the catalog (read-only):
- moderation_reports.post_id is nullable and reported_user_id column exists (information_schema.columns).
- trigger moderation_auto_takedown exists on moderation_reports (pg_trigger); auto_takedown() removes a post at >=3 distinct reporters OR >=2 severe.
- moderation_queue() and moderate_post() exist, are SECURITY DEFINER, and are guarded by is_admin() (a non-admin/postgres caller of moderation_queue() returns 0 rows without error — verify via execute_sql).
- auto_takedown() is NOT executable by anon/authenticated (revoked). Check via get_advisors security or pg_proc/acl.
Report checks + bugs.`,
  },
  {
    key: 'privacy-weight',
    prompt: `${common}
Dimension: Privacy (weight + account lifecycle). CLAUDE.md rule: weight_kg is owner-only, never in public payloads.
- Confirm feed() and recommend_people() return NO weight column (read the migration return tables; optionally execute and inspect keys).
- profiles_private is owner-only (RLS) and posts_private has no SELECT policy (read 0001/0002 or query pg_policies).
- Edge functions export-data and delete-account exist (list via Supabase MCP list_edge_functions) and require auth: curl -s -o /dev/null -w '%{http_code}' -X POST https://${PROJECT_ID}.supabase.co/functions/v1/<fn> with only the publishable key (from app/lib/core/supabase/supabase_config.dart) → expect 401.
Report checks + bugs.`,
  },
  {
    key: 'storage-buckets',
    prompt: `${common}
Dimension: Storage. Read supabase/migrations (0001 post-media, 0003/0004 hardening, 0009 avatars) and query storage.buckets / storage policies (read-only):
- buckets 'post-media' and 'avatars' exist; 'avatars' is public.
- owner-prefixed write policies exist for both (foldername-based uid match).
Report checks + bugs.`,
  },
  {
    key: 'profiles-connections-ui',
    prompt: `${common}
Dimension: Profiles & connections UI (real data, no mock). In app/lib:
- other_user_profile_screen.dart uses otherProfileProvider + userPostsProvider (real), NOT hardcoded stats/bio/chips and NOT mockFeed.
- connections_screen.dart uses followersProvider/followingProvider (real follows graph), no @mayachen, no mockFeed.
- profile.dart, profile_repository.dart expose these providers.
Grep app/lib for remaining mockFeed usages and confirm the only one is the decorative onboarding marquee (onboarding_flow.dart). Report checks + bugs.`,
  },
  {
    key: 'feed-catwalk-ui',
    prompt: `${common}
Dimension: Feed / Catwalk / outfit detail UI. In app/lib:
- feed_screen.dart: no notification bell, no filter chips, no "See all"; RECOMMENDED row uses recommendedPeopleProvider (real); renders nothing when empty.
- catwalk_screen.dart: real surface backed by feedProvider (not PlaceholderScreen).
- outfit_detail_screen.dart: shows real caption + items via postDetailProvider; no hardcoded COS/Aritzia, no fixed caption, no fake 'Size'/'Hourglass' chips, no no-op share button.
Report checks + bugs.`,
  },
  {
    key: 'settings-lifecycle-ui',
    prompt: `${common}
Dimension: Settings & account lifecycle UI. In app/lib/features/profile/presentation/settings_screen.dart:
- Email row shows the real auth email (not maya@email.com).
- Export my data calls account_repository.exportData and shares the file (not a fake snackbar).
- Delete account calls account_repository.deleteAccount then signs out (real cascade, not just sign-out).
- Privacy policy / Community guidelines / Help open real in-app content (no onTap: () {}).
- No non-functional notification toggles remain.
Report checks + bugs.`,
  },
]

const findingsRaw = await parallel(
  DIMENSIONS.map((d) => () =>
    agent(d.prompt, { label: `verify:${d.key}`, phase: 'Verify', schema: FINDINGS_SCHEMA }),
  ),
)
const findings = findingsRaw.filter(Boolean)

// ── Phase 3: adversarially confirm each reported bug ──────────────────────────
phase('Confirm')
const allBugs = findings.flatMap((f) =>
  (f.bugs || []).map((b) => ({ ...b, dimension: f.dimension })),
)

const verifiedBugs = await parallel(
  allBugs.map((b) => () =>
    agent(
      `Adversarially verify whether this QA finding is a REAL, currently-true bug in the Viele repo (/Users/akashsuryavanshi/Projects/Viele). Read the actual file/migration/DB to confirm. Default to isReal=false if you cannot reproduce it from the current code/state. Finding:\n${JSON.stringify(b, null, 2)}`,
      { label: `confirm:${b.dimension}`, phase: 'Confirm', schema: VERDICT_SCHEMA },
    ).then((v) => ({ ...b, verdict: v })),
  ),
)
const confirmedBugs = verifiedBugs.filter(Boolean).filter((b) => b.verdict && b.verdict.isReal)

const totalChecks = findings.reduce((n, f) => n + (f.checks ? f.checks.length : 0), 0)
const failedChecks = findings.flatMap((f) =>
  (f.checks || []).filter((c) => !c.passed).map((c) => ({ dimension: f.dimension, ...c })),
)

return {
  interactive,
  dimensions: findings,
  totalChecks,
  failedChecks,
  confirmedBugs,
  verdict:
    interactive.passed && confirmedBugs.length === 0 && failedChecks.length === 0
      ? 'PASS'
      : 'ISSUES_FOUND',
}
