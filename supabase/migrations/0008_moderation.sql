-- ============================================================================
-- 0008_moderation.sql — moderation for public testing.
--
-- 1. User-level reports: moderation_reports can now target a USER (not just a
--    post). post_id becomes nullable; reported_user_id added; a row must target
--    one or the other.
-- 2. Auto-takedown: a post is auto-removed (status='removed', hidden from feed
--    and grids) once enough DISTINCT users report it — 3 reporters for any
--    reason, or 2 reporters citing a severe category (sexual/violence/illegal).
--    Distinct-reporter thresholds prevent a single malicious user nuking a post.
-- 3. Review path: admin-only moderation_queue() (aggregated open reports) and
--    moderate_post() (remove/dismiss/restore + audit trail) — callable from the
--    Supabase dashboard SQL by a founder whose JWT carries app_metadata.role
--    = 'admin', until the React admin app is built.
-- ============================================================================

-- 1 ── User-level reports ------------------------------------------------------
alter table public.moderation_reports
  alter column post_id drop not null;

alter table public.moderation_reports
  add column if not exists reported_user_id uuid
    references public.profiles(id) on delete cascade;

alter table public.moderation_reports
  drop constraint if exists moderation_reports_target_chk;
alter table public.moderation_reports
  add constraint moderation_reports_target_chk
    check (post_id is not null or reported_user_id is not null);

create index if not exists reports_reported_user_idx
  on public.moderation_reports (reported_user_id, status);

-- 2 ── Auto-takedown trigger ---------------------------------------------------
create or replace function public.auto_takedown()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  n_reporters int;
  n_severe    int;
begin
  if new.post_id is null then
    return new;
  end if;

  select count(distinct reporter_id) into n_reporters
  from public.moderation_reports
  where post_id = new.post_id and status = 'open';

  select count(distinct reporter_id) into n_severe
  from public.moderation_reports
  where post_id = new.post_id and status = 'open'
    and reason in ('sexual', 'violence', 'illegal');

  if n_reporters >= 3 or n_severe >= 2 then
    update public.posts set status = 'removed'
    where id = new.post_id and status = 'active';
  end if;

  return new;
end;
$$;

drop trigger if exists moderation_auto_takedown on public.moderation_reports;
create trigger moderation_auto_takedown
  after insert on public.moderation_reports
  for each row execute function public.auto_takedown();

-- Trigger functions must not be exposed on the REST RPC surface (the trigger
-- still fires regardless of EXECUTE grants).
revoke all on function public.auto_takedown() from public, anon, authenticated;

-- 3 ── Admin review path -------------------------------------------------------
-- Aggregated open reports. SECURITY DEFINER, but every branch is guarded by
-- is_admin() in the WHERE clause, so a non-admin caller gets zero rows.
create or replace function public.moderation_queue()
returns table (
  target_type   text,
  target_id     uuid,
  display       text,
  post_status   text,
  reasons       jsonb,
  reporters     bigint,
  last_report   timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select 'post'::text, r.post_id,
         coalesce(nullif(left(p.caption, 80), ''), '(no caption)'),
         p.status,
         to_jsonb(array_agg(distinct r.reason)),
         count(distinct r.reporter_id),
         max(r.created_at)
  from public.moderation_reports r
  join public.posts p on p.id = r.post_id
  where public.is_admin() and r.status = 'open' and r.post_id is not null
  group by r.post_id, p.caption, p.status
  union all
  select 'user'::text, r.reported_user_id,
         coalesce(pr.display_name, pr.username::text, '(user)'),
         null::text,
         to_jsonb(array_agg(distinct r.reason)),
         count(distinct r.reporter_id),
         max(r.created_at)
  from public.moderation_reports r
  join public.profiles pr on pr.id = r.reported_user_id
  where public.is_admin() and r.status = 'open' and r.reported_user_id is not null
  group by r.reported_user_id, pr.display_name, pr.username
  order by 7 desc;
$$;

-- Founder action on a reported post: remove / dismiss / restore. Records an
-- admin_actions audit row and resolves the post's open reports.
create or replace function public.moderate_post(
  p_post_id uuid,
  p_action  text,
  p_reason  text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  if p_action = 'remove' then
    update public.posts set status = 'removed' where id = p_post_id;
    update public.moderation_reports set status = 'actioned'
      where post_id = p_post_id and status = 'open';
  elsif p_action = 'dismiss' then
    update public.moderation_reports set status = 'dismissed'
      where post_id = p_post_id and status = 'open';
  elsif p_action = 'restore' then
    update public.posts set status = 'active' where id = p_post_id;
    update public.moderation_reports set status = 'dismissed'
      where post_id = p_post_id and status = 'open';
  else
    raise exception 'unknown action %', p_action;
  end if;

  insert into public.admin_actions (admin_id, target_type, target_id, action, reason)
  values (
    auth.uid(),
    'post',
    p_post_id,
    case when p_action = 'restore' then 'dismiss' else p_action end,
    p_reason
  );
end;
$$;

revoke all on function public.moderation_queue() from public;
revoke all on function public.moderate_post(uuid, text, text) from public;
grant execute on function public.moderation_queue() to authenticated;
grant execute on function public.moderate_post(uuid, text, text) to authenticated;
