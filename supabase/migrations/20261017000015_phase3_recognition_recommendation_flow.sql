-- =====================================================================
-- Phase 3/4, step 2 of 3: recommended, then approved or not    (APPLIED)
--
-- WHAT THE شعبۂ خدمت IS. The brief lists six, and asks whether they are
-- the taxonomy already in report_categories under another name. Checked
-- against the live rows — they are:
--
--   علمی و تحقیقی کاوش          -> academic_research
--   مؤثر تدریسی خدمت            -> teaching_improvement
--   سماجی و دعوتی خدمت          -> positive_social_role
--                                  (group سماجی و دعوتی کردار)
--   افراد سازی و ٹیم ورک        -> people_building
--   مسجد و مدرسے میں عملی کردار -> the group مسجد و مدرسہ میں عملی کردار
--   تکنیکی مہارت کا استعمال      -> technical_skills
--
-- So recognitions.category_id references report_categories rather than a
-- second list being created. One list the منتظم maintains, as the brief
-- asks, and an اعزاز is then provably about the same شعبہ a کارگزاری was
-- filed under.
--
-- NO SCORES. Nothing here counts, totals, averages, ranks or compares one
-- person with another. A tier is proposed in words with reasons attached;
-- the four tiers carry an order of standing and nothing else. There is no
-- automatic award: every row is written by a مربی and decided by an منتظم.
--
-- recognition_rules and award_earned_recognitions() — the count-threshold
-- awarder that predates this — are left in place and are NOT part of this
-- flow. Both were empty and inert (0 rules, 0 recognitions), and the
-- application no longer calls the function. Dropping either is destructive
-- and was not asked for.
--
-- Leaves alone: recognitions' existing columns (graduate_id, awarded_by,
-- title, detail, tier, awarded_at), every other table, and all data.
-- =====================================================================

alter table public.recognitions
  add column if not exists status public.recognition_status
    not null default 'pending',
  add column if not exists category_id uuid
    references public.report_categories (id) on delete set null,
  add column if not exists report_id uuid
    references public.reports (id) on delete set null,
  add column if not exists reason           text,
  add column if not exists notable_work     text,
  add column if not exists positive_results text,
  add column if not exists recommended_by   uuid references auth.users (id)
    on delete set null,
  add column if not exists recommended_at   timestamptz not null default now(),
  add column if not exists decided_by       uuid references auth.users (id)
    on delete set null,
  add column if not exists decided_at       timestamptz,
  add column if not exists decision_note    text;

-- Only the four tiers the brief names may be stored. NOT VALID so the
-- constraint applies to new rows without rewriting any existing one; the
-- table was empty, so nothing is grandfathered in by that.
alter table public.recognitions drop constraint if exists recognitions_tier_allowed;
alter table public.recognitions add constraint recognitions_tier_allowed
  check (tier in ('worthy_progress','notable_performance',
                  'distinguished_service','exemplary_impact')) not valid;

alter table public.recognitions
  alter column tier set default 'worthy_progress'::public.recognition_tier;

comment on column public.recognitions.status is
  'pending until an منتظم decides. A فاضل may read only approved rows.';
comment on column public.recognitions.category_id is
  'شعبۂ خدمت — a report_categories row, the same list a کارگزاری is filed '
  'under, so the two cannot drift apart.';

create index if not exists recognitions_graduate_status_idx
  on public.recognitions (graduate_id, status);
create index if not exists recognitions_status_idx
  on public.recognitions (status);

-- ---------------------------------------------------------------------
-- Who may see what
-- ---------------------------------------------------------------------
alter table public.recognitions enable row level security;

-- A فاضل sees their approved اعزازات and nothing else — not a pending
-- recommendation about them, not a rejected one. A مربی sees what they
-- themselves recommended. An منتظم sees everything.
drop policy if exists "recognitions select permitted" on public.recognitions;
create policy "recognitions select permitted" on public.recognitions
  for select to authenticated
  using (
    private.is_admin()
    or (auth.uid() = recommended_by)
    or (auth.uid() = graduate_id
        and status = 'approved'::public.recognition_status)
  );

drop policy if exists "recognitions admin deletes" on public.recognitions;
create policy "recognitions admin deletes" on public.recognitions
  for delete to authenticated using (private.is_admin());

-- NOTE: step 3 of this phase removes the pre-existing "recognitions granted
-- by staff" ALL-policy, which otherwise still lets a مربی write the table
-- directly and set status='approved' themselves. Apply step 3 with this
-- file; on its own, this one leaves that path open.

-- ---------------------------------------------------------------------
-- A مربی recommends
-- ---------------------------------------------------------------------
create or replace function public.recommend_recognition(
  p_graduate_id      uuid,
  p_tier             public.recognition_tier,
  p_category_id      uuid default null,
  p_report_id        uuid default null,
  p_reason           text default null,
  p_notable_work     text default null,
  p_positive_results text default null
) returns uuid
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_id    uuid;
  v_title text;
begin
  if not private.has_role(auth.uid(), 'mentor') then
    raise exception 'MENTOR_ONLY';
  end if;
  if not private.is_mentor_of(p_graduate_id) then
    raise exception 'NOT_ASSIGNED';
  end if;
  if auth.uid() = p_graduate_id then
    raise exception 'SELF_RECOMMENDATION';
  end if;
  if coalesce(btrim(p_reason), '') = '' then
    raise exception 'REASON_REQUIRED';
  end if;

  select ca.title into v_title
  from public.report_categories ca where ca.id = p_category_id;

  insert into public.recognitions (
    graduate_id, tier, category_id, report_id, reason, notable_work,
    positive_results, recommended_by, recommended_at, status,
    title, detail
  ) values (
    p_graduate_id, p_tier, p_category_id, p_report_id,
    btrim(p_reason), nullif(btrim(coalesce(p_notable_work, '')), ''),
    nullif(btrim(coalesce(p_positive_results, '')), ''),
    auth.uid(), now(), 'pending'::public.recognition_status,
    -- title and detail are NOT NULL from the original design; they carry
    -- the شعبہ and the reason so an older reader still shows something true.
    coalesce(v_title, 'اعزاز کی سفارش'), btrim(p_reason)
  )
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.recommend_recognition(
  uuid, public.recognition_tier, uuid, uuid, text, text, text) from public, anon;
grant execute on function public.recommend_recognition(
  uuid, public.recognition_tier, uuid, uuid, text, text, text) to authenticated;

-- ---------------------------------------------------------------------
-- An منتظم decides
-- ---------------------------------------------------------------------
create or replace function public.decide_recognition(
  p_id      uuid,
  p_approve boolean,
  p_note    text default null
) returns void
language plpgsql
security definer
set search_path to ''
as $$
declare
  r public.recognitions;
begin
  if not private.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;

  select * into r from public.recognitions where id = p_id for update;
  if not found then
    raise exception 'RECOGNITION_NOT_FOUND';
  end if;
  if r.status <> 'pending'::public.recognition_status then
    raise exception 'ALREADY_DECIDED';
  end if;
  -- Nobody approves their own recommendation, even an منتظم who is also a
  -- مربی and wrote it.
  if r.recommended_by = auth.uid() then
    raise exception 'SELF_APPROVAL';
  end if;

  update public.recognitions
  set status = case when p_approve
                    then 'approved'::public.recognition_status
                    else 'rejected'::public.recognition_status end,
      decided_by    = auth.uid(),
      decided_at    = now(),
      decision_note = nullif(btrim(coalesce(p_note, '')), ''),
      -- The permanent record of the award itself, set only on approval.
      awarded_by    = case when p_approve then auth.uid() else awarded_by end,
      awarded_at    = case when p_approve then now() else awarded_at end
  where id = p_id;

  -- Only an approved اعزاز is announced. A rejection stays between the مربی
  -- who proposed it and the منتظم who declined it.
  if p_approve then
    insert into public.notifications (user_id, title, body, kind)
    values (
      r.graduate_id,
      'مبارک ہو — آپ کو اعزاز دیا گیا ہے',
      nullif(btrim(coalesce(r.reason, '')), ''),
      'recognition'::public.notification_kind
    );
  end if;
end;
$$;

revoke all on function public.decide_recognition(uuid, boolean, text)
  from public, anon;
grant execute on function public.decide_recognition(uuid, boolean, text)
  to authenticated;
