-- ============================================================================
-- 0014_swipes_discover.sql — swipes table + discover_deck RPC
--
-- swipes: records left/right swipes per user per post (owner-only RLS).
-- discover_deck: same return columns as feed(), but:
--   * excludes already-swiped posts (not exists swipes)
--   * excludes own posts
--   * adds an aesthetic-affinity bonus (+0–10%) from right-swiped post aesthetics
--   * ordered by adjusted match_pct desc, then created_at desc, post id desc
--   * granted to authenticated only (guests use plain feed)
--
-- Gower body copied verbatim from 0006_feed_gower.sql (me CTE + raw lateral +
-- g lateral). Bonus term adds at most 0.10 to g.num/g.den, so match_pct stays
-- bounded [0,100].
-- ============================================================================

-- ---------------------------------------------------------------------------
-- swipes table
-- ---------------------------------------------------------------------------

create table if not exists public.swipes (
  user_id    uuid not null references public.profiles(id) on delete cascade,
  post_id    uuid not null references public.posts(id)    on delete cascade,
  direction  text not null check (direction in ('left', 'right')),
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);

alter table public.swipes enable row level security;

create policy swipes_select on public.swipes for select to authenticated
  using ( (select auth.uid()) = user_id );

create policy swipes_insert on public.swipes for insert to authenticated
  with check ( (select auth.uid()) = user_id );

create policy swipes_update on public.swipes for update to authenticated
  using  ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );

create policy swipes_delete on public.swipes for delete to authenticated
  using ( (select auth.uid()) = user_id );

create index if not exists swipes_user_idx on public.swipes (user_id);

-- ---------------------------------------------------------------------------
-- discover_deck RPC
-- ---------------------------------------------------------------------------

create or replace function public.discover_deck(
  p_limit  int default 20,
  p_offset int default 0
)
returns table (
  id              uuid,
  author_id       uuid,
  author_name     text,
  username        citext,
  aesthetics      text[],
  media           jsonb,
  height_cm       numeric,
  body_silhouette text,
  likes           bigint,
  match_pct       int,
  created_at      timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  with me as (
    select body_silhouette, height_cm, skin_tone, undertone, aesthetics
    from public.profiles where id = auth.uid()
  ),
  affinity as (  -- aesthetics the caller has right-swiped
    select distinct a as aes
    from public.swipes s
    join public.posts p2 on p2.id = s.post_id
    cross join lateral unnest(p2.aesthetics) a
    where s.user_id = auth.uid() and s.direction = 'right'
  )
  select
    po.id,
    po.author_id,
    coalesce(pa.display_name, pa.username::text) as author_name,
    pa.username,
    po.aesthetics,
    po.media,
    pa.height_cm,
    pa.body_silhouette,
    (select count(*) from public.likes l where l.post_id = po.id) as likes,
    -- Gower score + affinity bonus, clamped [0,100]
    (case when g.den > 0
          then greatest(0, least(100, round(100 * (g.num / g.den + bonus.b))))
          else round(100 * bonus.b)
     end)::int as match_pct,
    po.created_at
  from public.posts po
  join public.profiles pa on pa.id = po.author_id
  left join me on true
  -- ---- verbatim from 0006_feed_gower.sql: raw lateral ----
  cross join lateral (
    select
      -- presence flags (1 when the feature exists on BOTH viewer and target)
      (me.body_silhouette is not null and pa.body_silhouette is not null)::int as p_sil,
      (me.height_cm is not null and pa.height_cm is not null)::int               as p_ht,
      (me.skin_tone is not null and pa.skin_tone is not null)::int               as p_sk,
      (me.undertone is not null and pa.undertone is not null)::int               as p_und,
      (coalesce(cardinality(me.aesthetics), 0) > 0
         and coalesce(cardinality(po.aesthetics), 0) > 0)::int                   as p_aes,
      -- per-feature similarity in [0,1]
      (case when me.body_silhouette = pa.body_silhouette then 1 else 0 end)::numeric          as s_sil,
      (1 - least(abs(coalesce(me.height_cm, 0) - coalesce(pa.height_cm, 0)) / 30.0, 1))::numeric as s_ht,
      (1 - least(abs(coalesce(me.skin_tone, 0) - coalesce(pa.skin_tone, 0)) / 9.0, 1))::numeric  as s_sk,
      (case when me.undertone = pa.undertone then 1 else 0 end)::numeric                       as s_und,
      coalesce(
        cardinality(array(select unnest(me.aesthetics) intersect select unnest(po.aesthetics)))::numeric
        / nullif(cardinality(array(select unnest(me.aesthetics) union select unnest(po.aesthetics))), 0),
        0)::numeric as s_aes
  ) raw
  -- ---- verbatim from 0006_feed_gower.sql: g lateral ----
  cross join lateral (
    select
      0.27 * raw.p_sil * raw.s_sil + 0.18 * raw.p_ht * raw.s_ht
        + 0.18 * raw.p_sk * raw.s_sk + 0.12 * raw.p_und * raw.s_und
        + 0.25 * raw.p_aes * raw.s_aes as num,
      0.27 * raw.p_sil + 0.18 * raw.p_ht + 0.18 * raw.p_sk
        + 0.12 * raw.p_und + 0.25 * raw.p_aes as den
  ) g
  -- ---- affinity bonus: up to 3 matching tags → 0..0.10 ----
  cross join lateral (
    select least(
      (select count(*) from unnest(po.aesthetics) a where a in (select aes from affinity)),
      3) / 3.0 * 0.10 as b
  ) bonus
  where po.status = 'active' and po.visibility = 'public'
    and po.author_id <> auth.uid()
    and not exists (
      select 1 from public.swipes s
      where s.user_id = auth.uid() and s.post_id = po.id
    )
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = auth.uid() and b.blocked_id = po.author_id)
         or (b.blocker_id = po.author_id and b.blocked_id = auth.uid())
    )
  order by match_pct desc nulls last, po.created_at desc, po.id desc
  limit p_limit offset p_offset;
$$;

revoke all on function public.discover_deck(int, int) from public;
revoke execute on function public.discover_deck(int, int) from anon;
grant execute on function public.discover_deck(int, int) to authenticated;
