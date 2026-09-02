-- =====================================================================
-- Migration 3 of 3 — storage buckets, storage RLS, realtime publication
--
-- PROPOSAL ONLY. Not applied.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Buckets
--
-- avatars  : public read. Profile pictures are shown next to names in
--            mentor and admin lists, so a public bucket keeps reads
--            cheap. Writes are still restricted per user.
-- evidence : PRIVATE. Report attachments are the graduate's own work and
--            must never be reachable by URL guessing. Clients read these
--            through signed URLs only.
--
-- Both use a `<user_id>/<filename>` path convention, which is what the
-- policies below key on: the first path segment must equal auth.uid().
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880,
   array['image/png','image/jpeg','image/webp']),
  ('evidence', 'evidence', false, 52428800,
   array['image/png','image/jpeg','image/webp','application/pdf',
         'video/mp4','video/quicktime'])
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- avatars policies
-- ---------------------------------------------------------------------
create policy "avatars are publicly readable"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "users upload own avatar"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "users update own avatar"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "users delete own avatar"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------
-- evidence policies — mirror the table-level rules exactly, so a file
-- is reachable by precisely the people who may read its evidence row.
-- ---------------------------------------------------------------------
create policy "evidence readable by owner mentor or admin"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'evidence'
    and public.can_view_graduate(((storage.foldername(name))[1])::uuid)
  );

create policy "graduates upload own evidence"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'evidence'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "graduates update own evidence"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'evidence'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "graduates or admin delete evidence"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'evidence'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
  );

-- ---------------------------------------------------------------------
-- Realtime
--
-- Only the tables whose changes must reach an open screen without a
-- refresh. Reference tables are deliberately excluded — they change
-- rarely and would just add socket traffic.
--
-- REPLICA IDENTITY FULL is required for UPDATE and DELETE events to
-- carry the old row, which the client needs to reconcile its cache.
-- RLS still applies to realtime, so a subscriber only receives rows
-- they are allowed to read.
-- ---------------------------------------------------------------------
alter table public.reports             replica identity full;
alter table public.evidence            replica identity full;
alter table public.evaluations         replica identity full;
alter table public.assignments         replica identity full;
alter table public.recognitions        replica identity full;
alter table public.notifications       replica identity full;
alter table public.graduate_activities replica identity full;
alter table public.mentor_feedback     replica identity full;
alter table public.follow_ups          replica identity full;

alter publication supabase_realtime add table public.reports;
alter publication supabase_realtime add table public.evidence;
alter publication supabase_realtime add table public.evaluations;
alter publication supabase_realtime add table public.assignments;
alter publication supabase_realtime add table public.recognitions;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.graduate_activities;
alter publication supabase_realtime add table public.mentor_feedback;
alter publication supabase_realtime add table public.follow_ups;
