-- =====================================================================
-- Community Board, the four کارگزاری categories, and removing مہمان
--
-- RUN THIS WHOLE FILE IN THE SUPABASE SQL EDITOR.
-- It is written to be safe to run twice.
--
-- Nothing here deletes a کارگزاری, an account, a review or a file. The
-- old categories are switched off rather than removed, so every existing
-- کارگزاری keeps pointing at the category it was filed under.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. مہمان is cancelled: remove what only it used
--
-- The policy below is recreated first because it calls private.is_guest(),
-- which is dropped straight after. The value 'guest' stays in the app_role
-- enum: Postgres cannot drop an enum value, and nothing assigns it now.
-- ---------------------------------------------------------------------

drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own" on public.profiles
  for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop function if exists public.public_statistics();
drop function if exists public.public_activity_breakdown();
drop function if exists private.is_guest();

-- Invitations are for مربی and منتظم again.
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

-- NOT VALID: new invitations must be مربی or منتظم, while any guest
-- invitation already sitting in the table is left alone rather than
-- failing the whole script. Nothing can create another one.
alter table public.staff_invites
  add constraint staff_invites_role_check
  check (role in ('mentor', 'admin')) not valid;

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

-- The dashboard figures no longer count guests. The function loses a
-- column, and Postgres will not let CREATE OR REPLACE change the shape of
-- what a function returns, so the old one is dropped first.
drop function if exists public.admin_dashboard_statistics();

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
-- 2. The four categories and their twelve sub-criteria
--
-- The existing table already has the right shape: a group (the main
-- category) and a row per sub-criterion. The old five are switched off,
-- not deleted, so historical کارگزاری keep their category.
-- ---------------------------------------------------------------------

update public.report_categories
set is_active = false
where key not in (
  'positive_personal_change', 'academic_research', 'technical_skills',
  'teaching_improvement', 'mosque_madrasa_change', 'people_building',
  'positive_social_role', 'outreach_influence', 'unity_cooperation',
  'observable_results', 'effectiveness', 'continuity'
);

-- Written as an update-then-insert rather than ON CONFLICT, because that
-- would need a unique constraint on `key` which this table may not have.
-- Running it twice changes nothing.
with wanted(key, group_key, group_title, title, sort_order) as (
  values
    -- 1. ذاتی و علمی ترقی
    ('positive_personal_change', 'personal_academic', 'ذاتی و علمی ترقی', 'مثبت ذاتی تبدیلی', 1),
    ('academic_research',        'personal_academic', 'ذاتی و علمی ترقی', 'علمی و تحقیقی سرگرمیاں', 2),
    ('technical_skills',         'personal_academic', 'ذاتی و علمی ترقی', 'تکنیکی مہارتوں کا استعمال', 3),
    -- 2. مسجد و مدرسہ میں عملی کردار
    ('teaching_improvement',     'mosque_madrasa', 'مسجد و مدرسہ میں عملی کردار', 'تدریس میں بہتری', 1),
    ('mosque_madrasa_change',    'mosque_madrasa', 'مسجد و مدرسہ میں عملی کردار', 'مسجد و مدرسے میں عملی تبدیلی', 2),
    ('people_building',          'mosque_madrasa', 'مسجد و مدرسہ میں عملی کردار', 'افراد سازی', 3),
    -- 3. سماجی و دعوتی کردار
    ('positive_social_role',     'social_dawah', 'سماجی و دعوتی کردار', 'مثبت سماجی کردار', 1),
    ('outreach_influence',       'social_dawah', 'سماجی و دعوتی کردار', 'ابلاغ و اثر و رسوخ', 2),
    ('unity_cooperation',        'social_dawah', 'سماجی و دعوتی کردار', 'اتحاد و تعاون', 3),
    -- 4. عملی نتائج و اثرات
    ('observable_results',       'results_impact', 'عملی نتائج و اثرات', 'قابل مشاہدہ نتائج', 1),
    ('effectiveness',            'results_impact', 'عملی نتائج و اثرات', 'اثر پذیری', 2),
    ('continuity',               'results_impact', 'عملی نتائج و اثرات', 'تسلسل', 3)
),
updated as (
  update public.report_categories rc
  set group_key   = w.group_key,
      group_title = w.group_title,
      title       = w.title,
      sort_order  = w.sort_order,
      is_active   = true
  from wanted w
  where rc.key = w.key
  returning rc.key
)
insert into public.report_categories (key, group_key, group_title, title, sort_order, is_active)
select w.key, w.group_key, w.group_title, w.title, w.sort_order, true
from wanted w
where w.key not in (select key from updated);

-- ---------------------------------------------------------------------
-- 3. Sharing a کارگزاری to the Community Board
--
-- Nothing becomes public on its own. The graduate chooses to share, and
-- an administrator can withdraw it. A draft is never shared.
-- ---------------------------------------------------------------------

alter table public.reports
  add column if not exists shared_at timestamptz;

comment on column public.reports.shared_at is
  'When the graduate chose to show this کارگزاری on the Community Board. Null means private.';

create index if not exists reports_shared_at_idx
  on public.reports (shared_at desc)
  where shared_at is not null;

-- ---------------------------------------------------------------------
-- 4. Community Board tables
-- ---------------------------------------------------------------------

create table if not exists public.community_posts (
  id          uuid primary key default gen_random_uuid(),
  author_id   uuid not null references public.profiles (id) on delete cascade,
  title       text not null check (btrim(title) <> ''),
  body        text not null check (btrim(body) <> ''),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  -- Moderation: hidden rather than destroyed, so nothing is lost.
  is_hidden   boolean not null default false,
  hidden_by   uuid references public.profiles (id) on delete set null,
  hidden_at   timestamptz
);

comment on table public.community_posts is
  'Posts written straight to the Community Board by a مربی or منتظم.';

create index if not exists community_posts_created_at_idx
  on public.community_posts (created_at desc);

create table if not exists public.community_comments (
  id          uuid primary key default gen_random_uuid(),
  author_id   uuid not null references public.profiles (id) on delete cascade,
  -- A comment belongs to exactly one of the two.
  report_id   uuid references public.reports (id) on delete cascade,
  post_id     uuid references public.community_posts (id) on delete cascade,
  body        text not null check (btrim(body) <> ''),
  created_at  timestamptz not null default now(),
  is_hidden   boolean not null default false,
  hidden_by   uuid references public.profiles (id) on delete set null,
  hidden_at   timestamptz,
  constraint community_comments_one_target
    check ((report_id is null) <> (post_id is null))
);

comment on table public.community_comments is
  'عوامی تبصرہ: public comments. Never private review — that lives in evaluations and mentor_feedback and is not readable here.';

create index if not exists community_comments_report_idx
  on public.community_comments (report_id, created_at desc);
create index if not exists community_comments_post_idx
  on public.community_comments (post_id, created_at desc);

-- ---------------------------------------------------------------------
-- 5. Who may do what
-- ---------------------------------------------------------------------

alter table public.community_posts enable row level security;
alter table public.community_comments enable row level security;

-- Posts: everyone signed in reads what is not hidden; only مربی and منتظم
-- write, and only as themselves.
drop policy if exists "community_posts readable" on public.community_posts;
create policy "community_posts readable" on public.community_posts
  for select to authenticated
  using (not is_hidden or private.is_admin());

drop policy if exists "community_posts written by staff" on public.community_posts;
create policy "community_posts written by staff" on public.community_posts
  for insert to authenticated
  with check (
    auth.uid() = author_id
    and (private.has_role(auth.uid(), 'mentor') or private.is_admin())
  );

drop policy if exists "community_posts edited by author or admin" on public.community_posts;
create policy "community_posts edited by author or admin" on public.community_posts
  for update to authenticated
  using (auth.uid() = author_id or private.is_admin())
  with check (auth.uid() = author_id or private.is_admin());

drop policy if exists "community_posts deleted by author or admin" on public.community_posts;
create policy "community_posts deleted by author or admin" on public.community_posts
  for delete to authenticated
  using (auth.uid() = author_id or private.is_admin());

-- Comments: everyone signed in reads what is not hidden and writes their
-- own. A graduate commenting is the whole point; nobody edits anybody
-- else's words, and an administrator moderates by hiding.
drop policy if exists "community_comments readable" on public.community_comments;
create policy "community_comments readable" on public.community_comments
  for select to authenticated
  using (not is_hidden or private.is_admin());

drop policy if exists "community_comments written as self" on public.community_comments;
create policy "community_comments written as self" on public.community_comments
  for insert to authenticated
  with check (
    auth.uid() = author_id
    and (
      -- on a shared کارگزاری
      (report_id is not null and exists (
        select 1 from public.reports r
        where r.id = report_id
          and r.shared_at is not null
          and r.status <> 'draft'::public.work_status))
      -- or on a board post that is visible
      or (post_id is not null and exists (
        select 1 from public.community_posts p
        where p.id = post_id and not p.is_hidden))
    )
  );

drop policy if exists "community_comments edited by author or admin" on public.community_comments;
create policy "community_comments edited by author or admin" on public.community_comments
  for update to authenticated
  using (auth.uid() = author_id or private.is_admin())
  with check (auth.uid() = author_id or private.is_admin());

drop policy if exists "community_comments deleted by author or admin" on public.community_comments;
create policy "community_comments deleted by author or admin" on public.community_comments
  for delete to authenticated
  using (auth.uid() = author_id or private.is_admin());

-- ---------------------------------------------------------------------
-- 6. What the Community Board actually reads
--
-- A function rather than a table policy, so a shared کارگزاری exposes
-- exactly these columns and nothing else: no phone number, no رقمِ
-- تسجیل, no private review, no internal note. Paginated by time.
-- ---------------------------------------------------------------------

create or replace function public.community_feed(
  p_limit  int default 20,
  p_before timestamptz default null
)
returns table (
  kind           text,
  id             uuid,
  report_id      uuid,
  title          text,
  body           text,
  author_name    text,
  author_role    text,
  group_title    text,
  category_title text,
  activity_date  date,
  created_at     timestamptz,
  comment_count  int
)
language plpgsql
stable
security definer
set search_path to ''
as $$
begin
  if auth.uid() is null then
    raise exception 'SIGN_IN_REQUIRED';
  end if;

  return query
  select * from (
    -- کارگزاری the graduate chose to share
    select
      'karguzari'::text as kind,
      r.id,
      r.id as report_id,
      r.title,
      r.summary as body,
      p.full_name as author_name,
      'graduate'::text as author_role,
      rc.group_title,
      rc.title as category_title,
      r.activity_date,
      coalesce(r.shared_at, r.created_at) as created_at,
      (select count(*) from public.community_comments c
        where c.report_id = r.id and not c.is_hidden)::int as comment_count
    from public.reports r
    join public.profiles p on p.id = r.graduate_id
    left join public.report_categories rc on rc.id = r.category_id
    where r.shared_at is not null
      and r.status <> 'draft'::public.work_status

    union all

    -- posts written straight to the board
    select
      'post'::text,
      cp.id,
      null::uuid,
      cp.title,
      cp.body,
      p.full_name,
      case when private.has_role(cp.author_id, 'admin') then 'admin' else 'mentor' end,
      null::text,
      null::text,
      null::date,
      cp.created_at,
      (select count(*) from public.community_comments c
        where c.post_id = cp.id and not c.is_hidden)::int
    from public.community_posts cp
    join public.profiles p on p.id = cp.author_id
    where not cp.is_hidden
  ) feed
  where p_before is null or feed.created_at < p_before
  order by feed.created_at desc
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
end;
$$;

revoke execute on function public.community_feed(int, timestamptz) from public, anon;
grant execute on function public.community_feed(int, timestamptz) to authenticated;

-- One shared کارگزاری, for the screen a feed item opens. Same columns,
-- same silence about everything private.
create or replace function public.community_karguzari(p_report_id uuid)
returns table (
  id             uuid,
  title          text,
  body           text,
  author_name    text,
  group_title    text,
  category_title text,
  activity_date  date,
  created_at     timestamptz
)
language plpgsql
stable
security definer
set search_path to ''
as $$
begin
  if auth.uid() is null then
    raise exception 'SIGN_IN_REQUIRED';
  end if;

  return query
  select r.id, r.title, r.summary, p.full_name,
         rc.group_title, rc.title, r.activity_date,
         coalesce(r.shared_at, r.created_at)
  from public.reports r
  join public.profiles p on p.id = r.graduate_id
  left join public.report_categories rc on rc.id = r.category_id
  where r.id = p_report_id
    and r.shared_at is not null
    and r.status <> 'draft'::public.work_status;
end;
$$;

revoke execute on function public.community_karguzari(uuid) from public, anon;
grant execute on function public.community_karguzari(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 7. What was deliberately NOT changed
--
-- * evaluations and mentor_feedback keep their policies, so نجی جائزہ
--   stays visible only to the graduate, their مربی and the منتظم. The
--   Community Board functions above never read either table.
-- * Scores (evaluations.total_score / max_score, evaluation_scores,
--   evaluation_standards) are left exactly as they are. The app stops
--   writing and showing them; no existing row is touched.
-- * No کارگزاری, account, review or file is deleted anywhere in this file.
-- =====================================================================
