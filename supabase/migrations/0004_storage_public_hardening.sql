-- 0004 — now that post-media is a public bucket (0003), object downloads work
-- via public URLs and don't need a SELECT policy on storage.objects. The broad
-- authenticated read policy only enabled *listing* the whole bucket, so drop it
-- (advisor: public_bucket_allows_listing). Owner insert/update/delete policies
-- remain for uploads.
drop policy if exists "post-media read" on storage.objects;
