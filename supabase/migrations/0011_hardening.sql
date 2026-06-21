-- ============================================================================
-- 0011_hardening.sql — pre-public-test hardening (QA follow-ups).
--
-- 1. Bound uploads: cap object size and restrict to image mime types on both
--    public buckets. Without this, any authenticated user can upload arbitrary
--    files of any size to a public bucket.
-- 2. Tighten the admin moderation RPCs: they are internally is_admin()-guarded,
--    but there's no reason for the anon role to hold EXECUTE — revoke it (keep
--    authenticated, since admins are authenticated users).
-- ============================================================================

-- 1 ── Upload limits (10 MB, images only) -------------------------------------
update storage.buckets
  set file_size_limit = 10485760,
      allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
  where id in ('post-media', 'avatars');

-- 2 ── Admin moderation RPCs: drop anon EXECUTE --------------------------------
revoke execute on function public.moderation_queue() from anon;
revoke execute on function public.moderate_post(uuid, text, text) from anon;
