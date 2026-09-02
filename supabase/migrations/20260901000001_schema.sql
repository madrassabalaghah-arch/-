-- =====================================================================
-- کارواں فضلاء مدرسہ ڈاٹ پی کے  /  MADRASSA.PK Graduate Platform
-- Migration 1 of 3 — enums, tables, indexes
--
-- PROPOSAL ONLY. Not applied. Derived from the existing Flutter screens
-- and models; every column below backs something the UI already renders.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Enums. These mirror the Dart enums already used by the interface, so
-- the Urdu labels in app_strings.dart map 1:1 onto database values.
-- ---------------------------------------------------------------------
create type public.app_role as enum ('graduate', 'mentor', 'admin');

create type public.work_status as enum (
  'draft',        -- مسودہ
  'pending',      -- زیرِ التوا
  'submitted',    -- جمع کروا دی گئی
  'under_review', -- زیرِ جائزہ
  'completed',    -- مکمل
  'late',         -- تاخیر سے
  'inactive',     -- غیر فعال
  'active'        -- فعال
);

create type public.recognition_tier as enum ('milestone', 'award', 'appreciation');

create type public.notification_kind as enum (
  'report', 'review', 'recognition', 'reminder', 'system'
);

create type public.evidence_kind as enum ('image', 'video', 'document');

-- ---------------------------------------------------------------------
-- Reference data
-- ---------------------------------------------------------------------
create table public.wifaqs (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  city        text,
  status      public.work_status not null default 'active',
  created_at  timestamptz not null default now()
);

create table public.institutes (
  id          uuid primary key default gen_random_uuid(),
  wifaq_id    uuid references public.wifaqs (id) on delete set null,
  name        text not null,
  city        text,
  status      public.work_status not null default 'active',
  created_at  timestamptz not null default now()
);
create index institutes_wifaq_id_idx on public.institutes (wifaq_id);

-- ---------------------------------------------------------------------
-- Identity. profiles.id IS auth.users.id — one row per authenticated
-- user, created automatically by the trigger in migration 2.
-- ---------------------------------------------------------------------
create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  full_name    text not null default '',
  father_name  text,
  institute_id uuid references public.institutes (id) on delete set null,
  wifaq_id     uuid references public.wifaqs (id) on delete set null,
  city         text,
  phone        text,
  email        text,
  stage        text,                  -- تربیتی مرحلہ
  avatar_path  text,                  -- storage object path, not a URL
  status       public.work_status not null default 'active',
  joined_on    date,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index profiles_institute_id_idx on public.profiles (institute_id);

-- Roles live in their OWN table, never on profiles. If the role were a
-- profiles column, any user who can update their profile could promote
-- themselves to admin. This table is writable by admins only.
create table public.user_roles (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  role       public.app_role not null,
  created_at timestamptz not null default now(),
  unique (user_id, role)
);
create index user_roles_user_id_idx on public.user_roles (user_id);

-- The relationship every mentor policy depends on.
create table public.mentor_assignments (
  id          uuid primary key default gen_random_uuid(),
  mentor_id   uuid not null references public.profiles (id) on delete cascade,
  graduate_id uuid not null references public.profiles (id) on delete cascade,
  assigned_at timestamptz not null default now(),
  is_active   boolean not null default true,
  unique (mentor_id, graduate_id),
  constraint mentor_assignments_not_self check (mentor_id <> graduate_id)
);
create index mentor_assignments_mentor_id_idx on public.mentor_assignments (mentor_id);
create index mentor_assignments_graduate_id_idx on public.mentor_assignments (graduate_id);

-- ---------------------------------------------------------------------
-- Curriculum: courses and the practical activities graduates work on
-- ---------------------------------------------------------------------
create table public.courses (
  id             uuid primary key default gen_random_uuid(),
  title          text not null,
  duration_label text,
  status         public.work_status not null default 'active',
  created_at     timestamptz not null default now()
);

create table public.course_enrollments (
  id          uuid primary key default gen_random_uuid(),
  course_id   uuid not null references public.courses (id) on delete cascade,
  graduate_id uuid not null references public.profiles (id) on delete cascade,
  enrolled_at timestamptz not null default now(),
  unique (course_id, graduate_id)
);
create index course_enrollments_graduate_id_idx
  on public.course_enrollments (graduate_id);

-- Catalogue of عملی سرگرمیاں. icon_key maps to the Flutter IconData
-- lookup so icons stay UI constants rather than database data.
create table public.activities (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  detail      text,
  icon_key    text,
  total_steps integer not null default 1 check (total_steps > 0),
  status      public.work_status not null default 'active',
  created_at  timestamptz not null default now()
);

-- Per-graduate progress against an activity.
create table public.graduate_activities (
  id              uuid primary key default gen_random_uuid(),
  graduate_id     uuid not null references public.profiles (id) on delete cascade,
  activity_id     uuid not null references public.activities (id) on delete cascade,
  completed_steps integer not null default 0 check (completed_steps >= 0),
  status          public.work_status not null default 'pending',
  updated_at      timestamptz not null default now(),
  unique (graduate_id, activity_id)
);
create index graduate_activities_graduate_id_idx
  on public.graduate_activities (graduate_id);

-- ---------------------------------------------------------------------
-- The core workflow: report -> evidence -> evaluation
-- ---------------------------------------------------------------------
create table public.reports (
  id           uuid primary key default gen_random_uuid(),
  graduate_id  uuid not null references public.profiles (id) on delete cascade,
  activity_id  uuid references public.activities (id) on delete set null,
  title        text not null,
  summary      text,
  status       public.work_status not null default 'draft',
  submitted_at timestamptz,
  due_at       timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index reports_graduate_id_idx on public.reports (graduate_id);
create index reports_status_idx on public.reports (status);

create table public.evidence (
  id          uuid primary key default gen_random_uuid(),
  report_id   uuid references public.reports (id) on delete cascade,
  graduate_id uuid not null references public.profiles (id) on delete cascade,
  title       text not null,
  kind        public.evidence_kind not null default 'document',
  storage_path text not null,          -- object path in the evidence bucket
  mime_type   text,
  size_bytes  bigint,
  status      public.work_status not null default 'submitted',
  created_at  timestamptz not null default now()
);
create index evidence_report_id_idx on public.evidence (report_id);
create index evidence_graduate_id_idx on public.evidence (graduate_id);

-- جانچ کے معیارات — the rubric the mentor review form renders as sliders.
create table public.evaluation_standards (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  detail     text,
  weight     integer not null default 0 check (weight between 0 and 100),
  status     public.work_status not null default 'active',
  created_at timestamptz not null default now()
);

create table public.evaluations (
  id          uuid primary key default gen_random_uuid(),
  report_id   uuid not null references public.reports (id) on delete cascade,
  mentor_id   uuid not null references public.profiles (id) on delete cascade,
  graduate_id uuid not null references public.profiles (id) on delete cascade,
  comment     text,
  total_score integer not null default 0 check (total_score >= 0),
  max_score   integer not null default 0 check (max_score >= 0),
  status      public.work_status not null default 'under_review',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (report_id, mentor_id)
);
create index evaluations_graduate_id_idx on public.evaluations (graduate_id);
create index evaluations_mentor_id_idx on public.evaluations (mentor_id);

-- One score per standard, so the rubric stays data-driven.
create table public.evaluation_scores (
  id            uuid primary key default gen_random_uuid(),
  evaluation_id uuid not null references public.evaluations (id) on delete cascade,
  standard_id   uuid not null references public.evaluation_standards (id) on delete cascade,
  score         integer not null default 0 check (score >= 0),
  unique (evaluation_id, standard_id)
);

-- ---------------------------------------------------------------------
-- Guidance, duties, awards, follow-ups, notifications
-- ---------------------------------------------------------------------

-- مربی کی رہنمائی — standalone guidance, separate from a report review.
create table public.mentor_feedback (
  id          uuid primary key default gen_random_uuid(),
  mentor_id   uuid not null references public.profiles (id) on delete cascade,
  graduate_id uuid not null references public.profiles (id) on delete cascade,
  subject     text not null,
  message     text not null,
  created_at  timestamptz not null default now()
);
create index mentor_feedback_graduate_id_idx on public.mentor_feedback (graduate_id);

-- ذمہ داریاں
create table public.assignments (
  id          uuid primary key default gen_random_uuid(),
  graduate_id uuid not null references public.profiles (id) on delete cascade,
  created_by  uuid references public.profiles (id) on delete set null,
  title       text not null,
  detail      text,
  due_at      timestamptz,
  status      public.work_status not null default 'pending',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index assignments_graduate_id_idx on public.assignments (graduate_id);

-- اعزازات
create table public.recognitions (
  id          uuid primary key default gen_random_uuid(),
  graduate_id uuid not null references public.profiles (id) on delete cascade,
  awarded_by  uuid references public.profiles (id) on delete set null,
  title       text not null,
  detail      text,
  tier        public.recognition_tier not null default 'appreciation',
  awarded_at  timestamptz not null default now()
);
create index recognitions_graduate_id_idx on public.recognitions (graduate_id);

-- اگلی پیروی
create table public.follow_ups (
  id           uuid primary key default gen_random_uuid(),
  graduate_id  uuid not null references public.profiles (id) on delete cascade,
  mentor_id    uuid references public.profiles (id) on delete set null,
  title        text not null,
  detail       text,
  scheduled_at timestamptz,
  status       public.work_status not null default 'pending',
  created_at   timestamptz not null default now()
);
create index follow_ups_graduate_id_idx on public.follow_ups (graduate_id);

-- اطلاعات — addressed to exactly one recipient.
create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  title      text not null,
  body       text,
  kind       public.notification_kind not null default 'system',
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);
create index notifications_user_id_created_at_idx
  on public.notifications (user_id, created_at desc);

-- ---------------------------------------------------------------------
-- updated_at maintenance
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger reports_set_updated_at before update on public.reports
  for each row execute function public.set_updated_at();
create trigger evaluations_set_updated_at before update on public.evaluations
  for each row execute function public.set_updated_at();
create trigger assignments_set_updated_at before update on public.assignments
  for each row execute function public.set_updated_at();
create trigger graduate_activities_set_updated_at before update on public.graduate_activities
  for each row execute function public.set_updated_at();
