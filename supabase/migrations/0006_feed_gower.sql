-- ============================================================================
-- 0006_feed_gower.sql — Phase 0 of the matching-algorithm redesign.
--
-- Replaces the placeholder weighted-point match score in feed() (silhouette 30 /
-- height 20 / skin 15 / undertone 10 / aesthetic 25) with a Gower similarity
-- coefficient (Podani ordinal extension), per docs/matching-algorithm.md.
--
-- Why: the old formula's exact-match categorical terms hit max distance instantly
-- while graded terms only approach it at extremes, so categoricals silently
-- dominate; and the aesthetic term divided by the VIEWER's tag count only
-- (asymmetric). Gower fixes both: every feature contributes a bounded [0,1]
-- similarity, combined as a weighted average with proper missing-value
-- renormalisation (a feature absent on either side is dropped and the remaining
-- weights renormalise — no arbitrary penalty).
--
-- Weights are a TRANSPARENT PRODUCT PRIOR (not asserted as "correct" — the
-- research validates no specific fashion weighting), grouped into the three
-- pillars the product promise rests on, body-led per Eugene's intent:
--   body       0.45  → silhouette 0.27 + height 0.18
--   complexion 0.30  → skin tone  0.18 + undertone 0.12
--   aesthetic  0.25  → Jaccard set overlap of the LOOK's aesthetics vs viewer's
-- (sum = 1.00). Phase 1+ lets implicit feedback learn per-user importance.
--
-- Ordinal similarities are graded (Podani): skin tone over the Monk 1–10 scale,
-- height over a 30 cm reference range. Guests / profile-less viewers get all
-- features absent → score 0 (the app shows no match badge — honest, not "8%").
--
-- Body + complexion read from the post AUTHOR's profile (pa); aesthetic reads
-- from the POST's tagged aesthetics (po). Weight band is intentionally NOT yet
-- included (follow-up: needs posts_private read + seed weight bands).
-- ============================================================================

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
    -- Gower weighted average over present features (weight = 0 when a feature is
    -- absent on either side, so the denominator renormalises).
    (case when g.den > 0 then greatest(0, least(100, round(100 * g.num / g.den)))
          else 0 end)::int as match_pct,
    po.created_at
  from public.posts po
  join public.profiles pa on pa.id = po.author_id
  left join me on true
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
  cross join lateral (
    select
      0.27 * raw.p_sil * raw.s_sil + 0.18 * raw.p_ht * raw.s_ht
        + 0.18 * raw.p_sk * raw.s_sk + 0.12 * raw.p_und * raw.s_und
        + 0.25 * raw.p_aes * raw.s_aes as num,
      0.27 * raw.p_sil + 0.18 * raw.p_ht + 0.18 * raw.p_sk
        + 0.12 * raw.p_und + 0.25 * raw.p_aes as den
  ) g
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
