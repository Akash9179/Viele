-- Viele MVP schema — implements docs/superpowers/specs/2026-06-15-data-architecture-design.md
-- v1: all posts public (Followers/Private -> V2). RLS on every table.
-- Applied to project mdgublyyxcgpwvnmnlxe via Supabase MCP (apply_migration: initial_schema).

create extension if not exists pgcrypto;
create extension if not exists citext;

-- ──────────────────────────────────────────────────────────────────────────
-- TABLES
-- ──────────────────────────────────────────────────────────────────────────

-- Public profile (1:1 auth.users)
create table public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  username        citext unique not null,
  display_name    text,
  avatar_url      text,
  bio             text,
  region          text,
  gender_identity text,
  body_type_set   text check (body_type_set in ('women','men','both')),
  body_silhouette text check (body_silhouette in ('hourglass','pear','rectangle','apple','inverted_triangle','not_sure')),
  height_cm       numeric,
  skin_tone       smallint check (skin_tone between 1 and 10),
  undertone       text check (undertone in ('warm','cool','neutral','unsure')),
  hair_color      text,
  eye_color       text,
  sizes           jsonb,
  fit_preference  text,
  aesthetics      text[] not null default '{}',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Owner-only sensitive fields (split out because RLS is row-level, not column-level)
create table public.profiles_private (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  weight_kg  numeric,
  birthday   date
);

-- Posts (v1 all public)
create table public.posts (
  id              uuid primary key default gen_random_uuid(),
  author_id       uuid not null references public.profiles(id) on delete cascade,
  caption         text,
  aesthetics      text[] not null default '{}',
  items           jsonb not null default '[]',
  media           jsonb not null default '[]',
  visibility      text not null default 'public' check (visibility in ('public','followers','private')),
  status          text not null default 'active' check (status in ('active','removed')),
  author_snapshot jsonb not null default '{}',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Publish-time weight band — never client-readable (matching only)
create table public.posts_private (
  post_id            uuid primary key references public.posts(id) on delete cascade,
  author_weight_band smallint
);

create table public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  followee_id uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);

create table public.likes (
  user_id    uuid not null references public.profiles(id) on delete cascade,
  post_id    uuid not null references public.posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);

create table public.collections (
  id         uuid primary key default gen_random_uuid(),
  owner_id   uuid not null references public.profiles(id) on delete cascade,
  name       text not null,
  created_at timestamptz not null default now()
);

create table public.collection_items (
  collection_id uuid not null references public.collections(id) on delete cascade,
  post_id       uuid not null references public.posts(id) on delete cascade,
  created_at    timestamptz not null default now(),
  primary key (collection_id, post_id)
);

create table public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table public.moderation_reports (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid not null references public.posts(id) on delete cascade,
  reporter_id uuid references public.profiles(id) on delete set null,
  reason      text not null check (reason in ('sexual','harassment','violence','illegal','spam','ip','other')),
  status      text not null default 'open' check (status in ('open','actioned','dismissed')),
  created_at  timestamptz not null default now()
);

create table public.admin_actions (
  id          uuid primary key default gen_random_uuid(),
  admin_id    uuid not null references public.profiles(id),
  target_type text not null check (target_type in ('post','user')),
  target_id   uuid not null,
  action      text not null check (action in ('dismiss','warn','remove','suspend','ban','escalate')),
  reason      text,
  created_at  timestamptz not null default now()
);

-- ──────────────────────────────────────────────────────────────────────────
-- INDEXES
-- ──────────────────────────────────────────────────────────────────────────
create index profiles_aesthetics_gin  on public.profiles using gin (aesthetics);
create index posts_aesthetics_gin      on public.posts using gin (aesthetics);
create index posts_recent_idx          on public.posts (status, visibility, created_at desc);
create index follows_followee_idx      on public.follows (followee_id);
create index follows_follower_idx      on public.follows (follower_id);
create index likes_post_idx            on public.likes (post_id);
create index collection_items_post_idx on public.collection_items (post_id);
create index blocks_blocker_idx        on public.blocks (blocker_id);
create index blocks_blocked_idx        on public.blocks (blocked_id);
create index reports_status_idx        on public.moderation_reports (status, created_at);

-- ──────────────────────────────────────────────────────────────────────────
-- HELPER FUNCTIONS
-- ──────────────────────────────────────────────────────────────────────────

-- Admin claim lives in app_metadata only (never user-editable user_metadata)
create or replace function public.is_admin()
returns boolean language sql stable
set search_path = ''
as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false);
$$;

-- NOTE: is_blocked() is created here in public, then relocated to the private
-- schema in 0002_security_hardening.sql (so it is not exposed via the REST API).
create or replace function public.is_blocked(a uuid, b uuid)
returns boolean language sql stable security definer
set search_path = ''
as $$
  select exists(
    select 1 from public.blocks
    where (blocker_id = a and blocked_id = b)
       or (blocker_id = b and blocked_id = a)
  );
$$;

create or replace function public.set_updated_at()
returns trigger language plpgsql
set search_path = ''
as $$ begin new.updated_at = now(); return new; end; $$;

create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger posts_updated_at before update on public.posts
  for each row execute function public.set_updated_at();

-- ──────────────────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY — enabled on EVERY table
-- ──────────────────────────────────────────────────────────────────────────
alter table public.profiles           enable row level security;
alter table public.profiles_private   enable row level security;
alter table public.posts              enable row level security;
alter table public.posts_private      enable row level security;
alter table public.follows            enable row level security;
alter table public.likes              enable row level security;
alter table public.collections        enable row level security;
alter table public.collection_items   enable row level security;
alter table public.blocks             enable row level security;
alter table public.moderation_reports enable row level security;
alter table public.admin_actions      enable row level security;

-- profiles: public attrs readable by any authenticated (minus blocks); owner writes
create policy profiles_select on public.profiles for select to authenticated
  using ( id = (select auth.uid()) or not public.is_blocked((select auth.uid()), id) );
create policy profiles_insert on public.profiles for insert to authenticated
  with check ( id = (select auth.uid()) );
create policy profiles_update on public.profiles for update to authenticated
  using ( id = (select auth.uid()) ) with check ( id = (select auth.uid()) );

-- profiles_private: OWNER ONLY (weight, birthday)
create policy profiles_private_all on public.profiles_private for all to authenticated
  using ( profile_id = (select auth.uid()) ) with check ( profile_id = (select auth.uid()) );

-- posts: v1 all public + active + not blocked; author sees own; author writes
create policy posts_select on public.posts for select to authenticated
  using (
    author_id = (select auth.uid())
    or ( status = 'active' and visibility = 'public'
         and not public.is_blocked((select auth.uid()), author_id) )
  );
create policy posts_insert on public.posts for insert to authenticated
  with check ( author_id = (select auth.uid()) );
create policy posts_update on public.posts for update to authenticated
  using ( author_id = (select auth.uid()) ) with check ( author_id = (select auth.uid()) );
create policy posts_delete on public.posts for delete to authenticated
  using ( author_id = (select auth.uid()) );

-- posts_private: NO client SELECT (matching only). Author may insert the band at publish.
create policy posts_private_insert on public.posts_private for insert to authenticated
  with check ( (select author_id from public.posts where id = post_id) = (select auth.uid()) );

-- follows / likes: counts readable by authenticated; owner writes
create policy follows_select on public.follows for select to authenticated using ( true );
create policy follows_insert on public.follows for insert to authenticated
  with check ( follower_id = (select auth.uid()) );
create policy follows_delete on public.follows for delete to authenticated
  using ( follower_id = (select auth.uid()) );

create policy likes_select on public.likes for select to authenticated using ( true );
create policy likes_insert on public.likes for insert to authenticated
  with check ( user_id = (select auth.uid()) );
create policy likes_delete on public.likes for delete to authenticated
  using ( user_id = (select auth.uid()) );

-- collections / saved: OWNER ONLY
create policy collections_all on public.collections for all to authenticated
  using ( owner_id = (select auth.uid()) ) with check ( owner_id = (select auth.uid()) );
create policy collection_items_all on public.collection_items for all to authenticated
  using ( (select owner_id from public.collections where id = collection_id) = (select auth.uid()) )
  with check ( (select owner_id from public.collections where id = collection_id) = (select auth.uid()) );

-- blocks: OWNER ONLY
create policy blocks_select on public.blocks for select to authenticated
  using ( blocker_id = (select auth.uid()) );
create policy blocks_insert on public.blocks for insert to authenticated
  with check ( blocker_id = (select auth.uid()) );
create policy blocks_delete on public.blocks for delete to authenticated
  using ( blocker_id = (select auth.uid()) );

-- moderation_reports: reporter or admin reads; reporter inserts; admin updates
create policy reports_select on public.moderation_reports for select to authenticated
  using ( reporter_id = (select auth.uid()) or public.is_admin() );
create policy reports_insert on public.moderation_reports for insert to authenticated
  with check ( reporter_id = (select auth.uid()) );
create policy reports_update on public.moderation_reports for update to authenticated
  using ( public.is_admin() ) with check ( public.is_admin() );

-- admin_actions: admin only, append-only
create policy admin_actions_select on public.admin_actions for select to authenticated
  using ( public.is_admin() );
create policy admin_actions_insert on public.admin_actions for insert to authenticated
  with check ( public.is_admin() and admin_id = (select auth.uid()) );

-- ──────────────────────────────────────────────────────────────────────────
-- STORAGE — private post-media bucket; owner-prefixed writes, authenticated reads (v1)
-- Path convention: post-media/posts/{author_id}/{post_id}/{n}
-- ──────────────────────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
  values ('post-media', 'post-media', false)
  on conflict (id) do nothing;

create policy "post-media read" on storage.objects for select to authenticated
  using ( bucket_id = 'post-media' );
create policy "post-media owner insert" on storage.objects for insert to authenticated
  with check ( bucket_id = 'post-media' and (storage.foldername(name))[2] = (select auth.uid())::text );
create policy "post-media owner update" on storage.objects for update to authenticated
  using ( bucket_id = 'post-media' and (storage.foldername(name))[2] = (select auth.uid())::text );
create policy "post-media owner delete" on storage.objects for delete to authenticated
  using ( bucket_id = 'post-media' and (storage.foldername(name))[2] = (select auth.uid())::text );
