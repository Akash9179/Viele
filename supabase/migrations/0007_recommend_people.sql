-- ============================================================================
-- 0007_recommend_people.sql — "People like you" recommendations.
--
-- Powers the Feed RECOMMENDED row and the Catwalk surface with REAL people,
-- replacing the hardcoded mockRecommended list. Same Gower similarity model as
-- feed() (0006), but profile-to-profile: body + complexion read from each
-- candidate's profile, aesthetic from the JACCARD overlap of the candidate's
-- aesthetics vs the viewer's. Weights identical to feed() so a person's "match"
-- here is consistent with the looks they post.
--
--   body       0.45  → silhouette 0.27 + height 0.18
--   complexion 0.30  → skin tone  0.18 + undertone 0.12
--   aesthetic  0.25  → Jaccard of the two profiles' aesthetics
--
-- Excludes the caller and any blocked pair. Guests (no auth.uid()) get all
-- features absent → match 0 for everyone, ordered newest-first (the app shows no
-- match badge — honest, encourages sign-up).
-- ============================================================================

create or replace function public.recommend_people()
returns table (
  id          uuid,
  display_name text,
  username    citext,
  avatar_url  text,
  match_pct   int
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
    pa.id,
    pa.display_name,
    pa.username,
    pa.avatar_url,
    (case when g.den > 0 then greatest(0, least(100, round(100 * g.num / g.den)))
          else 0 end)::int as match_pct
  from public.profiles pa
  left join me on true
  cross join lateral (
    select
      (me.body_silhouette is not null and pa.body_silhouette is not null)::int as p_sil,
      (me.height_cm is not null and pa.height_cm is not null)::int             as p_ht,
      (me.skin_tone is not null and pa.skin_tone is not null)::int             as p_sk,
      (me.undertone is not null and pa.undertone is not null)::int             as p_und,
      (coalesce(cardinality(me.aesthetics), 0) > 0
         and coalesce(cardinality(pa.aesthetics), 0) > 0)::int                 as p_aes,
      (case when me.body_silhouette = pa.body_silhouette then 1 else 0 end)::numeric          as s_sil,
      (1 - least(abs(coalesce(me.height_cm, 0) - coalesce(pa.height_cm, 0)) / 30.0, 1))::numeric as s_ht,
      (1 - least(abs(coalesce(me.skin_tone, 0) - coalesce(pa.skin_tone, 0)) / 9.0, 1))::numeric  as s_sk,
      (case when me.undertone = pa.undertone then 1 else 0 end)::numeric                       as s_und,
      coalesce(
        cardinality(array(select unnest(me.aesthetics) intersect select unnest(pa.aesthetics)))::numeric
        / nullif(cardinality(array(select unnest(me.aesthetics) union select unnest(pa.aesthetics))), 0),
        0)::numeric as s_aes
  ) raw
  cross join lateral (
    select
      0.27 * raw.p_sil * raw.s_sil + 0.18 * raw.p_ht * raw.s_ht
        + 0.18 * raw.p_sk * raw.s_sk + 0.12 * raw.p_und * raw.s_und
        + 0.25 * raw.p_aes * raw.s_aes as num,
      0.27 * raw.p_sil + 0.18 * raw.p_ht + 0.18 * raw.p_sk
        + 0.12 * raw.p_und + 0.25 * raw.p_aes as den
  ) g
  where (auth.uid() is null or pa.id <> auth.uid())
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = auth.uid() and b.blocked_id = pa.id)
         or (b.blocker_id = pa.id and b.blocked_id = auth.uid())
    )
  order by match_pct desc nulls last, pa.created_at desc
  limit 30;
$$;

revoke all on function public.recommend_people() from public;
grant execute on function public.recommend_people() to anon, authenticated;
