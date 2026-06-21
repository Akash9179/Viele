-- ============================================================================
-- 0009_avatars_bucket.sql — public bucket for profile photos.
--
-- Path convention: avatars/{uid}/avatar.jpg  (one avatar per user, upserted).
-- Public bucket → readable via public URL (no SELECT policy needed, same as
-- post-media). Writes are owner-prefixed: a user may only write under their own
-- {uid}/ folder. delete-account removes avatars/{uid}/ on account deletion.
-- ============================================================================
insert into storage.buckets (id, name, public)
  values ('avatars', 'avatars', true)
  on conflict (id) do nothing;

create policy "avatars owner insert" on storage.objects for insert to authenticated
  with check ( bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text );
create policy "avatars owner update" on storage.objects for update to authenticated
  using ( bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text );
create policy "avatars owner delete" on storage.objects for delete to authenticated
  using ( bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text );
