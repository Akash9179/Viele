# Viele — Supabase

**Dedicated, isolated project (hard rule C-8):**

| | |
|---|---|
| Name | `viele` |
| Project ref | `mdgublyyxcgpwvnmnlxe` |
| Org | `typtdvcjzflwpulemafi` (Akash9179's Org) |
| Region | `us-east-1` |
| Tier | Free ($0/mo) |
| Provisioned | 2026-06-15 (explicit go-ahead) |

**Only this project may ever be targeted by Viele tooling.** Never read, modify, or migrate any other project in the org.

## Migrations
Source of truth for the schema is `docs/superpowers/specs/2026-06-15-data-architecture-design.md`.

- `migrations/0001_initial_schema.sql` — tables, RLS on every table, owner-only `profiles_private` / `posts_private` isolation, helper functions, indexes, private `post-media` storage bucket.
- `migrations/0002_security_hardening.sql` — move `citext` out of `public`; move `is_blocked()` into a non-API-exposed `private` schema.

Applied via the Supabase MCP (`apply_migration`). **Security advisor returns zero findings.** Re-run after any DDL change:
`get_advisors(project_id=mdgublyyxcgpwvnmnlxe, type=security)`.

## Security model (what's enforced)
- **RLS enabled on all 11 tables**; writes are owner-scoped (`(select auth.uid()) = owner`), UPDATE carries both `USING` + `WITH CHECK`.
- **Weight + birthday** live in owner-only `profiles_private`; the post-time **weight band** in `posts_private` (no client SELECT) — sensitive data is structurally un-shareable.
- **Admin** rights come from the `app_metadata.role` claim (`public.is_admin()`), never `user_metadata`.
- v1: **all posts public**; block relationships always enforced via `private.is_blocked()`.

## Not yet built (next)
- `feed()` / `recommended_people()` `SECURITY DEFINER` matching RPCs.
- Auth providers (Apple / Google / email) configuration.
- Edge Functions for admin/moderation privileged actions (`service_role`).
- Client wiring (`supabase_flutter`) replacing mock data.

`service_role` / secret keys must live server-side only (Edge Functions) — never in the app or admin browser bundle.
