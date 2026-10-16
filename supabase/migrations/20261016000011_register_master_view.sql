-- =====================================================================
-- One expression behind the figure and the list      (NOT YET APPLIED)
--
-- Defect 1.1, properly this time.
--
-- The first fix made the register list filter on course_participants.gender
-- and open from the tapped dashboard figure. That was still wrong, because
-- it is not what the figure counts. admin_dashboard_statistics() counts:
--
--     coalesce(cp.gender, p.gender)      -- the register row, else the
--                                        -- linked profile's own جنس
--     ...
--     where cp.eligible
--
-- So a person whose register row has no جنس still counts, through the
-- فاضل / فاضلہ they chose when they signed up. Measured on the live data:
--
--     course_participants.gender alone :  4 male,  3 female, 386 unrecorded
--     what the figure actually counts  :  9 male, 11 female, 373 unrecorded
--
-- A list filtered the first way would show 4 under a card reading 9. The
-- brief asks for one filter, counted and listed the same way — and writing
-- that coalesce a second time in Dart would only be a second copy, free to
-- drift again, which is how this defect arose in the first place.
--
-- So the expression is defined once, here, as a view. The statistics
-- function counts from it and the register list reads from it. They cannot
-- disagree, because there is nothing left to keep in step.
--
-- A view, rather than an embedded select in the client: course_participants
-- has no foreign key on linked_user_id at all, so PostgREST cannot embed
-- profiles from it. The join has to be written in SQL.
--
-- security_invoker = true matters. Without it a view runs with its owner's
-- rights and would hand the whole register to any signed-in account. With
-- it, the existing SELECT policies on course_participants and profiles
-- still apply to whoever queries the view — an منتظم sees the register,
-- everybody else sees nothing, exactly as before.
--
-- Deliberately left alone: every policy, including the two this view leans
-- on. course_participants and profiles keep their shape; cp.gender is still
-- the register's own column and still what an منتظم edits. No column or
-- table is dropped or renamed, and no auth user, password, role, session or
-- id is written. This file adds one view and rewrites one function body.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. The register, as the dashboard understands it
-- ---------------------------------------------------------------------
create or replace view public.register_master
with (security_invoker = true) as
select
  cp.id,
  cp.registration_number,
  cp.registration_key,
  cp.full_name,
  cp.father_name,
  cp.course_start_date,
  cp.course_completion_date,
  cp.course_period,
  cp.eligible,
  cp.account_created,
  cp.linked_user_id,
  cp.claimed_at,
  cp.notes,
  cp.created_at,
  cp.updated_at,
  cp.gender,

  -- جنس as every figure on the dashboard reckons it: the register's own
  -- column when it has one, otherwise what the person chose for themselves
  -- at signup. Null when nobody has said — 373 of 393 rows today, counted
  -- as «درج نہیں» rather than guessed either way.
  coalesce(cp.gender, p.gender) as effective_gender,

  -- Whether a فاضل account stands behind the row, which is what the فعال
  -- figures count as against the کل figures.
  (cp.linked_user_id is not null and exists (
     select 1 from public.user_roles r
     where r.user_id = cp.linked_user_id
       and r.role = 'graduate'::public.app_role
   )) as has_account

from public.course_participants cp
left join public.profiles p on p.id = cp.linked_user_id
where cp.eligible;

comment on view public.register_master is
  'The eligible course register with جنس resolved the way the dashboard '
  'counts it — the register column, else the linked profile''s own. Read by '
  'admin_dashboard_statistics() and by the register list, so a figure and '
  'the rows behind it are one expression rather than two copies of a rule. '
  'security_invoker, so the existing policies still decide who may see it.';

-- ---------------------------------------------------------------------
-- 2. The figures, counted from that view
-- ---------------------------------------------------------------------
-- Same returned columns, same order, same types as 20261001000008 — only
-- the source changes, from an inline CTE to the shared view. Nothing the
-- Flutter app reads changes shape, so AdminStatistics is untouched.
create or replace function public.admin_dashboard_statistics()
returns table (
  total_male              int,
  total_female            int,
  total_unrecorded_gender int,
  total_graduates         int,
  active_male             int,
  active_female           int,
  active_unrecorded       int,
  active_graduates        int,
  accounts_without_record int,
  mentors                 int,
  admins                  int,
  active_assignments      int,
  pending_reports         int,
  under_review            int,
  late_reports            int
)
language plpgsql
stable
security definer
set search_path to ''
as $$
begin
  if not private.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;

  return query
  select
    (select count(*) filter (where m.effective_gender = 'male')
       from public.register_master m)::int,
    (select count(*) filter (where m.effective_gender = 'female')
       from public.register_master m)::int,
    (select count(*) filter (where m.effective_gender is null)
       from public.register_master m)::int,
    (select count(*) from public.register_master m)::int,
    (select count(*) filter (where m.has_account
                               and m.effective_gender = 'male')
       from public.register_master m)::int,
    (select count(*) filter (where m.has_account
                               and m.effective_gender = 'female')
       from public.register_master m)::int,
    (select count(*) filter (where m.has_account
                               and m.effective_gender is null)
       from public.register_master m)::int,
    (select count(*) filter (where m.has_account)
       from public.register_master m)::int,
    (select count(*) from public.user_roles r
      where r.role = 'graduate'::public.app_role
        and not exists (
          select 1 from public.course_participants cp
          where cp.linked_user_id = r.user_id))::int,
    (select count(*) from public.user_roles r
       left join public.profiles p on p.id = r.user_id
      where r.role = 'mentor'::public.app_role
        and coalesce(p.status, 'active'::public.work_status)
            <> 'inactive'::public.work_status)::int,
    (select count(*) from public.user_roles r
       left join public.profiles p on p.id = r.user_id
      where r.role = 'admin'::public.app_role
        and coalesce(p.status, 'active'::public.work_status)
            <> 'inactive'::public.work_status)::int,
    (select count(*) from public.mentor_assignments where is_active)::int,
    (select count(*) from public.reports
      where status in ('pending'::public.work_status,
                       'draft'::public.work_status))::int,
    (select count(*) from public.reports
      where status in ('under_review'::public.work_status,
                       'submitted'::public.work_status))::int,
    (select count(*) from public.reports
      where status = 'late'::public.work_status)::int;
end;
$$;

-- The function is SECURITY DEFINER and guards itself with is_admin(), as
-- before. Restated because a replace leaves grants as they were, and saying
-- so is cheaper than wondering.
revoke all on function public.admin_dashboard_statistics() from public;
grant execute on function public.admin_dashboard_statistics()
  to authenticated;

-- =====================================================================
-- Verify after applying. None of these writes.
--
--   -- the view and the figures agree, by construction. Both should read
--   -- 9 male / 11 female / 373 unrecorded on today's data.
--   select coalesce(effective_gender::text, 'not recorded') as g, count(*)
--   from public.register_master group by 1 order by 2 desc;
--
--   select total_male, total_female, total_unrecorded_gender, total_graduates
--   from public.admin_dashboard_statistics();
--
--   -- and the list the card opens is those same rows:
--   select count(*) from public.register_master
--   where effective_gender = 'male';          -- expect total_male
--
--   -- the view widened nothing: signed in as a فاضل or مربی this must
--   -- return 0, because the register is an منتظم's table
--   select count(*) from public.register_master;
--
--   -- nothing moved
--   select count(*) from auth.users;
--   select role, count(*) from public.user_roles group by role;
-- =====================================================================
