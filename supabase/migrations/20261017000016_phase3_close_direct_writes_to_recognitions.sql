-- =====================================================================
-- Phase 3, step 3 of 3: writes go only through the functions   (APPLIED)
--
-- A hole found by probing the flow step 2 had just added, not by reading
-- it. recognitions carried a pre-existing policy, "recognitions granted by
-- staff", for ALL commands:
--
--     using / with check (private.is_mentor_of(graduate_id)
--                         or private.is_admin())
--
-- so a مربی could INSERT straight into the table, skipping
-- recommend_recognition() altogether — no reason required, and, worst, free
-- to set status = 'approved' and award an اعزاز to their own فاضل with no
-- منتظم deciding. The probe that caught it: a مربی's direct insert returned
-- SUCCESS where it had to be refused.
--
-- Step 2 had dropped "recognitions no direct insert" and "recognitions no
-- direct update" — names that never existed — so the real policy survived.
-- Dropping a policy by a guessed name is worth nothing. This drops it by
-- the name it actually has.
--
-- Writes now go only through the two SECURITY DEFINER functions, which hold
-- the role, assignment, reason and self-approval checks. Both bypass RLS by
-- design, so removing the table-level write path does not disturb them.
--
-- Safe to remove: every use of recognitions in the Flutter app is a read —
-- admin_repository.recognitions(), graduate_repository.recognitions() and
-- its watch stream all call .select() or .stream(). Nothing in a client
-- inserts or updates the table.
--
-- Verified after applying, each inside a rolled-back transaction:
--
--   mentor inserts directly              -> refused by row-level security
--   mentor inserts status='approved'     -> refused by row-level security
--   mentor calls recommend_recognition   -> SUCCESS
--   admin calls decide_recognition       -> SUCCESS, one 'recognition'
--                                           notification to the فاضل
--   admin decides the same row again     -> ALREADY_DECIDED
--   فاضل with a pending, a rejected and an approved row about them
--                                        -> sees 1 row, the approved one
--
-- Leaves alone: the SELECT and DELETE policies, every column, every other
-- table, and all data.
-- =====================================================================

drop policy if exists "recognitions granted by staff" on public.recognitions;

-- Stated rather than implied: with RLS enabled and no INSERT or UPDATE
-- policy, both are denied to every client role. The functions are the only
-- way in.
comment on table public.recognitions is
  'اعزازات. Written only through recommend_recognition() and '
  'decide_recognition(); the table has no INSERT or UPDATE policy, so a '
  'client cannot write one directly and no مربی can approve their own '
  'recommendation. A فاضل may read only approved rows.';
