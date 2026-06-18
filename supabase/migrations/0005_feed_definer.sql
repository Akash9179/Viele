-- 0005 — feed() as SECURITY DEFINER so GUESTS (anon) can browse the public feed
-- (value-first design) without opening table RLS to anon. The function returns
-- ONLY public, active posts + public author fields + a match% (never weight),
-- and enforces visibility + block-pairs itself. Table RLS stays authenticated-only.

create or replace function public.feed()
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
    greatest(0, least(100, round(
        (case when me.body_silhouette is not null
              and pa.body_silhouette = me.body_silhouette then 30 else 0 end)
      + (20 * (1 - least(abs(coalesce(pa.height_cm,0) - coalesce(me.height_cm,0)) / 30.0, 1)))
      + (15 * (1 - least(abs(coalesce(pa.skin_tone,0) - coalesce(me.skin_tone,0)) / 9.0, 1)))
      + (case when me.undertone is not null and pa.undertone = me.undertone then 10 else 0 end)
      + (25 * (
          cardinality(array(select unnest(po.aesthetics) intersect select unnest(me.aesthetics)))::numeric
          / greatest(cardinality(coalesce(me.aesthetics, '{}')), 1)
        ))
    )))::int as match_pct,
    po.created_at
  from public.posts po
  join public.profiles pa on pa.id = po.author_id
  left join me on true
  where po.status = 'active' and po.visibility = 'public'
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = auth.uid() and b.blocked_id = po.author_id)
         or (b.blocker_id = po.author_id and b.blocked_id = auth.uid())
    )
  order by match_pct desc nulls last, po.created_at desc
  limit 100;
$$;

revoke all on function public.feed() from public;
grant execute on function public.feed() to anon, authenticated;
