-- =====================================================================
-- Real dashboard counts, the مہمان role, and attribution  (APPLIED)
--
-- Applied in the Supabase history as three migrations:
--   add_guest_role
--   guest_readonly_master_gender_and_real_statistics
--   claimed_register_record_keeps_gender
--
-- WHY
--
-- 1. The administrator's "فاضل / فاضلہ" figure counted rows of `profiles`,
--    which is every account — mentors and administrators included — and had
--    nothing to do with the course register. Its "مربی" figure counted rows
--    of `mentor_assignments`, which counts links: a mentor with nobody
--    assigned was simply absent, which is why three mentors showed as two.
--
--    admin_dashboard_statistics() answers both, and keeps apart two
--    questions that no single number can answer:
--      کل   — every eligible record in the course register, account or not.
--      فعال — the register records linked to an account holding the
--             graduate role.
--    It also returns the gap between them (graduate accounts no register
--    record points at) instead of hiding it.
--
-- 2. کل فاضل and کل فاضلہ need the register to say which is which, and it
--    had no such column. `course_participants.gender` is it. Nothing is
--    ever guessed: null means not recorded, and is counted as such.
--
-- 3. A مہمان may read the institution's totals and nothing else. Owning a
--    row used to be enough to write it, and a guest account owns its own
--    profile row, so every self-write policy now also asks for the role
--    that the write belongs to.
--
-- 4. public_statistics() and public_activity_breakdown() are what a guest —
--    or a visitor who is not signed in at all — actually reads. They return
--    counts and category names. No row of any table is exposed, so there is
--    nothing for a guest to be shown by mistake, and drafts are excluded
--    because a draft is a working copy its author has not submitted.
-- =====================================================================

-- ---------------------------------------------------------------------
-- add_guest_role. Alone, because Postgres will not let a new enum value
-- be used in the same transaction that adds it.
-- ---------------------------------------------------------------------

alter type public.app_role add value if not exists 'guest';

-- ---------------------------------------------------------------------
-- 1. A guest may read, never write
-- ---------------------------------------------------------------------

create or replace function private.is_guest()
returns boolean
language sql
stable
security definer
set search_path to ''
as $$
  select private.has_role(auth.uid(), 'guest');
$$;

drop policy if exists "reports insert own" on public.reports;
create policy "reports insert own" on public.reports
  for insert to authenticated
  with check (
    (auth.uid() = graduate_id and private.has_role(auth.uid(), 'graduate'))
    or private.is_admin()
  );

drop policy if exists "reports update own or reviewer" on public.reports;
create policy "reports update own or reviewer" on public.reports
  for update to authenticated
  using (
    (auth.uid() = graduate_id and private.has_role(auth.uid(), 'graduate'))
    or private.is_mentor_of(graduate_id) or private.is_admin()
  )
  with check (
    (auth.uid() = graduate_id and private.has_role(auth.uid(), 'graduate'))
    or private.is_mentor_of(graduate_id) or private.is_admin()
  );

drop policy if exists "reports delete own draft or admin" on public.reports;
create policy "reports delete own draft or admin" on public.reports
  for delete to authenticated
  using (
    (auth.uid() = graduate_id
      and private.has_role(auth.uid(), 'graduate')
      and status = 'draft'::public.work_status)
    or private.is_admin()
  );

drop policy if exists "evidence insert own" on public.evidence;
create policy "evidence insert own" on public.evidence
  for insert to authenticated
  with check (
    (auth.uid() = graduate_id and private.has_role(auth.uid(), 'graduate'))
    or private.is_admin()
  );

drop policy if exists "evidence update own, reviewer or admin" on public.evidence;
create policy "evidence update own, reviewer or admin" on public.evidence
  for update to authenticated
  using (
    (auth.uid() = graduate_id and private.has_role(auth.uid(), 'graduate'))
    or private.is_mentor_of(graduate_id) or private.is_admin()
  )
  with check (
    (auth.uid() = graduate_id and private.has_role(auth.uid(), 'graduate'))
    or private.is_mentor_of(graduate_id) or private.is_admin()
  );

drop policy if exists "evidence delete own or admin" on public.evidence;
create policy "evidence delete own or admin" on public.evidence
  for delete to authenticated
  using (
    (auth.uid() = graduate_id and private.has_role(auth.uid(), 'graduate'))
    or private.is_admin()
  );

drop policy if exists "graduate_activities write own or permitted" on public.graduate_activities;
create policy "graduate_activities write own or permitted" on public.graduate_activities
  for all to authenticated
  using (
    (auth.uid() = graduate_id and private.has_role(auth.uid(), 'graduate'))
    or private.is_mentor_of(graduate_id) or private.is_admin()
  )
  with check (
    (auth.uid() = graduate_id and private.has_role(auth.uid(), 'graduate'))
    or private.is_mentor_of(graduate_id) or private.is_admin()
  );

drop policy if exists "assignments_duty update own status" on public.assignments;
create policy "assignments_duty update own status" on public.assignments
  for update to authenticated
  using (
    (auth.uid() = graduate_id and private.has_role(auth.uid(), 'graduate'))
    or private.is_mentor_of(graduate_id) or private.is_admin()
  )
  with check (
    (auth.uid() = graduate_id and private.has_role(auth.uid(), 'graduate'))
    or private.is_mentor_of(graduate_id) or private.is_admin()
  );

drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own" on public.profiles
  for update to authenticated
  using (auth.uid() = id and not private.is_guest())
  with check (auth.uid() = id and not private.is_guest());

-- This was the one table any signed-in account could write to.
drop policy if exists "institutes insertable by authenticated" on public.institutes;
create policy "institutes insertable by graduates" on public.institutes
  for insert to authenticated
  with check (private.has_role(auth.uid(), 'graduate') or private.is_admin());

-- ---------------------------------------------------------------------
-- 2. The master register records فاضل / فاضلہ
-- ---------------------------------------------------------------------

alter table public.course_participants
  add column if not exists gender public.participant_gender;

comment on column public.course_participants.gender is
  'فاضل or فاضلہ as the organisation recorded it, or as the person chose at signup. Never guessed: null means not recorded.';

update public.course_participants cp
set gender = p.gender
from public.profiles p
where p.id = cp.linked_user_id
  and cp.gender is null
  and p.gender is not null;

-- ---------------------------------------------------------------------
-- 3. Feedback can name the کارگزاری it is about
-- ---------------------------------------------------------------------

alter table public.mentor_feedback
  add column if not exists report_id uuid
  references public.reports (id) on delete set null;

create index if not exists mentor_feedback_report_id_idx
  on public.mentor_feedback (report_id);

-- ---------------------------------------------------------------------
-- 4. Guests are invited the same way mentors and administrators are
-- ---------------------------------------------------------------------

do $$
declare
  c text;
begin
  select conname into c from pg_constraint
  where conrelid = 'public.staff_invites'::regclass
    and contype = 'c'
    and pg_get_constraintdef(oid) ilike '%mentor%admin%';
  if c is not null then
    execute format('alter table public.staff_invites drop constraint %I', c);
  end if;
end
$$;

alter table public.staff_invites
  add constraint staff_invites_role_check
  check (role in ('mentor', 'admin', 'guest'));

-- create_staff_invite is unchanged from 20260922000006 except that it now
-- also accepts 'guest':
--   if p_role is null or p_role not in ('mentor', 'admin', 'guest') then
--     raise exception 'INVITE_ROLE_INVALID';
--   end if;

-- ---------------------------------------------------------------------
-- 5. The administrator's figures, counted where the facts live
-- ---------------------------------------------------------------------

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
  guests                  int,
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
  with master as (
    select
      coalesce(cp.gender, p.gender) as gender,
      (cp.linked_user_id is not null and exists (
         select 1 from public.user_roles r
         where r.user_id = cp.linked_user_id
           and r.role = 'graduate'::public.app_role
       )) as has_account
    from public.course_participants cp
    left join public.profiles p on p.id = cp.linked_user_id
    where cp.eligible
  )
  select
    (select count(*) filter (where m.gender = 'male') from master m)::int,
    (select count(*) filter (where m.gender = 'female') from master m)::int,
    (select count(*) filter (where m.gender is null) from master m)::int,
    (select count(*) from master m)::int,
    (select count(*) filter (where m.has_account and m.gender = 'male') from master m)::int,
    (select count(*) filter (where m.has_account and m.gender = 'female') from master m)::int,
    (select count(*) filter (where m.has_account and m.gender is null) from master m)::int,
    (select count(*) filter (where m.has_account) from master m)::int,
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
    (select count(*) from public.user_roles r
      where r.role = 'guest'::public.app_role)::int,
    (select count(*) from public.mentor_assignments where is_active)::int,
    (select count(*) from public.reports
      where status in ('pending'::public.work_status, 'draft'::public.work_status))::int,
    (select count(*) from public.reports
      where status in ('under_review'::public.work_status, 'submitted'::public.work_status))::int,
    (select count(*) from public.reports
      where status = 'late'::public.work_status)::int;
end;
$$;

revoke execute on function public.admin_dashboard_statistics() from public, anon;
grant execute on function public.admin_dashboard_statistics() to authenticated;

-- ---------------------------------------------------------------------
-- 6. What a guest may see: totals, and nothing about any one person
-- ---------------------------------------------------------------------

create or replace function public.public_statistics()
returns table (
  total_male         int,
  total_female       int,
  total_graduates    int,
  total_reports      int,
  social_activities  int,
  practical_services int,
  completed_projects int
)
language plpgsql
stable
security definer
set search_path to ''
as $$
begin
  return query
  with master as (
    select coalesce(cp.gender, p.gender) as gender
    from public.course_participants cp
    left join public.profiles p on p.id = cp.linked_user_id
    where cp.eligible
  ),
  shared as (
    select r.id, r.status, rc.group_key
    from public.reports r
    left join public.report_categories rc on rc.id = r.category_id
    where r.status <> 'draft'::public.work_status
  )
  select
    (select count(*) filter (where m.gender = 'male') from master m)::int,
    (select count(*) filter (where m.gender = 'female') from master m)::int,
    (select count(*) from master m)::int,
    (select count(*) from shared)::int,
    (select count(*) filter (where s.group_key = 'social') from shared s)::int,
    (select count(*) filter (where s.group_key is not null and s.group_key <> 'social')
       from shared s)::int,
    (select count(*) filter (where s.status = 'completed'::public.work_status)
       from shared s)::int;
end;
$$;

revoke execute on function public.public_statistics() from public;
grant execute on function public.public_statistics() to anon, authenticated;

create or replace function public.public_activity_breakdown()
returns table (
  group_title    text,
  category_title text,
  total          int
)
language plpgsql
stable
security definer
set search_path to ''
as $$
begin
  return query
  select rc.group_title, rc.title,
         (select count(*) from public.reports r
           where r.category_id = rc.id
             and r.status <> 'draft'::public.work_status)::int
  from public.report_categories rc
  where rc.is_active
  order by rc.group_title, rc.sort_order, rc.title;
end;
$$;

revoke execute on function public.public_activity_breakdown() from public;
grant execute on function public.public_activity_breakdown() to anon, authenticated;

-- ---------------------------------------------------------------------
-- 7. claimed_register_record_keeps_gender
--
-- private.handle_new_user() is otherwise unchanged from 20260922000006.
-- When a register record is claimed it now also keeps a جنس: the one the
-- organisation recorded if there is one, otherwise the one the person
-- chose for themselves at signup.
--
--   update public.course_participants
--   set account_created = true,
--       linked_user_id  = new.id,
--       claimed_at      = now(),
--       gender          = coalesce(r.gender, v_gender)
--   where id = r.id;
-- ---------------------------------------------------------------------
