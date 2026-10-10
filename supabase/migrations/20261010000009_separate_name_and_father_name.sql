-- =====================================================================
-- نام and ولدیت, told apart                                    (APPLIED)
--
-- The problem, as reported: a فاضل or فاضلہ could not create an account
-- when they entered their name together with their father's name, but
-- could when they entered their own name alone.
--
-- The cause. Creating an account compares the name typed against the
-- register for exact equality, in two places — private.handle_new_user()
-- and public.verify_course_registration():
--
--     private.name_key(v_full_name) <> r.name_key
--
-- The sign-up form asked for «نام مع ولدیت» in ONE field, and
-- course_participants holds ONE full_name column. Whichever shape the
-- register happens to hold, anybody who types the other shape is refused.
-- Of 393 register rows, 32 hold a one-word name, 256 two words, 86 three:
-- the organisation's own file is not consistent, and so no single shape can
-- be demanded of the person signing up.
--
-- What this does.
--
-- 1. father_name on the register, so a record entered from now on keeps the
--    two apart. Nullable, no default, NOT backfilled — splitting an existing
--    combined name would mean guessing where the name ends, and a wrong guess
--    is worse than an empty field. name_key is a stored generated column over
--    full_name alone, so adding this column does not disturb it.
--
-- 2. private.name_matches() decides what counts as a match, and both the
--    trigger and the RPC call it, so the courtesy check and the enforcement
--    cannot disagree.
--
--    Every branch is an exact equality. There is deliberately no prefix or
--    wildcard match: with 256 rows holding two-word names, accepting «محمد »
--    as a prefix would let anyone holding someone else's رقم التسجیل claim it
--    by typing one token. The check is loosened only as to the SHAPE of the
--    name, never as to how much of it must be known.
--
-- 3. private.handle_new_user() restated from 20260922000006 — otherwise
--    unchanged — using that helper, and writing father_name onto the profile.
--    It still raises REGISTRATION_NAME_MISMATCH, so the Urdu message the app
--    already shows for that code keeps working.
--
-- 4. public.verify_course_registration() gains p_father_name. It is dropped
--    and recreated rather than replaced, because CREATE OR REPLACE cannot
--    change a parameter list: a second overload would make the existing
--    three-argument call ambiguous and fail. The new fourth parameter is
--    defaulted, so an older installed APK calling it with three named
--    arguments still resolves. A drop discards the function's grants, so they
--    are restored below.
--
-- What this does NOT do. No column is dropped or renamed. No auth user is
-- created, deleted or altered. No password, email, user id, role, session,
-- policy or foreign key is touched. Nothing writes email_confirmed_at. No
-- row of anyone's work is modified: the only data change in this file is a
-- new, empty, nullable column.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. ولدیت gets a column of its own
-- ---------------------------------------------------------------------
alter table public.course_participants
  add column if not exists father_name text;

comment on column public.course_participants.father_name is
  'ولدیت, for records entered since it had a column of its own. Null for '
  'everything imported before, where full_name may hold both names with no '
  'way to tell them apart. Never filled in by splitting full_name.';

-- ---------------------------------------------------------------------
-- 2. What counts as a matching name
-- ---------------------------------------------------------------------
-- p_name is the person's own name, p_father their ولدیت, which may be null
-- because the register may hold none. r is the register row already found by
-- its رقم التسجیل, so every comparison here is against that one row — a
-- looser name rule cannot widen the search to anybody else's record.
create or replace function private.name_matches(
  p_name   text,
  p_father text,
  r        public.course_participants
) returns boolean
language sql
immutable
set search_path to ''
as $$
  select case
    -- A blank name must never match. Without this, name_key('') = '' would
    -- make an empty name agree with an empty register value.
    when coalesce(btrim(p_name), '') = '' then false
    else
      -- The register holds the name on its own.
      private.name_key(p_name) = r.name_key

      -- The register holds both, in the order the form asks for them.
      or private.name_key(concat_ws(' ', p_name, p_father)) = r.name_key

      -- The register holds both the other way round.
      or private.name_key(concat_ws(' ', p_father, p_name)) = r.name_key

      -- The register writes ولد or بن between the two.
      or private.name_key(concat_ws(' ', p_name, p_father)) =
         btrim(regexp_replace(
           regexp_replace(r.name_key, '(^|\s)(ولد|بن|ولدیت)(\s|$)', ' ', 'g'),
           '\s+', ' ', 'g'))

      -- The register keeps the two in their own columns, and each agrees.
      or (r.father_name is not null
          and private.name_key(p_name) = private.name_key(r.full_name)
          and private.name_key(p_father) = private.name_key(r.father_name))
  end
$$;

comment on function private.name_matches(text, text, public.course_participants) is
  'True when a نام and ولدیت agree with a register row, whichever of the '
  'shapes the organisation''s own file uses. Exact equalities only: the '
  'shape is forgiven, the content is not.';

-- ---------------------------------------------------------------------
-- 3. The signup trigger
-- ---------------------------------------------------------------------
-- Restated in full from 20260922000006. Changed: v_father_name is read from
-- the metadata, the name check calls private.name_matches(), and the profile
-- row carries father_name. Everything else — the invitation path, the
-- bootstrap administrators, the role coming from the database rather than the
-- client, the FOR UPDATE that stops two signups claiming one number — is
-- exactly as it was.
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
  v_father_name   text;
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
  v_father_name := nullif(btrim(
    coalesce(new.raw_user_meta_data ->> 'father_name', '')), '');
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
    -- An invitation records one name, so nothing here claims a ولدیت.
    v_father_name := null;
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
    elsif not private.name_matches(v_full_name, v_father_name, r) then
      raise exception 'REGISTRATION_NAME_MISMATCH';
    elsif not private.period_matches(
            coalesce(new.raw_user_meta_data ->> 'course_period', ''), r) then
      raise exception 'REGISTRATION_PERIOD_MISMATCH';
    end if;

    -- The register is authoritative where it can tell the two names apart.
    -- Where it cannot, the pair as typed is kept: the check above has already
    -- proved it agrees with the register, and only the person can say which
    -- part of a combined name is the ولدیت.
    if r.father_name is not null then
      v_full_name := r.full_name;
      v_father_name := r.father_name;
    end if;

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
    id, full_name, father_name, email, gender, wifaq_id, institute_id
  )
  values (
    new.id, v_full_name, v_father_name, new.email, v_gender, v_wifaq_id,
    v_institute_id
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

  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 4. The check the app makes before it tries
-- ---------------------------------------------------------------------
-- Dropped and recreated to take a fourth parameter; see the header. The
-- parameter is defaulted, so a three-argument call from an older installed
-- build still resolves.
drop function if exists public.verify_course_registration(text, text, text);

create or replace function public.verify_course_registration(
  p_registration_number text,
  p_full_name           text default null,
  p_father_name         text default null,
  p_course_period       text default null
)
returns table (
  valid              boolean,
  reason             text,
  participant_name   text,
  participant_period text
)
language plpgsql
stable
security definer
set search_path to ''
as $$
declare
  v_key text;
  r     public.course_participants;
begin
  v_key := upper(regexp_replace(
    coalesce(p_registration_number, ''), '[^A-Za-z0-9]', '', 'g'));

  if v_key = '' then
    return query select false, 'required', null::text, null::text;
    return;
  end if;

  select * into r from public.course_participants
  where registration_key = v_key;

  if not found then
    return query select false, 'not_found', null::text, null::text;
  elsif not r.eligible then
    return query select false, 'not_eligible', null::text, null::text;
  elsif r.account_created then
    return query select false, 'already_used', null::text, null::text;
  elsif p_full_name is not null
        and not private.name_matches(p_full_name, p_father_name, r) then
    return query select false, 'name_mismatch', null::text, null::text;
  elsif p_course_period is not null
        and not private.period_matches(p_course_period, r) then
    return query select false, 'period_mismatch', null::text, null::text;
  else
    -- The period is returned only once the number, name and period have all
    -- matched, so it confirms a record the applicant already proved is theirs.
    return query select true, 'ok', r.full_name,
      coalesce(nullif(r.course_period, ''),
               nullif(concat_ws(' — ', r.course_start_date,
                                r.course_completion_date), ''));
  end if;
end;
$$;

-- A drop takes the grants with it. The caller here has no account yet, so
-- anon must be able to execute it; nothing else may.
revoke all on function public.verify_course_registration(
  text, text, text, text) from public;
grant execute on function public.verify_course_registration(
  text, text, text, text) to anon, authenticated;

-- =====================================================================
-- Verify after applying. Each of these should hold; none of them writes.
--
--   -- the column exists and is empty, and name_key is untouched
--   select count(*) as rows, count(father_name) as with_father
--   from public.course_participants;
--
--   -- the reported case now matches. Replace the names with a real
--   -- register row's, keeping them in separate arguments.
--   select private.name_matches('نام', 'ولدیت', r)
--   from public.course_participants r
--   where r.registration_key = 'THENUMBER';      -- expect true
--
--   -- a wrong name is still refused
--   select private.name_matches('کوئی اور', null, r)
--   from public.course_participants r
--   where r.registration_key = 'THENUMBER';      -- expect false
--
--   -- nobody was touched: compare with the values from before
--   select count(*) from auth.users;
--   select role, count(*) from public.user_roles group by role;
-- =====================================================================
