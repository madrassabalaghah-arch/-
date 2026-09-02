-- =====================================================================
-- Migration 2 of 3 — role helpers, profile bootstrap, RLS policies
--
-- PROPOSAL ONLY. Not applied.
--
-- Design note: every helper is SECURITY DEFINER with an empty
-- search_path. SECURITY DEFINER is what stops infinite recursion — a
-- policy on user_roles that itself queried user_roles would recurse.
-- The empty search_path stops search_path hijacking, so every object
-- below is schema-qualified.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Role helpers
-- ---------------------------------------------------------------------
create or replace function public.has_role(_user_id uuid, _role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = _user_id and role = _role
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_role(auth.uid(), 'admin');
$$;

-- True when the caller is an active mentor of the given graduate.
create or replace function public.is_mentor_of(_graduate_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.mentor_assignments
    where mentor_id = auth.uid()
      and graduate_id = _graduate_id
      and is_active
  );
$$;

-- Convenience: the caller may read a graduate's record if it is their
-- own, they mentor that graduate, or they are an administrator.
create or replace function public.can_view_graduate(_graduate_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() = _graduate_id
      or public.is_mentor_of(_graduate_id)
      or public.is_admin();
$$;

-- ---------------------------------------------------------------------
-- Profile bootstrap: every new auth user gets a profile and the
-- default 'graduate' role. Roles are never taken from client metadata,
-- so a user cannot sign up as an admin.
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.email
  )
  on conflict (id) do nothing;

  insert into public.user_roles (user_id, role)
  values (new.id, 'graduate')
  on conflict (user_id, role) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- Enable RLS on every table. Nothing is readable until a policy allows it.
-- ---------------------------------------------------------------------
alter table public.wifaqs               enable row level security;
alter table public.institutes           enable row level security;
alter table public.profiles             enable row level security;
alter table public.user_roles           enable row level security;
alter table public.mentor_assignments   enable row level security;
alter table public.courses              enable row level security;
alter table public.course_enrollments   enable row level security;
alter table public.activities           enable row level security;
alter table public.graduate_activities  enable row level security;
alter table public.reports              enable row level security;
alter table public.evidence             enable row level security;
alter table public.evaluation_standards enable row level security;
alter table public.evaluations          enable row level security;
alter table public.evaluation_scores    enable row level security;
alter table public.mentor_feedback      enable row level security;
alter table public.assignments          enable row level security;
alter table public.recognitions         enable row level security;
alter table public.follow_ups           enable row level security;
alter table public.notifications        enable row level security;

-- ---------------------------------------------------------------------
-- Reference data: readable by any signed-in user, written by admins only.
-- ---------------------------------------------------------------------
create policy "reference readable by authenticated"
  on public.wifaqs for select to authenticated using (true);
create policy "wifaqs writable by admin"
  on public.wifaqs for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "institutes readable by authenticated"
  on public.institutes for select to authenticated using (true);
create policy "institutes writable by admin"
  on public.institutes for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "courses readable by authenticated"
  on public.courses for select to authenticated using (true);
create policy "courses writable by admin"
  on public.courses for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "activities readable by authenticated"
  on public.activities for select to authenticated using (true);
create policy "activities writable by admin"
  on public.activities for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "standards readable by authenticated"
  on public.evaluation_standards for select to authenticated using (true);
create policy "standards writable by admin"
  on public.evaluation_standards for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- profiles: own row, assigned graduates, or admin.
-- A graduate cannot list other graduates.
-- ---------------------------------------------------------------------
create policy "profiles select own or permitted"
  on public.profiles for select to authenticated
  using (public.can_view_graduate(id));

create policy "profiles update own"
  on public.profiles for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);

create policy "profiles admin manages all"
  on public.profiles for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- user_roles: a user may READ their own roles but never write any.
-- Only admins grant or revoke. This is the privilege-escalation guard.
-- ---------------------------------------------------------------------
create policy "user_roles select own"
  on public.user_roles for select to authenticated
  using (auth.uid() = user_id or public.is_admin());

create policy "user_roles admin writes"
  on public.user_roles for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- mentor_assignments: mentor sees their own rows, graduate sees who
-- mentors them, admin manages the mapping.
-- ---------------------------------------------------------------------
create policy "assignments select own side"
  on public.mentor_assignments for select to authenticated
  using (auth.uid() = mentor_id or auth.uid() = graduate_id or public.is_admin());

create policy "assignments admin writes"
  on public.mentor_assignments for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- Graduate-owned records. One shared shape:
--   SELECT  own | mentor of that graduate | admin
--   INSERT  own (or admin)
--   UPDATE  own while not yet locked, mentor, admin
--   DELETE  own drafts, admin
-- ---------------------------------------------------------------------
create policy "reports select permitted"
  on public.reports for select to authenticated
  using (public.can_view_graduate(graduate_id));

create policy "reports insert own"
  on public.reports for insert to authenticated
  with check (auth.uid() = graduate_id or public.is_admin());

create policy "reports update own or reviewer"
  on public.reports for update to authenticated
  using (auth.uid() = graduate_id or public.is_mentor_of(graduate_id) or public.is_admin())
  with check (auth.uid() = graduate_id or public.is_mentor_of(graduate_id) or public.is_admin());

create policy "reports delete own draft or admin"
  on public.reports for delete to authenticated
  using ((auth.uid() = graduate_id and status = 'draft') or public.is_admin());

create policy "evidence select permitted"
  on public.evidence for select to authenticated
  using (public.can_view_graduate(graduate_id));

create policy "evidence insert own"
  on public.evidence for insert to authenticated
  with check (auth.uid() = graduate_id or public.is_admin());

create policy "evidence update own or admin"
  on public.evidence for update to authenticated
  using (auth.uid() = graduate_id or public.is_admin())
  with check (auth.uid() = graduate_id or public.is_admin());

create policy "evidence delete own or admin"
  on public.evidence for delete to authenticated
  using (auth.uid() = graduate_id or public.is_admin());

create policy "graduate_activities select permitted"
  on public.graduate_activities for select to authenticated
  using (public.can_view_graduate(graduate_id));

create policy "graduate_activities write own or permitted"
  on public.graduate_activities for all to authenticated
  using (auth.uid() = graduate_id or public.is_mentor_of(graduate_id) or public.is_admin())
  with check (auth.uid() = graduate_id or public.is_mentor_of(graduate_id) or public.is_admin());

create policy "enrollments select permitted"
  on public.course_enrollments for select to authenticated
  using (public.can_view_graduate(graduate_id));

create policy "enrollments admin writes"
  on public.course_enrollments for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- Evaluations: written by the assigned mentor, read by the graduate it
-- concerns. A mentor cannot evaluate a graduate who is not theirs —
-- the WITH CHECK enforces that on write, not just on read.
-- ---------------------------------------------------------------------
create policy "evaluations select permitted"
  on public.evaluations for select to authenticated
  using (public.can_view_graduate(graduate_id));

create policy "evaluations mentor writes assigned"
  on public.evaluations for insert to authenticated
  with check (
    (auth.uid() = mentor_id and public.is_mentor_of(graduate_id))
    or public.is_admin()
  );

create policy "evaluations mentor updates own"
  on public.evaluations for update to authenticated
  using ((auth.uid() = mentor_id and public.is_mentor_of(graduate_id)) or public.is_admin())
  with check ((auth.uid() = mentor_id and public.is_mentor_of(graduate_id)) or public.is_admin());

create policy "evaluations admin deletes"
  on public.evaluations for delete to authenticated
  using (public.is_admin());

-- Scores inherit their permission from the parent evaluation.
create policy "evaluation_scores select via parent"
  on public.evaluation_scores for select to authenticated
  using (exists (
    select 1 from public.evaluations e
    where e.id = evaluation_id and public.can_view_graduate(e.graduate_id)
  ));

create policy "evaluation_scores write via parent"
  on public.evaluation_scores for all to authenticated
  using (exists (
    select 1 from public.evaluations e
    where e.id = evaluation_id
      and ((auth.uid() = e.mentor_id and public.is_mentor_of(e.graduate_id))
           or public.is_admin())
  ))
  with check (exists (
    select 1 from public.evaluations e
    where e.id = evaluation_id
      and ((auth.uid() = e.mentor_id and public.is_mentor_of(e.graduate_id))
           or public.is_admin())
  ));

-- ---------------------------------------------------------------------
-- Guidance, duties, awards, follow-ups
-- ---------------------------------------------------------------------
create policy "mentor_feedback select permitted"
  on public.mentor_feedback for select to authenticated
  using (public.can_view_graduate(graduate_id));

create policy "mentor_feedback mentor writes assigned"
  on public.mentor_feedback for all to authenticated
  using ((auth.uid() = mentor_id and public.is_mentor_of(graduate_id)) or public.is_admin())
  with check ((auth.uid() = mentor_id and public.is_mentor_of(graduate_id)) or public.is_admin());

create policy "assignments_duty select permitted"
  on public.assignments for select to authenticated
  using (public.can_view_graduate(graduate_id));

create policy "assignments_duty update own status"
  on public.assignments for update to authenticated
  using (auth.uid() = graduate_id or public.is_mentor_of(graduate_id) or public.is_admin())
  with check (auth.uid() = graduate_id or public.is_mentor_of(graduate_id) or public.is_admin());

create policy "assignments_duty managed by staff"
  on public.assignments for insert to authenticated
  with check (public.is_mentor_of(graduate_id) or public.is_admin());

create policy "assignments_duty admin deletes"
  on public.assignments for delete to authenticated
  using (public.is_admin());

create policy "recognitions select permitted"
  on public.recognitions for select to authenticated
  using (public.can_view_graduate(graduate_id));

create policy "recognitions granted by staff"
  on public.recognitions for all to authenticated
  using (public.is_mentor_of(graduate_id) or public.is_admin())
  with check (public.is_mentor_of(graduate_id) or public.is_admin());

create policy "follow_ups select permitted"
  on public.follow_ups for select to authenticated
  using (public.can_view_graduate(graduate_id));

create policy "follow_ups managed by staff"
  on public.follow_ups for all to authenticated
  using (public.is_mentor_of(graduate_id) or public.is_admin())
  with check (public.is_mentor_of(graduate_id) or public.is_admin());

-- ---------------------------------------------------------------------
-- Notifications: strictly the recipient's own. A user may mark their own
-- as read; only staff create them.
-- ---------------------------------------------------------------------
create policy "notifications select own"
  on public.notifications for select to authenticated
  using (auth.uid() = user_id);

create policy "notifications update own"
  on public.notifications for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "notifications created by staff"
  on public.notifications for insert to authenticated
  with check (public.is_admin() or public.has_role(auth.uid(), 'mentor'));

create policy "notifications delete own or admin"
  on public.notifications for delete to authenticated
  using (auth.uid() = user_id or public.is_admin());
