# MASTER PROMPT 05 — Madrassa Tarbiat App (مدرسہ تربیت ایپ)

## Bug fixes, the review workflow, اعزازات, and device compatibility

This application already exists and is in use. Do **not** rebuild it, redesign
it, or start a parallel system. Make targeted changes to the existing project.

Work in the order the phases are written. Phase 1 comes first because the
workflows in Phases 2–5 read the same data that is currently displaying `Null`
— building on top of a broken join would hide the fault rather than fix it.

---

## Ground rules (apply to every phase)

- **Preserve everything that works.** Do not delete, recreate or deactivate any
  existing account. Do not change user ids, email addresses, passwords, roles,
  sessions or account ownership. Do not force anyone to register again.
- **No destructive database changes.** Do not drop or rename a column or table
  that is in use. Additive migrations only. Ask before anything destructive.
- **Enforce every visibility rule in the database (RLS), not only in the UI.**
  Hiding a button is a courtesy; the policy is the protection. Never use a
  service-role key in the Flutter app and never disable RLS.
- **No mock, dummy, placeholder or hardcoded data.** Every number and name on
  every screen must come from a real query. If something cannot be computed,
  show an empty state, not a fabricated value.
- **No scores, marks, grades, percentages, points, rankings or leaderboards.**
  These were deliberately removed from the whole application and must not
  return in any form, including inside the new اعزازات system.
- **Never report something as tested unless it was actually executed.** Mark
  anything unverified as **NOT VERIFIED** and say why.
- **Do not show unfinished buttons.** If a feature is not complete, do not put
  a control for it on screen.
- Urdu-first, right-to-left throughout. All numerals in Latin digits (0–9)
  through the existing `UrduNumbers` utility. Keep the grammar correct: فاضل /
  فضلاء / فاضلہ / فاضلات / فضلاء و فاضلات by context, never by
  find-and-replace.
- After each phase: `flutter analyze`, `flutter test`, then manual checks on a
  real device. Fix what breaks before starting the next phase.

---

## What already exists — extend it, do not duplicate it

Read these before writing any new table or screen. Several requests below are
mostly already built.

| Need | Already in the project |
|---|---|
| کارگزاری + categories | `reports`, `report_categories` (4 بنیادی شعبے × 3 ذیلی معیار), the two-step picker in `report_editor_screen.dart` |
| Mentor's جائزہ | `mentor_report_review_screen.dart` (4 steps, written guidance, no scores), `mentor_repository.submitEvaluation` |
| اعزازات | `recognitions` table, `RecognitionItem`, `graduate_recognition_screen.dart`, the `adminRecognition` route |
| Courses / activities | `activities`, the activity catalogue, `ActivityItem` with steps and progress, `practical_activities_screen.dart` |
| Community board | `community_posts`, `community_comments`, `community_feed()`, `community_karguzari()` |
| Evidence | `evidence` + Supabase Storage, signed URLs |
| Notifications | `notifications` + `NotificationItem` |
| Register | `course_participants`, with `registration_key` and `name_key` generated columns |

**The اعزازات work is an extension of `recognitions`, not a new table.** The
courses work is an extension of `activities`. Reuse the existing models,
repositories, storage, review and notification code.

---

# PHASE 1 — Fix what is broken now

Four defects. For each one: **find the root cause and state it**, then fix it
at the root. Do not patch the symptom at the UI layer.

### 1.1 Admin dashboard counts open the wrong list

**Symptom.** The first card on the منتظم dashboard shows فضلاء and فاضلات as 5
and 5. Tapping it opens the entire register sheet instead of only that group.

**Required.** Tapping the فضلاء card opens a list of فضلاء only; tapping فاضلات
opens فاضلات only. The number on the card must equal the number of rows in the
list it opens — one filter, counted and listed the same way.

**Before changing the number, check whether it is actually wrong.** `جنس` was
added to `course_participants` after most rows had been imported, so a large
share of rows have `gender = null` and are correctly counted as "درج نہیں"
rather than as فاضل or فاضلہ. 5 and 5 may be the truthful count of rows where
جنس is *recorded*. Report which it is. If most rows have no جنس, the real
problem is register data, and the منتظم needs a way to see and set it — the
participants screen already has a جنس filter and a setter.

### 1.2 A مربی's institute is not saved

**Symptom.** A مربی selects their وفاق, types their institute name, and the
institute is not registered.

**Likely cause — verify before fixing.** Two things point the same way:

1. `private.handle_new_user()` creates an `institutes` row only inside the
   course-register branch. An invited مربی goes down the invitation branch,
   which never touches `institutes` at all.
2. `INSERT` on `institutes` was restricted to منتظم during earlier RLS work, so
   a مربی writing one directly is refused by policy.

**Required.** A مربی can record their وفاق and institute, and both are saved
and visible on their profile afterwards. Decide deliberately whether a مربی may
create a new institute or must choose from existing ones, and enforce that in
RLS, not only in the UI. If they may create one, match on the existing
`institutes (wifaq_id, name_key)` unique key so that "جامعہ اشرفیہ" and
"جامعہ  اشرفیہ" do not become two institutions. Do not add a second institute
table.

### 1.3 `Null` instead of the name on a کارگزاری

**Symptom.** When a فاضل or فاضلہ submits a کارگزاری, the details show `Null`
where the name should be.

**Cause pattern, already seen and fixed once in this project.** A query selects
the report rows without embedding the owner's profile, so the name is simply
absent — and the screen then interpolates a null into a string, printing the
literal text "null". Fix both halves:

- Embed the profile through its foreign key, with an alias, exactly as the
  evidence and review queries already do:
  `graduate:profiles!reports_graduate_id_fkey(full_name, father_name, gender)`
- Never interpolate a nullable into a displayed string. Build the line from the
  parts that exist, as `graduate_reports_screen.dart` does.

**Required.** Every کارگزاری shows the correct name of the فاضل or فاضلہ it
belongs to — on their own screen, the مربی's screen and the منتظم's screen —
and is linked to the right account.

### 1.4 `Null` instead of the name on community board comments

**Symptom.** عوامی تبصرے on the کمیونٹی بورڈ appear without their author's
name.

**Read this before fixing it — the obvious fix is the wrong one.** The feed
goes through `community_feed()`, a SECURITY DEFINER function that returns
`author_name` as a plain column. The comment list is read **straight from the
`community_comments` table** instead. A client-side join to `profiles` cannot
work there, because RLS on `profiles` correctly stops a فاضل from reading
another فاضل's profile row — so the join returns null, exactly as the policy
intends.

**Required.** Serve comments the way the feed is served: through a SECURITY
DEFINER function returning only safe columns, `author_name` and `author_role`
among them. **Do not loosen the `profiles` SELECT policy to make the join
work** — that would expose every profile to every signed-in user in order to
display a name. Return the name through the function instead.

**Still forbidden:** that function must never return a نجی جائزہ, an email
address, a رقم التسجیل, or any other private column. عوامی تبصرہ and نجی جائزہ
stay strictly separate.

---

# PHASE 2 — کارگزاری and the مربی's جائزہ, end to end

Most of this exists. Complete the chain and make each step visible to the right
person.

1. A فاضل or فاضلہ submits a کارگزاری; the record is stored and their assigned
   مربی can see it.
2. The مربی reviews it: a written تبصرہ, a note of قابلِ تحسین work, and
   رہنمائی for further improvement. No score of any kind.
3. On submission the جائزہ becomes visible to that فاضل or فاضلہ, and they are
   notified through the existing notification system.
4. The منتظم dashboard records the جائزہ — **which مربی reviewed which فاضل or
   فاضلہ's کارگزاری, and when**.
5. From the منتظم dashboard, any کارگزاری can be opened in full: its details,
   its evidence, and the مربی's تبصرہ and جائزہ.

**Enforce in RLS:** a فاضل may read their own کارگزاری and جائزہ and nobody
else's; a مربی only those of the فضلاء و فاضلات assigned to them; a منتظم all
of them. A فاضل must not be able to read another فاضل's نجی جائزہ. Prove this
with a policy probe, not by looking at the UI.

---

# PHASE 3 — اعزازات for فضلاء و فاضلات

Four tiers, in this order:

1. 🏅 **قابلِ قدر پیش رفت**
2. 🏅 **نمایاں کارکردگی**
3. 🏅 **امتیازی خدمت**
4. 🏅 **مثالی اثر**

**These are not scores and must never behave like them.** They are given for
the quality of practical work, the effort behind it, positive results and
social effect — never on numbers, percentages, averages or comparison between
people. There is no ranking, no leaderboard and no automatic award: a person is
proposed for a tier directly, and any tier may be proposed at any time without
passing through the ones below it.

Every اعزاز also records its **شعبۂ خدمت**:

- علمی و تحقیقی کاوش
- مؤثر تدریسی خدمت
- سماجی و دعوتی خدمت
- افراد سازی و ٹیم ورک
- مسجد و مدرسے میں عملی کردار
- تکنیکی مہارت کا استعمال

**Where the شعبۂ خدمت should live.** These six overlap heavily with the four
بنیادی شعبے and twelve ذیلی معیار already in `report_categories`. Before adding
a second list, check whether this is the same taxonomy under another name. One
list the منتظم maintains is far better than two that drift apart. If they
genuinely differ, say why in the report.

Extend the existing `recognitions` table. Do not create a parallel one.

---

# PHASE 4 — How an اعزاز is approved

1. A مربی reviews a فاضل or فاضلہ's practical کارگزاری and **recommends** an
   اعزاز.
2. The recommendation carries the tier, the reason, the notable work, the
   positive results, and the شعبۂ خدمت.
3. It arrives on the منتظم dashboard for approval.
4. The منتظم reviews it and **approves or rejects** it. A rejection may carry a
   reason.
5. On approval the اعزاز appears on that person's profile and they are
   notified.
6. The date, the reason and a تعریفی سند record are stored permanently.
7. The منتظم dashboard shows **زیرِ التوا سفارشات**, **منظور شدہ اعزازات** and
   **مسترد شدہ سفارشات** separately.

**Enforce in RLS:** only a مربی may create a recommendation, and only for a
فاضل or فاضلہ assigned to them. Only a منتظم may approve or reject. A فاضل or
فاضلہ must not be able to see a pending or rejected recommendation about
themselves — only an approved اعزاز. Nobody may approve their own
recommendation. Use the existing SECURITY DEFINER + stable error code pattern
(`ADMIN_ONLY`, `MENTOR_ONLY`, …) so the app can show a correct Urdu message.

---

# PHASE 5 — Dashboards and profiles

**منتظم:** open any فاضل or فاضلہ's profile and see, in one place, their
کارگزاریاں, the مربی's جائزے and تبصرے, and their اعزازات.

**مربی:** see the کارگزاری of the فضلاء و فاضلات assigned to them, record a
جائزہ, and send an اعزاز recommendation.

**فاضل / فاضلہ:** see their own submitted کارگزاری, their مربی's جائزہ and
رہنمائی, and their approved اعزازات.

Build these from the screens and providers that already exist. Do not add a
third way to list کارگزاری.

---

# PHASE 6 — Short practical courses

Add short courses in مؤثر تدریس، مسجد و مدرسے میں عملی کردار، دعوت و ابلاغ and
the other related شعبے.

Each course carries a **practical activity**, so what was learned is put into
practice and the resulting کارگزاری can be shared on the کمیونٹی بورڈ.

Build on the existing `activities` catalogue, which already has steps and
per-person progress. A course is a grouping of activities, not a new parallel
system. Do not add scores, or quizzes with marks, or pass/fail.

---

# PHASE 7 — Works on as many Android phones as possible

The application must install and run on old and new Android phones alike,
across every Android version it can technically support.

**Required work:**

- State the current `minSdkVersion` and `targetSdkVersion` and which phones
  that covers. Investigate whether `minSdk` can be lowered, and report honestly
  what each dependency allows — do not lower it and hope.
- Keep shipping per-architecture APKs (`--split-per-abi`) so an arm32 phone
  downloads an arm32 build, and say which file is for which phone.
- Test installation and real use on a low-RAM phone, a phone with little free
  storage, and the oldest supported Android version available. Check sign-in,
  the dashboard, کارگزاری, تبصرے and the other features on each.
- Avoid heavy features that buy little: large bundled assets, animation on long
  lists, full-resolution images loaded into small thumbnails, anything holding
  a long list in memory at once.
- Report APK size per architecture, and cold start time on the slowest device
  tested.

**Be honest about what could not be tested.** If no physical old phone was
available, say so and name what was used instead. Do not describe an emulator
run as a device test.

---

# Deliverables

1. **A root-cause statement for each of the four Phase 1 defects** — what was
   actually wrong, not merely what was changed.
2. All SQL as files I can paste into the Supabase SQL editor myself, each one
   additive, with a comment saying what it changes and what it deliberately
   leaves alone.
3. `flutter analyze` and `flutter test` output.
4. A new APK per architecture, with the build number raised so it installs over
   the one people already have.
5. A final report covering: files changed; migrations applied; how existing
   accounts, roles, passwords and user ids were preserved; which RLS rules were
   proved and how; what was tested; and **everything that is NOT VERIFIED, with
   the reason**.

# Do not

- Rebuild the app, redesign existing screens, or create a parallel reporting,
  award or course system.
- Introduce any score, mark, grade, percentage, ranking or leaderboard.
- Loosen an RLS policy to make a name appear on a screen.
- Expose a نجی جائزہ, email address, رقم التسجیل or password anywhere public.
- Put a service-role key in the Flutter app.
- Delete, reset or recreate any existing account, role or password.
- Claim anything was tested that was not actually run.
