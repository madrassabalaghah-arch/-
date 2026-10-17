-- =====================================================================
-- Phase 3, step 1 of 3: the four tiers and the approval states (APPLIED)
--
-- Separate from the columns and policies that use them, because a value
-- added to an enum cannot be used until the transaction that added it has
-- committed.
--
-- recognition_tier already existed with milestone / award / appreciation,
-- none of which is one of the four tiers the brief names. The four are
-- added rather than the old three replaced, because a value cannot be
-- removed from an enum in use; step 2 adds a CHECK so only these four can
-- be stored, and moves the column default onto the first of them.
--
-- The order is the order the brief gives, and it is an order of standing
-- only. Nothing counts, compares or ranks on it: any tier may be proposed
-- at any time without passing through the ones below it.
--
-- Leaves alone: every existing enum value, every table, every policy, and
-- all data. recognitions and recognition_rules were both empty.
-- =====================================================================

alter type public.recognition_tier add value if not exists 'worthy_progress';
alter type public.recognition_tier add value if not exists 'notable_performance';
alter type public.recognition_tier add value if not exists 'distinguished_service';
alter type public.recognition_tier add value if not exists 'exemplary_impact';

-- Where a recommendation stands. A فاضل may see only 'approved'.
do $$
begin
  if not exists (
    select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'recognition_status'
  ) then
    create type public.recognition_status
      as enum ('pending', 'approved', 'rejected');
  end if;
end
$$;
