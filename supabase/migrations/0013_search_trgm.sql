create extension if not exists pg_trgm;

create index if not exists profiles_username_trgm on public.profiles using gin (username gin_trgm_ops);
create index if not exists profiles_display_name_trgm on public.profiles using gin (display_name gin_trgm_ops);
create index if not exists posts_caption_trgm on public.posts using gin (caption gin_trgm_ops);

create or replace function public.search_people(q text, p_limit int default 20, p_offset int default 0)
returns table (id uuid, username citext, display_name text, avatar_url text)
language sql stable security definer set search_path = ''
as $$
  select p.id, p.username, p.display_name, p.avatar_url
  from public.profiles p
  where (p.username ilike '%'||q||'%' or p.display_name ilike '%'||q||'%')
    and (auth.uid() is null or p.id <> auth.uid())
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
         or (b.blocker_id = p.id and b.blocked_id = auth.uid()))
  order by greatest(public.similarity(p.username::text, q), public.similarity(coalesce(p.display_name,''), q)) desc,
           p.created_at desc
  limit p_limit offset p_offset;
$$;

create or replace function public.search_looks(q text, p_limit int default 20, p_offset int default 0)
returns table (
  id uuid, author_id uuid, author_name text, username citext, aesthetics text[],
  media jsonb, height_cm numeric, body_silhouette text, likes bigint, match_pct int, created_at timestamptz)
language sql stable security definer set search_path = ''
as $$
  select po.id, po.author_id,
         coalesce(pa.display_name, pa.username::text) as author_name, pa.username,
         po.aesthetics, po.media, pa.height_cm, pa.body_silhouette,
         (select count(*) from public.likes l where l.post_id = po.id) as likes,
         0 as match_pct, po.created_at
  from public.posts po
  join public.profiles pa on pa.id = po.author_id
  where po.status = 'active' and po.visibility = 'public'
    and (po.caption ilike '%'||q||'%'
         or exists (select 1 from unnest(po.aesthetics) a where a ilike '%'||q||'%'))
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = auth.uid() and b.blocked_id = po.author_id)
         or (b.blocker_id = po.author_id and b.blocked_id = auth.uid()))
  order by public.similarity(coalesce(po.caption,''), q) desc, po.created_at desc
  limit p_limit offset p_offset;
$$;

revoke all on function public.search_people(text, int, int) from public;
revoke all on function public.search_looks(text, int, int) from public;
grant execute on function public.search_people(text, int, int) to anon, authenticated;
grant execute on function public.search_looks(text, int, int) to anon, authenticated;
