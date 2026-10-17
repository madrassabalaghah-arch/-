-- =====================================================================
-- Staff invitations and single-step role changes  (APPLIED)
--
-- Applied in the Supabase history as: staff_invites_and_role_changes,
-- staff_invites_not_readable_by_anon
--
-- 1. public.staff_invites
--    How a مربی or منتظم who is not on the course register gets an
--    account. An administrator records the person's name, email and role,
--    and the database issues a single-use code. The person signs up with
--    that email and that code; the signup trigger checks both and grants
--    the role.
--
--    The code is what makes this safe. An email address is not a secret:
--    with the address alone, whoever signed up first with it would take the
--    role before the real person had proved anything. The code travels
--    separately, from the administrator to the person.
--
--    RLS: administrators read. Nobody writes directly; creating and
--    cancelling go through the admin-only functions below, which can also
--    check auth.users for an account that already exists.
--
-- 2. public.verify_staff_invite(text, text)
--    Pre-signup check, callable as anon for the same reason as
--    verify_course_registration: the caller has no account yet. It answers
--    only about the email and code supplied, and returns the name and role
--    only when both match an open invitation.
--
-- 3. private.handle_new_user()
--    Gains the invitation path. With an invite_code in the signup metadata,
--    the email and code must match an open invitation or the signup is
--    refused, and the role and name come from the invitation, never from
--    the client. Without one, the bootstrap and course register paths are
--    unchanged.
--
-- 4. public.set_user_role(uuid, app_role)
--    Replaces a user's role in one transaction. The app used to delete the
--    old role and insert the new one as two requests, so a dropped
--    connection between them left the account with no role and nowhere in
--    the app to fix it from.
--
-- 5. private.end_assignments_with_role()
--    Access follows the role. private.is_mentor_of() looks only at
--    mentor_assignments, so a former mentor's active assignments would keep
--    their access to those graduates' records. Whenever a mentor or
--    graduate role is removed — by set_user_role, or by a direct write from
--    an older build — the assignments that depended on it are ended.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Invitations
-- ---------------------------------------------------------------------

create or replace function private.new_invite_code()
returns text
language plpgsql
volatile
set search_path to ''
as $$
declare
  -- No I, O, 0 or 1, which are misread when a code is passed on by hand.
  -- 32 characters, so every random byte maps onto one without bias.
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  bytes bytea := extensions.gen_random_bytes(8);
  code text := '';
begin
  for i in 0..7 loop
    code := code || substr(alphabet, (get_byte(bytes, i) % 32) + 1, 1);
  end loop;
  return code;
end;
$$;

revoke all on function private.new_invite_code() from public;

create table public.staff_invites (
  id              uuid primary key default gen_random_uuid(),
  full_name       text not null check (btrim(full_name) <> ''),
  email           text not null,
  email_key       text generated always as (lower(btrim(email))) stored,
  role            public.app_role not null check (role in ('mentor', 'admin')),
  code            text not null check (code ~ '^[A-Z0-9]{8}$'),
  invited_by      uuid references auth.users (id) on delete set null,
  created_at      timestamptz not null default now(),
  claimed_at      timestamptz,
  claimed_user_id uuid references auth.users (id) on delete set null
);

comment on table public.staff_invites is
  'Invitations for mentors and administrators who are not on the course register. Written only through create_staff_invite, cancel_staff_invite and the signup trigger.';

-- One open invitation per address. Claimed ones stay, as the record of who
-- joined through which invitation.
create unique index staff_invites_one_open_per_email
  on public.staff_invites (email_key)
  where claimed_at is null;

alter table public.staff_invites enable row level security;

revoke insert, update, delete on public.staff_invites from anon, authenticated;

-- Row level security already returns nothing to anon; without the grant the
-- table is not reachable before sign-in at all.
revoke select on public.staff_invites from anon;

create policy "staff_invites admin reads"
  on public.staff_invites
  for select
  to authenticated
  using (private.is_admin());

create or replace function public.create_staff_invite(
  p_full_name text,
  p_email     text,
  p_role      public.app_role
)
returns public.staff_invites
language plpgsql
volatile
security definer
set search_path to ''
as $$
declare
  v_name  text := btrim(regexp_replace(coalesce(p_full_name, ''), '\s+', ' ', 'g'));
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_row   public.staff_invites;
begin
  if not private.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;
  if p_role is null or p_role not in ('mentor', 'admin') then
    raise exception 'INVITE_ROLE_INVALID';
  end if;
  if v_name = '' then
    raise exception 'INVITE_NAME_REQUIRED';
  end if;
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'INVITE_EMAIL_INVALID';
  end if;
  -- Someone who already has an account needs a role change, not an
  -- invitation they could never use.
  if exists (select 1 from auth.users u where lower(u.email) = v_email) then
    raise exception 'INVITE_EMAIL_REGISTERED';
  end if;
  if exists (
    select 1 from public.staff_invites i
    where i.email_key = v_email and i.claimed_at is null
  ) then
    raise exception 'INVITE_ALREADY_OPEN';
  end if;

  insert into public.staff_invites (full_name, email, role, code, invited_by)
  values (v_name, v_email, p_role, private.new_invite_code(), auth.uid())
  returning * into v_row;

  return v_row;
end;
$$;

revoke execute on function public.create_staff_invite(text, text, public.app_role)
  from public, anon;
grant execute on function public.create_staff_invite(text, text, public.app_role)
  to authenticated;

create or replace function public.cancel_staff_invite(p_invite_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path to ''
as $$
begin
  if not private.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;
  -- A claimed invitation is the record of how an account was created, so
  -- only an open one can be withdrawn.
  delete from public.staff_invites
  where id = p_invite_id and claimed_at is null;
end;
$$;

revoke execute on function public.cancel_staff_invite(uuid) from public, anon;
grant execute on function public.cancel_staff_invite(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 2. Pre-signup check
-- ---------------------------------------------------------------------

create or replace function public.verify_staff_invite(p_email text, p_code text)
returns table (
  valid       boolean,
  reason      text,
  invite_name text,
  invite_role public.app_role
)
language plpgsql
stable
security definer
set search_path to ''
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_code  text := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  i       public.staff_invites;
begin
  if v_email = '' or v_code = '' then
    return query select false, 'required', null::text, null::public.app_role;
    return;
  end if;

  select * into i from public.staff_invites s
  where s.email_key = v_email and s.code = v_code
  order by (s.claimed_at is null) desc, s.created_at desc
  limit 1;

  if not found then
    return query select false, 'not_found', null::text, null::public.app_role;
  elsif i.claimed_at is not null then
    return query select false, 'already_used', null::text, null::public.app_role;
  elsif exists (select 1 from auth.users u where lower(u.email) = v_email) then
    return query select false, 'email_registered', null::text, null::public.app_role;
  else
    -- Returned only once the email and the code have both matched, so it
    -- confirms an invitation the person has already shown is theirs.
    return query select true, 'ok', i.full_name, i.role;
  end if;
end;
$$;

revoke execute on function public.verify_staff_invite(text, text) from public;
grant execute on function public.verify_staff_invite(text, text) to anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. Signup trigger
-- ---------------------------------------------------------------------

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  assigned_role   public.app_role;
  is_bootstrap    boolean;
  v_key           text;
  v_invite_code   text;
  r               public.course_participants;
  inv             public.staff_invites;
  v_full_name     text;
  v_gender        public.participant_gender;
  v_wifaq_id      uuid;
  v_institute_id  uuid;
  v_institute     text;
begin
  select exists (
    select 1 from private.bootstrap_admins
    where lower(email) = lower(new.email)
  ) into is_bootstrap;

  v_full_name := coalesce(new.raw_user_meta_data ->> 'full_name', '');
  v_invite_code := upper(regexp_replace(
    coalesce(new.raw_user_meta_data ->> 'invite_code', ''),
    '[^A-Za-z0-9]', '', 'g'));

  if v_invite_code <> '' then
    -- A مربی or منتظم joining by invitation. The email and the code must
    -- both match an open invitation. The role and the name are the ones the
    -- administrator recorded, never anything the client sent.
    select * into inv from public.staff_invites s
    where s.email_key = lower(btrim(new.email))
      and s.code = v_invite_code
      and s.claimed_at is null
    for update;

    if not found then
      raise exception 'INVITE_INVALID';
    end if;

    assigned_role := inv.role;
    v_full_name := inv.full_name;
  elsif is_bootstrap then
    assigned_role := 'admin'::public.app_role;
  else
    v_key := upper(regexp_replace(
      coalesce(new.raw_user_meta_data ->> 'registration_number', ''),
      '[^A-Za-z0-9]', '', 'g'));

    if v_key = '' then
      raise exception 'REGISTRATION_REQUIRED';
    end if;

    select * into r from public.course_participants
    where registration_key = v_key
    for update;

    if not found then
      raise exception 'REGISTRATION_INVALID';
    elsif not r.eligible then
      raise exception 'REGISTRATION_NOT_ELIGIBLE';
    elsif r.account_created then
      raise exception 'REGISTRATION_USED';
    elsif private.name_key(v_full_name) <> r.name_key then
      raise exception 'REGISTRATION_NAME_MISMATCH';
    elsif not private.period_matches(
            coalesce(new.raw_user_meta_data ->> 'course_period', ''), r) then
      raise exception 'REGISTRATION_PERIOD_MISMATCH';
    end if;

    v_full_name := r.full_name;

    v_gender := nullif(new.raw_user_meta_data ->> 'gender', '')
                  ::public.participant_gender;
    v_wifaq_id := nullif(new.raw_user_meta_data ->> 'wifaq_id', '')::uuid;
    v_institute := nullif(btrim(regexp_replace(
      coalesce(new.raw_user_meta_data ->> 'institute_name', ''),
      '\s+', ' ', 'g')), '');

    if v_institute is not null then
      insert into public.institutes (name, wifaq_id)
      values (v_institute, v_wifaq_id)
      on conflict (wifaq_id, name_key) do update
        set name = public.institutes.name
      returning id into v_institute_id;
    end if;

    assigned_role := 'graduate'::public.app_role;
  end if;

  insert into public.profiles (
    id, full_name, email, gender, wifaq_id, institute_id
  )
  values (
    new.id, v_full_name, new.email, v_gender, v_wifaq_id, v_institute_id
  )
  on conflict (id) do nothing;

  insert into public.user_roles (user_id, role)
  values (new.id, assigned_role)
  on conflict (user_id, role) do nothing;

  if r.id is not null then
    update public.course_participants
    set account_created = true,
        linked_user_id  = new.id,
        claimed_at      = now()
    where id = r.id;
  end if;

  if inv.id is not null then
    update public.staff_invites
    set claimed_at      = now(),
        claimed_user_id = new.id
    where id = inv.id;
  end if;

  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 4. Single-step role change
-- ---------------------------------------------------------------------

create or replace function public.set_user_role(
  p_user_id uuid,
  p_role    public.app_role
)
returns void
language plpgsql
volatile
security definer
set search_path to ''
as $$
begin
  if not private.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;
  if p_user_id is null or p_role is null then
    raise exception 'ROLE_REQUIRED';
  end if;
  -- The app hides this too. Enforcing it here means an administrator can
  -- never remove their own access by mistake.
  if p_user_id = auth.uid() then
    raise exception 'CANNOT_CHANGE_OWN_ROLE';
  end if;
  if not exists (select 1 from auth.users u where u.id = p_user_id) then
    raise exception 'USER_NOT_FOUND';
  end if;

  -- Two administrators changing the same account at once take turns, so the
  -- account cannot end up holding both of the roles they chose.
  perform pg_advisory_xact_lock(hashtextextended('user_role:' || p_user_id::text, 0));

  delete from public.user_roles
  where user_id = p_user_id and role <> p_role;

  insert into public.user_roles (user_id, role)
  values (p_user_id, p_role)
  on conflict (user_id, role) do nothing;
end;
$$;

revoke execute on function public.set_user_role(uuid, public.app_role) from public, anon;
grant execute on function public.set_user_role(uuid, public.app_role) to authenticated;

-- ---------------------------------------------------------------------
-- 5. Access follows the role
-- ---------------------------------------------------------------------

create or replace function private.end_assignments_with_role()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
begin
  if old.role = 'mentor'::public.app_role and not exists (
    select 1 from public.user_roles
    where user_id = old.user_id and role = 'mentor'::public.app_role
  ) then
    update public.mentor_assignments
    set is_active = false
    where mentor_id = old.user_id and is_active;
  elsif old.role = 'graduate'::public.app_role and not exists (
    select 1 from public.user_roles
    where user_id = old.user_id and role = 'graduate'::public.app_role
  ) then
    update public.mentor_assignments
    set is_active = false
    where graduate_id = old.user_id and is_active;
  end if;
  return old;
end;
$$;

create trigger end_assignments_with_role
  after delete on public.user_roles
  for each row execute function private.end_assignments_with_role();
