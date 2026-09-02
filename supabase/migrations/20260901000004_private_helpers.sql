-- =====================================================================
-- Migration 4 of 4 — move SECURITY DEFINER helpers out of the exposed API
--
-- APPLIED. Reason: Supabase's security linter flagged all five helpers as
-- callable through /rest/v1/rpc by the anon role. The material risk was
-- has_role(): the avatars bucket is public and its object paths contain
-- user UUIDs, so anyone holding the publishable key could have harvested a
-- UUID and then probed whether that user is an admin.
--
-- PostgREST only exposes `public` and `graphql_public`. Functions in
-- `private` remain callable inside RLS policies but are unreachable over
-- the REST API. All 49 policies were recreated against private.*, the two
-- storage policies were repointed, the signup trigger now calls
-- private.handle_new_user(), and the public copies were dropped.
--
-- Result: security advisor reports zero findings.
--
-- The applied statements are reproduced in migrations 20260901000004 and
-- 20260901000005 in the Supabase migration history. This file records the
-- change and its rationale alongside the schema it amends.
-- =====================================================================

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated, service_role;

-- private.has_role / is_admin / is_mentor_of / can_view_graduate /
-- handle_new_user are defined identically to their previous public
-- versions in migrations 2 and 3, with every internal reference
-- schema-qualified and search_path pinned to ''.

-- Every policy created in 20260901000002_rls.sql was dropped and recreated
-- with public.<helper>() replaced by private.<helper>(). Policy names,
-- USING and WITH CHECK semantics are unchanged, so the access matrix in the
-- design review still holds exactly.

-- Finally:
--   drop function public.can_view_graduate(uuid);
--   drop function public.is_mentor_of(uuid);
--   drop function public.is_admin();
--   drop function public.has_role(uuid, public.app_role);
--   drop function public.handle_new_user();
