-- ============================================================================
-- 0010_storage_upsert_with_check.sql — harden storage UPDATE policies.
--
-- Adds an explicit WITH CHECK (mirroring USING) to the owner-update policies for
-- post-media and avatars. Defense-in-depth: a future upsert/overwrite path is
-- gated on the owner prefix for the NEW row too, not just the existing one.
--
-- NOTE: the real upload-403 fix lives in app code. Storage `upsert: true` issues
-- INSERT ... ON CONFLICT DO UPDATE, which fails under owner-prefixed RLS
-- regardless of WITH CHECK (verified: upsert=false → 200, upsert=true → 403/400
-- even via raw HTTP). The app therefore uploads with upsert:false (post paths
-- are unique; avatars delete-then-insert). See post_repository / profile_repository.
-- ============================================================================
drop policy if exists "post-media owner update" on storage.objects;
create policy "post-media owner update" on storage.objects for update to authenticated
  using ( bucket_id = 'post-media'
    and (storage.foldername(name))[2] = (select auth.uid())::text )
  with check ( bucket_id = 'post-media'
    and (storage.foldername(name))[2] = (select auth.uid())::text );

drop policy if exists "avatars owner update" on storage.objects;
create policy "avatars owner update" on storage.objects for update to authenticated
  using ( bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text )
  with check ( bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text );
