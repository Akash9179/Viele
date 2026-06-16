-- Resolve security-advisor WARNs from 0001:
--  - move citext out of the public (API) schema
--  - move the SECURITY DEFINER is_blocked() into a non-API-exposed `private` schema
-- Applied to project mdgublyyxcgpwvnmnlxe via Supabase MCP (apply_migration: security_hardening).
-- After this migration the security advisor returns zero findings.

-- 1) citext extension out of the public (API) schema
alter extension citext set schema extensions;

-- 2) is_blocked() -> private schema (not exposed via PostgREST RPC)
create schema if not exists private;
grant usage on schema private to authenticated;

-- policies depend on the function; drop them first
drop policy profiles_select on public.profiles;
drop policy posts_select on public.posts;
drop function public.is_blocked(uuid, uuid);

create function private.is_blocked(a uuid, b uuid)
returns boolean language sql stable security definer
set search_path = ''
as $$
  select exists(
    select 1 from public.blocks
    where (blocker_id = a and blocked_id = b)
       or (blocker_id = b and blocked_id = a)
  );
$$;
revoke execute on function private.is_blocked(uuid, uuid) from public;
grant execute on function private.is_blocked(uuid, uuid) to authenticated;

-- recreate the two policies against private.is_blocked
create policy profiles_select on public.profiles for select to authenticated
  using ( id = (select auth.uid()) or not private.is_blocked((select auth.uid()), id) );
create policy posts_select on public.posts for select to authenticated
  using (
    author_id = (select auth.uid())
    or ( status = 'active' and visibility = 'public'
         and not private.is_blocked((select auth.uid()), author_id) )
  );
