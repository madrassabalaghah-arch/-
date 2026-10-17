# Report — نام / ولدیت, رقم التسجیل, English numerals

Commit `817fa4a`. Analyzer clean, 28/28 tests pass.

**What "verified" means here.** I ran the analyzer and the test suite and read
the output. I have no Supabase connector in this session and no device, so I
could not sign in, create an account, or query the database after you applied
the migration. Everything below that depends on the live system is marked
accordingly, and none of it is described as tested.

---

## 1. What was actually wrong

Not the login. Signing in is email + password and never looks at a name, so no
existing account's ability to log in was ever at stake and the authentication
method is unchanged.

Account **creation** was the fault. Two places compared the name typed against
the register for exact equality — `private.handle_new_user()` and
`public.verify_course_registration()`:

```sql
private.name_key(v_full_name) <> r.name_key
```

The sign-up form asked for «نام مع ولدیت» in **one** field; the register holds
**one** `full_name` column. Whichever shape that column happened to hold,
anyone who typed the other shape was refused. Typing the name alone worked for
the people who complained, which told us their rows hold the name without
ولدیت.

Your query 3 showed the register is not consistent about this at all:

| words in `full_name` | rows | claimed |
|---|---|---|
| 1 | 32 | 0 |
| 2 | 256 | 3 |
| 3 | 86 | 3 |
| 4 | 15 | 1 |
| 5 | 3 | 0 |
| 6 | 1 | 0 |

393 rows, 7 claimed. With 256 rows holding two words, no single shape could be
demanded of the person signing up — which is why the fix forgives the shape
rather than picking one.

---

## 2. Files and components changed

| Component | File | Change |
|---|---|---|
| Sign-up form | [sign_up_screen.dart](lib/features/auth/presentation/sign_up_screen.dart) | «نام» and «ولدیت» as separate fields; ولدیت optional; both sent to the check and to signup |
| Auth data | [auth_repository.dart](lib/features/auth/data/auth_repository.dart) | `signUp` takes `fatherName` → metadata `father_name` |
| Session | [auth_providers.dart](lib/features/auth/application/auth_providers.dart) | threads `fatherName` |
| Register data | [course_repository.dart](lib/features/auth/data/course_repository.dart) | `verify` sends `p_father_name`; `addParticipant` writes `father_name`; `CandidateRow` carries it |
| Register model | [course_participant.dart](lib/shared/models/course_participant.dart) | `CourseParticipant.fatherName` |
| CSV importer | [participant_file.dart](lib/features/admin/presentation/workshop/participant_file.dart) | optional «ولدیت» / «والد کا نام» / «ولد» column |
| Admin form | [admin_add_participant_screen.dart](lib/features/admin/presentation/workshop/admin_add_participant_screen.dart) | ولدیت field |
| Strings | [app_strings.dart](lib/core/constants/app_strings.dart) | «نام», «ولدیت»; nine `رقم التسجیل`; phone hint in Latin digits |
| Numerals | [urdu_numbers.dart](lib/core/utils/urdu_numbers.dart) | `convert()` folds Urdu digits **to** Latin |
| Dates | [urdu_dates.dart](lib/shared/models/urdu_dates.dart) | doc only — digits already came from `UrduNumbers` |
| Tests | [widget_test.dart](test/widget_test.dart) | three new cases |

**The profile editor needed no change.** `profiles` already had `full_name` and
`father_name`, and the editor already read and wrote both — only the label
changed, «والد کا نام» → «ولدیت». No new profile column was created.

### رقم التسجیل

The string in the code was `رقمِ تسجیل`, with a kasra — not the `رقم تسجیل` you
searched for, which is why a plain find-and-replace would have missed all nine.
Nine visible strings and six doc comments now read **رقم التسجیل**. A test
fails if any constant holds the old spelling.

No identifier changed: `registration_number`, `registrationNumber` and every
stored value are untouched. The importer still accepts `رقم تسجیل`,
`رقم التسجیل` and `رقمِ تسجیل` as column headings — removing an alias would
break files the organisation already holds.

> Note on your §5: that bullet contradicted itself about the target wording. I
> took §2 at face value — the visible label is **رقم التسجیل**.

### English numerals

One utility decides this. `UrduNumbers.convert()` was the only place digits
were translated, and `fromInt`, `percent`, `ratio` and every method of
`UrduDates` route through it — so counts, dates, file sizes, step ratios,
badges, notifications and reports all changed without a single call site being
edited.

It **folds** rather than passing through: an Urdu digit arriving from stored
data is now shown in Latin too, so the display is consistent whatever the
database holds. Urdu labels, month names and the RTL layout are untouched.

Input-side folding was deliberately left alone —
[participant_file.dart:230](lib/features/admin/presentation/workshop/participant_file.dart:230)
still accepts Urdu digits in imported files, and
[reference_repository.dart:84](lib/shared/data/reference_repository.dart:84)
still folds them for matching. Both read data rather than display it. Nothing
parses a formatted string back into a number, so no calculation is affected.

---

## 3. Database migration

One file, `20261010000009_separate_name_and_father_name.sql`, which you
applied.

1. `alter table public.course_participants add column if not exists father_name text`
   — nullable, no default, **no backfill**.
2. `private.name_matches(p_name, p_father, r)` — the matching rule, in one
   place, called by both the trigger and the RPC so the courtesy check and the
   enforcement cannot drift apart. It accepts:
   - the register holding the name alone
   - both names, in the order the form asks
   - both names, the other way round
   - both names with «ولد», «بن» or «ولدیت» written between them
   - each name matching its own column, where the register has both
3. `private.handle_new_user()` restated from `20260922000006`, otherwise
   unchanged, now calling that helper and writing `father_name` onto the
   profile. It still raises `REGISTRATION_NAME_MISMATCH`, so the Urdu message
   the app already showed for that code keeps working.
4. `public.verify_course_registration()` gains a defaulted `p_father_name`.

**Every branch is an exact equality.** A prefix match was in the plan and I
removed it once your query 3 arrived: with 256 two-word rows, accepting a
leading token would let anyone holding someone else's رقم التسجیل claim it by
typing one word. The check is loosened as to the **shape** of the name only,
never as to how much of it must be known. `name_matches` is also evaluated
against the single row already found by رقم التسجیل, so a looser name rule
cannot widen the search to anybody else's record.

Two things worth knowing about how it was written:

- The RPC was **dropped and recreated**, not replaced: `CREATE OR REPLACE`
  cannot change a parameter list, and a second overload would have made the
  existing three-argument call ambiguous and fail. The new parameter is
  defaulted, so **the APK already in people's hands keeps working** — it sends
  three named arguments and still resolves.
- A drop discards a function's grants, so `execute` is re-granted to `anon` and
  `authenticated` at the end of the file. Without that line, signup
  verification would have broken for anonymous callers.

`name_key` is a stored generated column over `full_name` alone — your query 2
confirmed it — so adding `father_name` cannot disturb it and no recomputation
was needed.

---

## 4. Existing account compatibility

How it is preserved, by construction:

- The trigger fires **only on `auth.users` INSERT**. It cannot run for anyone
  already registered.
- The migration contains **no UPDATE or DELETE against `auth.users`,
  `profiles` or `user_roles`**. Its only data-changing statement is
  `add column`. No password, email, user id, role, session, policy or foreign
  key is written.
- The new column is nullable with no default and is **not backfilled**.
  Splitting an existing combined name would mean guessing where the name ends,
  and a wrong guess is worse than an empty field. ولدیت stays empty until its
  owner fills it in, which the profile editor already allows.
- No existing column was dropped or renamed. No auth user was created, deleted
  or altered. Nothing writes `email_confirmed_at`, and no password was changed
  through SQL.
- Old APKs keep verifying, per §3.

**One deliberate behaviour change, for new signups only.** Previously the
profile's name was always taken from the register (`v_full_name :=
r.full_name`). Now, when the register cannot tell the two names apart, the pair
**as typed** is kept — the match has already proved it agrees with the
register, and only the person can say which part of a combined name is the
ولدیت. Where the register does have both columns, the register still wins. No
existing profile is rewritten.

---

## 5. What was tested, and what was not

**Executed, output read:**

- `flutter analyze` — no issues.
- `flutter test` — 28/28, including three new cases: the importer reads a
  «ولدیت» column and still imports a file that has none; numerals are Latin
  (`fromInt(2026) == '2026'`, `convert('۱۲۳') == '123'`, a date keeps «جنوری»
  and carries no Urdu digit); no `AppStrings` constant holds an Urdu digit or
  the old `رقمِ تسجیل`, and the three labels read «نام», «ولدیت»,
  «رقم التسجیل».

**NOT VERIFIED — no login or signup scenario was executed.** I could not sign
in, create an account, or query the database. Specifically unverified: that the
migration applied cleanly, that `name_matches` returns true for a real affected
row, that an existing فاضل / مربی / منتظم can still sign in, and that the
counts are unchanged.

Please run these. The first two are the point of the whole change.

1. **The reported case.** Pick a رقم التسجیل whose row holds a one-word name
   and, on a build 3 APK, sign up typing نام **and** ولدیت. This is what failed.
2. **The other shape.** A row holding two words: type نام and ولدیت matching
   the two parts. Then try نام alone.
3. **A wrong name is still refused** — «درج کردہ نام ہمارے ریکارڈ سے مطابقت
   نہیں رکھتا۔»
4. **An existing فاضل, مربی and منتظم each sign in** with their current
   password and reach their own dashboard. Nothing asks them to register again.
5. **Nothing moved.** You have real before-values from query 3 — 393 register
   rows, 7 claimed:

```sql
select count(*) as rows, count(father_name) as with_father,
       sum(case when account_created then 1 else 0 end) as claimed
from public.course_participants;     -- expect 393, 0, 7
select count(*) from auth.users;
select role, count(*) from public.user_roles group by role;
```

6. **Numerals and layout** — dashboard counts, a کارگزاری date, a file size, a
   notification and the پیش رفت ratio all read 0–9, still right-to-left.

The migration's own footer carries two `name_matches` probes you can run
against a real row.

---

## 6. Remaining issues

- **Everything in §5's second list.** That is the largest gap, and it is the
  same gap as last time: no connector, no device.
- **Some people may still be blocked.** If a register row holds the name in a
  shape none of the five branches match — a middle name the person omits,
  tokens in an order nobody would guess — they stay refused. That is on
  purpose: the alternative is guessing, and the remedy is an منتظم correcting
  that one register row, which the admin screens already allow.
- **The register itself is still inconsistent.** 32 one-word, 256 two-word and
  86 three-word values in a column labelled «نام مع ولدیت». The new importer
  column means next year's list can be clean; the 393 existing rows stay as
  they are until someone chooses to correct them by hand.
- **Build 3 is required** for the app-side fix to reach anyone. Build 2,
  already distributed, still verifies against the new RPC but still asks for
  one combined name.
