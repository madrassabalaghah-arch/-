-- =====================================================================
-- Close anon EXECUTE on the two Phase 1 functions          (APPLIED)
--
-- A mistake in 20261015000010, found by Supabase's security advisor after
-- applying it and confirmed with has_function_privilege().
--
-- That file ended each function with:
--
--     revoke all on function ... from public;
--     grant execute on function ... to authenticated;
--
-- which is not enough. `revoke ... from public` removes the PUBLIC grant,
-- but this project's default privileges grant EXECUTE on new functions in
-- schema public to anon as well, and that direct grant survives. So both
-- functions were reachable at /rest/v1/rpc/... without signing in:
--
--     community_comments_for    anon_can = true
--     find_or_create_institute  anon_can = true
--
-- community_comments_for is the one that mattered. It carries no role guard
-- — by design, because every signed-in role may read the board — so an
-- anonymous caller holding the publishable key could read every عوامی تبصرہ
-- and its author's name. That key is compiled into the app and the
-- repository is public, so it is reachable by anyone. The board is public to
-- members, never to the open internet.
--
-- find_or_create_institute already refused anon of its own accord: auth.uid()
-- is null for an anonymous caller, so has_role() is false and it raises
-- ROLE_REQUIRED. Revoking removes needless surface rather than closing a
-- hole.
--
-- Verified after applying, with has_function_privilege():
--
--     community_comments_for     anon false   authenticated true
--     find_or_create_institute   anon false   authenticated true
--     community_feed             anon false   authenticated true
--
-- so the two now match community_feed, which was already correct.
--
-- Deliberately left anon-callable: verify_course_registration and
-- verify_staff_invite. Both are called before an account exists — one checks
-- a رقم التسجیل, the other an invitation code — and both answer only about
-- the single value they were given.
--
-- Deliberately left alone: every policy, every function body, every grant to
-- authenticated, and all data. This file changes two grants and nothing else.
-- =====================================================================

revoke execute on function public.community_comments_for(uuid, uuid)
  from anon;

revoke execute on function public.find_or_create_institute(uuid, text, text)
  from anon;
