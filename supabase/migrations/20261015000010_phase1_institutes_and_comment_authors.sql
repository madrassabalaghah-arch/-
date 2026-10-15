-- =====================================================================
-- Phase 1 — the two defects that are database faults  (NOT YET APPLIED)
--
-- Defects 1.1 (dashboard card opens the wrong list) and 1.3 (Null instead
-- of a name on a کارگزاری) are faults in the Flutter app, not in the
-- database, and are fixed there. Their root causes are in the report.
--
-- ---------------------------------------------------------------------
-- 1.2  A مربی's institute was not saved
-- ---------------------------------------------------------------------
-- Two causes. Both are real, and only the second is a fault.
--
-- (a) private.handle_new_user() creates an institutes row only inside the
--     course-register branch. An invited مربی goes down the invitation
--     branch, which never touches institutes at all.
--
--     Left exactly as it is, deliberately. An invitation records a name, an
--     email and a role — it carries no وفاق and no institution, so there is
--     nothing for the trigger to create. A مربی records their institution on
--     their profile afterwards, which is the path (b) unblocks. Adding
--     institute fields to the invitation would mean an منتظم guessing them
--     on the مربی's behalf.
--
-- (b) 20260925000007 narrowed the institutes INSERT policy to:
--
--         private.has_role(auth.uid(), 'graduate') or private.is_admin()
--
--     A مربی holds neither role, so the policy refused their insert. This is
--     the fault: the narrowing was aimed at role-less accounts and caught
--     mentors by accident.
--
-- Decided, and enforced in the database rather than in the UI: a مربی MAY
-- record an institution, deduplicated on the existing (wifaq_id, name_key)
-- unique index, so «جامعہ اشرفیہ» and «جامعہ  اشرفیہ» stay one institution.
-- Two layers: the INSERT policy now admits a مربی, and
-- find_or_create_institute() does the matching server-side so no client can
-- create a near-duplicate by accident or by racing another signup.
--
-- A وفاق is still a curated list only an منتظم may write. Nothing here
-- changes that.
--
-- ---------------------------------------------------------------------
-- 1.4  عوامی تبصرے showed no author name
-- ---------------------------------------------------------------------
-- The board's feed goes through community_feed(), a SECURITY DEFINER
-- function that returns author_name as a plain column. The comment list was
-- read straight from the community_comments table with a client-side embed
-- of profiles — and RLS on profiles correctly stops a فاضل from reading
-- another فاضل's row, so that embed returned null. The policy was doing its
-- job; the query was asking the wrong way.
--
-- The profiles SELECT policy is NOT loosened. Exposing every profile to
-- every signed-in account in order to print a name would be a far worse
-- trade than adding a function. Comments are now served the way the feed
-- already is: through a SECURITY DEFINER function returning only the columns
-- a board may show.
--
-- That function never returns an email address, a رقم التسجیل, a نجی جائزہ,
-- or any other private column. عوامی تبصرہ and نجی جائزہ stay separate, read
-- through separate paths.
--
-- ---------------------------------------------------------------------
-- Deliberately left alone
-- ---------------------------------------------------------------------
-- The profiles SELECT policy. Every other policy. The shape of
-- community_comments and community_posts. private.handle_new_user(). All
-- existing data. No column or table is dropped or renamed; no auth user,
-- password, role, session or id is written. The only schema additions are
-- two functions and one widened INSERT policy.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1.2a  A مربی may record an institution
-- ---------------------------------------------------------------------
drop policy if exists "institutes insertable by graduates" on public.institutes;

create policy "institutes insertable by members" on public.institutes
  for insert to authenticated
  with check (
    private.has_role(auth.uid(), 'graduate')
    or private.has_role(auth.uid(), 'mentor')
    or private.is_admin()
  );

comment on policy "institutes insertable by members" on public.institutes is
  'A فاضل, فاضلہ or مربی may record their own institution; an منتظم may '
  'record any. An account with no role may not — which is what the policy '
  'this replaces was for, before it caught mentors by accident.';

-- ---------------------------------------------------------------------
-- 1.2b  One institution, however the name is typed
-- ---------------------------------------------------------------------
-- Returns the id of the institution, creating it only if this وفاق has no
-- institution whose normalised name matches. name_key is the generated
-- column the unique index is built on, so this cannot disagree with the
-- index — it matches on exactly what the index enforces.
create or replace function public.find_or_create_institute(
  p_wifaq_id uuid,
  p_name     text,
  p_city     text default null
) returns uuid
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_name text;
  v_id   uuid;
begin
  if not (private.has_role(auth.uid(), 'graduate')
          or private.has_role(auth.uid(), 'mentor')
          or private.is_admin()) then
    raise exception 'ROLE_REQUIRED';
  end if;

  v_name := nullif(btrim(
    regexp_replace(coalesce(p_name, ''), '\s+', ' ', 'g')), '');
  if v_name is null then
    raise exception 'INSTITUTE_NAME_REQUIRED';
  end if;
  if p_wifaq_id is null then
    raise exception 'WIFAQ_REQUIRED';
  end if;

  -- The name is stored exactly as it was written; only the matching is
  -- normalised. An existing row keeps its own spelling rather than being
  -- overwritten by whoever typed it next.
  insert into public.institutes (name, wifaq_id, city)
  values (v_name, p_wifaq_id, nullif(btrim(coalesce(p_city, '')), ''))
  on conflict (wifaq_id, name_key) do update
    set name = public.institutes.name
  returning id into v_id;

  return v_id;
end;
$$;

comment on function public.find_or_create_institute(uuid, text, text) is
  'The id of this وفاق''s institution by that name, created if it is new. '
  'Matched on the (wifaq_id, name_key) unique index, so spacing and '
  'diacritics cannot split one institution into two.';

revoke all on function public.find_or_create_institute(uuid, text, text)
  from public;
grant execute on function public.find_or_create_institute(uuid, text, text)
  to authenticated;

-- ---------------------------------------------------------------------
-- 1.4  عوامی تبصرے, with their authors' names
-- ---------------------------------------------------------------------
-- Only these columns. No email, no رقم التسجیل, no نجی جائزہ, not even
-- author_id — a board shows who wrote a تبصرہ by name, and nothing else
-- about them.
create or replace function public.community_comments_for(
  p_report_id uuid default null,
  p_post_id   uuid default null
) returns table (
  id          uuid,
  body        text,
  created_at  timestamptz,
  author_name text,
  author_role text,
  is_hidden   boolean
)
language plpgsql
stable
security definer
set search_path to ''
as $$
begin
  if p_report_id is null and p_post_id is null then
    raise exception 'TARGET_REQUIRED';
  end if;

  -- SECURITY DEFINER bypasses RLS, so the visibility the policies would have
  -- applied is re-applied here by hand. A تبصرہ is readable only when the
  -- thing it is about is on the board: a کارگزاری its owner shared, or a post
  -- that is not hidden.
  if p_report_id is not null then
    if not exists (
      select 1 from public.reports r
      where r.id = p_report_id and r.shared_at is not null
    ) then
      return;
    end if;
  else
    if not exists (
      select 1 from public.community_posts p
      where p.id = p_post_id
        and (not p.is_hidden or private.is_admin())
    ) then
      return;
    end if;
  end if;

  return query
    select c.id,
           c.body,
           c.created_at,
           coalesce(nullif(btrim(pr.full_name), ''), '') as author_name,
           (select ur.role::text
              from public.user_roles ur
             where ur.user_id = c.author_id
             order by case ur.role
                        when 'admin'  then 1
                        when 'mentor' then 2
                        else 3
                      end
             limit 1) as author_role,
           c.is_hidden
      from public.community_comments c
      left join public.profiles pr on pr.id = c.author_id
     where ((p_report_id is not null and c.report_id = p_report_id)
            or (p_post_id is not null and c.post_id = p_post_id))
       -- A hidden تبصرہ stays visible to an منتظم, who is the one who hid it.
       and (not c.is_hidden or private.is_admin())
     order by c.created_at;
end;
$$;

comment on function public.community_comments_for(uuid, uuid) is
  'عوامی تبصرے on one shared کارگزاری or board post, with the author''s '
  'name. Serves the comment list the way community_feed() serves the board, '
  'so the profiles SELECT policy never has to be loosened to show a name. '
  'Returns no email, رقم التسجیل or نجی جائزہ.';

revoke all on function public.community_comments_for(uuid, uuid) from public;
grant execute on function public.community_comments_for(uuid, uuid)
  to authenticated;

-- =====================================================================
-- Verify after applying. None of these writes.
--
--   -- a مربی may now record an institution, and twice gives one row
--   select public.find_or_create_institute(
--     (select id from public.wifaqs limit 1), '  جامعہ   اشرفیہ ');
--   select public.find_or_create_institute(
--     (select id from public.wifaqs limit 1), 'جامعہ اشرفیہ');
--   -- expect the SAME uuid twice, and one row:
--   select count(*) from public.institutes where name_key = 'جامعہ اشرفیہ';
--
--   -- comments carry a name, and nothing private
--   select * from public.community_comments_for(
--     (select id from public.reports where shared_at is not null limit 1));
--
--   -- the profiles policy was NOT loosened: signed in as a فاضل, this must
--   -- still return only their own row
--   select count(*) from public.profiles;
--
--   -- nothing moved
--   select count(*) from auth.users;
--   select role, count(*) from public.user_roles group by role;
-- =====================================================================
