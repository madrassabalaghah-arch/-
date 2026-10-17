-- =====================================================================
-- Phase 2 — a جائزہ in three parts, and the فاضل is told     (APPLIED)
--
-- 1. evaluations gains commendable (قابلِ تحسین) and guidance (رہنمائی).
--
--    The brief asks a جائزہ to carry a written تبصرہ, a note of قابلِ تحسین
--    work, and رہنمائی for improvement. Only `comment` existed. رہنمائی was
--    being collected by the review screen and written to mentor_feedback as
--    a separate message, and قابلِ تحسین was not collected at all. All three
--    now live on the one row an منتظم opens. Both nullable, no backfill.
--
--    No score, and none added. total_score and max_score still exist and
--    both already default to 0; nothing has written them since scoring was
--    removed. They are left in place because dropping a column in use is
--    destructive and was not asked for — they are inert, not live.
--
-- 2. Notifications, which had never once fired.
--
--    The table, its policies, the NotificationItem model and the اطلاعات
--    sections on all three dashboards have existed throughout, and
--    `select count(*) from public.notifications` returned 0. Nothing in the
--    application ever inserted one: all seven uses of the table were reads
--    or mark-as-read, and no trigger wrote one either. So every اطلاعات
--    section has always been empty.
--
--    Done with triggers rather than a client insert, for two reasons. A
--    caller that forgets is precisely how this came to be. And a جائزہ
--    written by an منتظم should notify the فاضل exactly as a مربی's does,
--    which a single call site in the mentor screen would not cover.
--
--    The two triggers cannot both fire for one action: submitting a جائزہ
--    writes `evaluations`, while handing work back for correction and
--    standalone رہنمائی write `mentor_feedback`, and the review screen no
--    longer duplicates رہنمائی into both.
--
-- Deliberately left alone: every policy on every table, including
-- notifications' own — `notifications created by staff` already lets a مربی
-- insert for an assigned فاضل, so nothing needed widening. The existing
-- columns of evaluations and mentor_feedback. All existing data. No column
-- or table is dropped or renamed, and no auth user, password, role, session
-- or id is written.
-- =====================================================================

alter table public.evaluations add column if not exists commendable text;
alter table public.evaluations add column if not exists guidance    text;

comment on column public.evaluations.commendable is
  'قابلِ تحسین — what the مربی judged worth commending in this کارگزاری. '
  'Words, never a score.';
comment on column public.evaluations.guidance is
  'رہنمائی — what the مربی advised for improvement. Words, never a score.';

-- ---------------------------------------------------------------------
-- A completed جائزہ tells the فاضل
-- ---------------------------------------------------------------------
create or replace function private.notify_graduate_of_evaluation()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_report text;
begin
  -- A جائزہ is only worth announcing once it is finished.
  if new.status <> 'completed'::public.work_status then
    return new;
  end if;

  -- Re-saving the same جائزہ must not notify again. OLD is only touched
  -- inside this branch, because it does not exist on an insert.
  if tg_op = 'UPDATE' then
    if old.status = new.status
       and old.comment     is not distinct from new.comment
       and old.commendable is not distinct from new.commendable
       and old.guidance    is not distinct from new.guidance then
      return new;
    end if;
  end if;

  select nullif(btrim(r.title), '') into v_report
  from public.reports r where r.id = new.report_id;

  insert into public.notifications (user_id, title, body, kind)
  values (
    new.graduate_id,
    case when v_report is null
         then 'آپ کی کارگزاری کا جائزہ مکمل ہو گیا ہے'
         else 'جائزہ مکمل: ' || v_report
    end,
    nullif(btrim(coalesce(new.comment, '')), ''),
    'review'::public.notification_kind
  );

  return new;
end;
$$;

drop trigger if exists notify_graduate_of_evaluation on public.evaluations;
create trigger notify_graduate_of_evaluation
  after insert or update on public.evaluations
  for each row execute function private.notify_graduate_of_evaluation();

-- ---------------------------------------------------------------------
-- A message from the مربی tells the فاضل
-- ---------------------------------------------------------------------
-- Covers handing work back for correction and standalone رہنمائی, both of
-- which write mentor_feedback and neither of which writes an evaluation.
create or replace function private.notify_graduate_of_feedback()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
begin
  insert into public.notifications (user_id, title, body, kind)
  values (
    new.graduate_id,
    nullif(btrim(new.subject), ''),
    nullif(btrim(new.message), ''),
    'review'::public.notification_kind
  );
  return new;
end;
$$;

drop trigger if exists notify_graduate_of_feedback on public.mentor_feedback;
create trigger notify_graduate_of_feedback
  after insert on public.mentor_feedback
  for each row execute function private.notify_graduate_of_feedback();

-- =====================================================================
-- Verified after applying, as the مربی assigned to that فاضل, inside a
-- transaction that was rolled back:
--
--   insert into public.evaluations
--     (report_id, mentor_id, graduate_id, comment, commendable, guidance,
--      status)
--   values (..., 'completed'::public.work_status);
--
--   select n.user_id = '<the فاضل>' as went_to_the_graduate,
--          n.title, n.body, n.kind, n.is_read
--   from public.notifications n;
--
--   went_to_the_graduate | t
--   title                | جائزہ مکمل: درس قرآن
--   body                 | تبصرہ: محنت نمایاں ہے۔
--   kind                 | review
--   is_read              | f
--
-- The insert passing at all proves the مربی's write policy accepts the new
-- columns; the row proves the trigger addresses the right person.
-- =====================================================================
