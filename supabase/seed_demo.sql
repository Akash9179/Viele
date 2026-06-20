-- ============================================================================
-- seed_demo.sql — multi-author demo data for the Viele dev project (viele,
-- ref mdgublyyxcgpwvnmnlxe). NOT a schema migration; demo content only.
--
-- Creates 5 non-login demo users (auth.users rows for the profiles FK only —
-- no password/identity, they never sign in), each with a populated public
-- profile and 2 posts. Post media REUSES the existing public storage objects
-- under the e2e_verify_user folder (the post-media bucket is public; `media`
-- is just a path string) so no storage upload is needed.
--
-- Persona attributes are tuned to the feed() match formula (0005) against the
-- e2e_verify_user viewer (hourglass / 168cm / skin 4 / neutral /
-- [Quiet Luxury, Off-Duty]) to produce a believable match% spread (~79..29%).
-- Aesthetics use the onboarding taxonomy (Quiet Luxury, Off-Duty, Minimal Chic,
-- Dark Academia, Romantic, Streetwear) so Search's aesthetic matching works.
--
-- Idempotent: deletes the seed id range first, then re-inserts. Fixed UUIDs in
-- the ...0000000000aN (users) and ...0000000000bN (posts) ranges.
--
-- TEARDOWN (remove all demo data):
--   delete from public.posts    where id::text like '00000000-0000-0000-0000-0000000000b%';
--   delete from public.profiles where id::text like '00000000-0000-0000-0000-0000000000a%';
--   delete from auth.users      where id::text like '00000000-0000-0000-0000-0000000000a%';
-- ============================================================================

begin;

-- Clean slate for the seed range (reverse FK order).
delete from public.posts    where id::text like '00000000-0000-0000-0000-0000000000b%';
delete from public.profiles where id::text like '00000000-0000-0000-0000-0000000000a%';
delete from auth.users      where id::text like '00000000-0000-0000-0000-0000000000a%';

-- ── Demo users (FK target only; non-login) ──────────────────────────────────
insert into auth.users (instance_id, id, aud, role, email, created_at, updated_at, is_sso_user, is_anonymous)
values
  ('00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-0000000000a1','authenticated','authenticated','mara.seed@viele.local',   now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-0000000000a2','authenticated','authenticated','ella.seed@viele.local',   now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-0000000000a3','authenticated','authenticated','sofia.seed@viele.local',  now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-0000000000a4','authenticated','authenticated','anya.seed@viele.local',   now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000','00000000-0000-0000-0000-0000000000a5','authenticated','authenticated','jules.seed@viele.local',  now(), now(), false, false);

-- ── Public profiles ─────────────────────────────────────────────────────────
insert into public.profiles
  (id, username, display_name, bio, region, body_type_set, body_silhouette, height_cm, skin_tone, undertone, hair_color, eye_color, aesthetics)
values
  ('00000000-0000-0000-0000-0000000000a1','mara_lindqvist','Mara Lindqvist','Stockholm. Quiet tailoring, warm neutrals.','Sweden','women','hourglass',          170, 3, 'cool',    'Blonde','Blue',  array['Quiet Luxury','Minimal Chic']),
  ('00000000-0000-0000-0000-0000000000a2','ella_romano',  'Ella Romano',   'Off-duty everything. Milan ↔ London.',         'Italy', 'women','rectangle',          165, 5, 'warm',    'Brown', 'Brown', array['Off-Duty','Streetwear']),
  ('00000000-0000-0000-0000-0000000000a3','sofia_m',      'Sofia Marchetti','Soft romantic with a minimal backbone.',       'Italy', 'women','pear',               172, 2, 'cool',    'Black', 'Green', array['Romantic','Minimal Chic']),
  ('00000000-0000-0000-0000-0000000000a4','anya_petrova', 'Anya Petrova',  'Dark academia, quiet luxury, good coats.',     'Latvia','women','hourglass',          160, 6, 'neutral', 'Brown', 'Hazel', array['Dark Academia','Quiet Luxury']),
  ('00000000-0000-0000-0000-0000000000a5','jules_okafor', 'Jules Okafor',  'Street-led, off-duty layering.',               'UK',    'women','inverted_triangle',  178, 7, 'warm',    'Black', 'Brown', array['Streetwear','Off-Duty']);

-- ── Posts (2 per author; media reuses existing public storage objects) ───────
-- author_snapshot mirrors the public profile fields the read surfaces display.
insert into public.posts (id, author_id, caption, aesthetics, items, media, visibility, status, author_snapshot, created_at)
values
  -- Mara
  ('00000000-0000-0000-0000-0000000000b1','00000000-0000-0000-0000-0000000000a1','Camel coat, ivory knit.',array['Quiet Luxury','Minimal Chic'],
    '[{"name":"Wool coat","brand":"Toteme"},{"name":"Knit","brand":"COS"}]'::jsonb,
    '["posts/b5b6bf98-e26c-4632-a3c2-2141d797100d/49b7b7d0-aebd-44c2-aa05-0c53c3349be4/0.jpg"]'::jsonb,
    'public','active',
    '{"username":"mara_lindqvist","display_name":"Mara Lindqvist","height_cm":170,"skin_tone":3,"undertone":"cool","hair_color":"Blonde","eye_color":"Blue","body_silhouette":"hourglass","aesthetics":["Quiet Luxury","Minimal Chic"]}'::jsonb,
    now() - interval '1 hour'),
  ('00000000-0000-0000-0000-0000000000b2','00000000-0000-0000-0000-0000000000a1','Tailored trousers, low heel.',array['Quiet Luxury','Minimal Chic'],
    '[{"name":"Trousers","brand":"The Row"}]'::jsonb,
    '["posts/b5b6bf98-e26c-4632-a3c2-2141d797100d/3740b876-d1a9-48a4-a62d-c91ea952239b/0.jpg"]'::jsonb,
    'public','active',
    '{"username":"mara_lindqvist","display_name":"Mara Lindqvist","height_cm":170,"skin_tone":3,"undertone":"cool","hair_color":"Blonde","eye_color":"Blue","body_silhouette":"hourglass","aesthetics":["Quiet Luxury","Minimal Chic"]}'::jsonb,
    now() - interval '2 hour'),
  -- Ella
  ('00000000-0000-0000-0000-0000000000b3','00000000-0000-0000-0000-0000000000a2','Denim, white tee, loafers.',array['Off-Duty','Streetwear'],
    '[{"name":"Straight jeans","brand":"Levi''s"},{"name":"Tee","brand":"Sunspel"}]'::jsonb,
    '["posts/b5b6bf98-e26c-4632-a3c2-2141d797100d/fe8c7601-a2be-4482-b99c-c6bfb18655f6/0.jpg"]'::jsonb,
    'public','active',
    '{"username":"ella_romano","display_name":"Ella Romano","height_cm":165,"skin_tone":5,"undertone":"warm","hair_color":"Brown","eye_color":"Brown","body_silhouette":"rectangle","aesthetics":["Off-Duty","Streetwear"]}'::jsonb,
    now() - interval '3 hour'),
  ('00000000-0000-0000-0000-0000000000b4','00000000-0000-0000-0000-0000000000a2','Bomber + cargo, sneakers.',array['Off-Duty','Streetwear'],
    '[{"name":"Bomber","brand":"Acne"}]'::jsonb,
    '["posts/b5b6bf98-e26c-4632-a3c2-2141d797100d/06b7c62e-fef3-4f5f-81a1-02522957984d/0.jpg"]'::jsonb,
    'public','active',
    '{"username":"ella_romano","display_name":"Ella Romano","height_cm":165,"skin_tone":5,"undertone":"warm","hair_color":"Brown","eye_color":"Brown","body_silhouette":"rectangle","aesthetics":["Off-Duty","Streetwear"]}'::jsonb,
    now() - interval '4 hour'),
  -- Sofia
  ('00000000-0000-0000-0000-0000000000b5','00000000-0000-0000-0000-0000000000a3','Slip dress, soft cardigan.',array['Romantic','Minimal Chic'],
    '[{"name":"Slip dress","brand":"Reformation"}]'::jsonb,
    '["posts/b5b6bf98-e26c-4632-a3c2-2141d797100d/1c849ff5-7f9b-4ecd-9072-93be52750769/0.jpg"]'::jsonb,
    'public','active',
    '{"username":"sofia_m","display_name":"Sofia Marchetti","height_cm":172,"skin_tone":2,"undertone":"cool","hair_color":"Black","eye_color":"Green","body_silhouette":"pear","aesthetics":["Romantic","Minimal Chic"]}'::jsonb,
    now() - interval '5 hour'),
  ('00000000-0000-0000-0000-0000000000b6','00000000-0000-0000-0000-0000000000a3','Lace blouse, full skirt.',array['Romantic','Minimal Chic'],
    '[{"name":"Blouse","brand":"Sézane"}]'::jsonb,
    '["posts/b5b6bf98-e26c-4632-a3c2-2141d797100d/fb9e9c2e-31b9-450a-a48b-1fd7d321c34c/0.jpg"]'::jsonb,
    'public','active',
    '{"username":"sofia_m","display_name":"Sofia Marchetti","height_cm":172,"skin_tone":2,"undertone":"cool","hair_color":"Black","eye_color":"Green","body_silhouette":"pear","aesthetics":["Romantic","Minimal Chic"]}'::jsonb,
    now() - interval '6 hour'),
  -- Anya
  ('00000000-0000-0000-0000-0000000000b7','00000000-0000-0000-0000-0000000000a4','Tweed blazer, pleated skirt.',array['Dark Academia','Quiet Luxury'],
    '[{"name":"Blazer","brand":"Massimo Dutti"}]'::jsonb,
    '["posts/b5b6bf98-e26c-4632-a3c2-2141d797100d/d2bfd7f6-4e12-441d-8ffc-19fa35677a64/0.jpg"]'::jsonb,
    'public','active',
    '{"username":"anya_petrova","display_name":"Anya Petrova","height_cm":160,"skin_tone":6,"undertone":"neutral","hair_color":"Brown","eye_color":"Hazel","body_silhouette":"hourglass","aesthetics":["Dark Academia","Quiet Luxury"]}'::jsonb,
    now() - interval '7 hour'),
  ('00000000-0000-0000-0000-0000000000b8','00000000-0000-0000-0000-0000000000a4','Long wool coat, loafers.',array['Dark Academia','Quiet Luxury'],
    '[{"name":"Coat","brand":"Max Mara"}]'::jsonb,
    '["posts/b5b6bf98-e26c-4632-a3c2-2141d797100d/0117a591-78aa-4cc1-b47b-a0240be6b623/0.jpg"]'::jsonb,
    'public','active',
    '{"username":"anya_petrova","display_name":"Anya Petrova","height_cm":160,"skin_tone":6,"undertone":"neutral","hair_color":"Brown","eye_color":"Hazel","body_silhouette":"hourglass","aesthetics":["Dark Academia","Quiet Luxury"]}'::jsonb,
    now() - interval '8 hour'),
  -- Jules
  ('00000000-0000-0000-0000-0000000000b9','00000000-0000-0000-0000-0000000000a5','Oversized hoodie, cargos.',array['Streetwear','Off-Duty'],
    '[{"name":"Hoodie","brand":"Carhartt WIP"}]'::jsonb,
    '["posts/b5b6bf98-e26c-4632-a3c2-2141d797100d/476717d9-34ae-4e33-9557-5d78c914f5d1/0.jpg"]'::jsonb,
    'public','active',
    '{"username":"jules_okafor","display_name":"Jules Okafor","height_cm":178,"skin_tone":7,"undertone":"warm","hair_color":"Black","eye_color":"Brown","body_silhouette":"inverted_triangle","aesthetics":["Streetwear","Off-Duty"]}'::jsonb,
    now() - interval '9 hour'),
  ('00000000-0000-0000-0000-0000000000ba','00000000-0000-0000-0000-0000000000a5','Track jacket, wide leg.',array['Streetwear','Off-Duty'],
    '[{"name":"Track jacket","brand":"Adidas"}]'::jsonb,
    '["posts/b5b6bf98-e26c-4632-a3c2-2141d797100d/03504286-e241-4d53-b8c0-e88e7cf9e72d/0.jpg"]'::jsonb,
    'public','active',
    '{"username":"jules_okafor","display_name":"Jules Okafor","height_cm":178,"skin_tone":7,"undertone":"warm","hair_color":"Black","eye_color":"Brown","body_silhouette":"inverted_triangle","aesthetics":["Streetwear","Off-Duty"]}'::jsonb,
    now() - interval '10 hour');

commit;
