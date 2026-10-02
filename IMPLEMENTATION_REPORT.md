# Implementation report — مدرسہ تربیت ایپ

Post-demo feedback and final updates. Six commits, `e99e292..5dbfacc`,
45 files, +2221 / −977.

**How to read this report.** "Verified" means I ran it and watched the result.
"NOT VERIFIED" means the code is written and reviewed but I did not observe it
working — in almost every case because the Supabase connector was removed from
this session partway through, so I can no longer query the database or sign in
as a real account. Nothing below is described as tested unless it was.

---

## 1. Name

| Where | Now reads |
|---|---|
| Urdu interface, everywhere | مدرسہ تربیت ایپ |
| English / tooling | Madrassa Tarbiat App |
| Android launcher label | مدرسہ تربیت ایپ |
| iOS display name, web title, web manifest | Madrassa Tarbiat App |
| Package id | `pk.madrassa.madrassa_graduate_app` — **unchanged** |

`AppConfig.appNameUrdu` and `AppConfig.appName` are the single source; a test
pins both strings exactly. The package id was deliberately left alone: changing
it makes Android treat the build as a different application, so every installed
copy would be orphaned and would need uninstalling by hand.

MADRASSA.PK is still the organisation, and is not used as the app's name.

**Verified**: `flutter test` asserts the two strings; I read each platform file.

---

## 2. Grammar — فاضل / فضلاء / فاضلہ / فاضلات

Done by meaning, not by find-and-replace. Singular and plural are now separate
strings, so a count can never read «کل فاضل».

| Meaning | String |
|---|---|
| one male graduate | فاضل |
| one female graduate | فاضلہ |
| many male | فضلاء |
| many female | فاضلات |
| mixed / unknown | فضلاء و فاضلات |

So: «کل فضلاء», «کل فاضلات», «کل فضلاء و فاضلات», «میرے فضلاء و فاضلات». Where
both singular forms appear together, فاضل is written first — a test enforces
the order and fails on «فاضلہ / فاضل».

The admin dashboard picks the male, female or mixed wording from which figure
it is showing, so the three cards read correctly rather than all saying the
same thing.

**Verified**: the ordering and plural tests pass.

---

## 3. مہمان (Guest) removed

- The `guest` value is gone from `AppRole`; three roles remain.
- `lib/features/guest/` deleted (2 files), its route deleted, its dashboard
  deleted.
- Database side, in `20261001000008`: `public_statistics` and
  `public_activity_breakdown` dropped, `private.is_guest()` dropped, the
  `profiles update own` policy recreated without it, `create_staff_invite`
  refuses a guest invitation, and `admin_dashboard_statistics()` no longer
  returns a `guests` count.
- A test asserts that only three roles exist and that nothing routes to a
  guest area.

Postgres cannot drop a value from an enum in use, so `app_role` may still
*contain* the label `guest` while nothing can obtain it: no policy grants it,
no screen offers it, and the invitation function rejects it.

**Verified in the app**: yes, by test and by reading every reference.
**NOT VERIFIED in the database**: the migration ran successfully on your
project (you reported "success!"), but I could not query afterwards to confirm
no `guest` row survives in `user_roles`. Worth one look:

```sql
select role, count(*) from public.user_roles group by role;
```

---

## 4. کارگزاری — four شعبے, twelve معیار

The form asked for its نوعیت in one flat dropdown listing every category. It
now asks in two steps: the بنیادی شعبہ first, then only that شعبہ's three
ذیلی معیار.

| بنیادی شعبہ | ذیلی معیار |
|---|---|
| ذاتی و علمی ترقی | مثبت ذاتی تبدیلی · علمی و تحقیقی سرگرمیاں · تکنیکی مہارتوں کا استعمال |
| مسجد و مدرسہ میں عملی کردار | تدریس میں بہتری · مسجد و مدرسے میں عملی تبدیلی · افراد سازی |
| سماجی و دعوتی کردار | مثبت سماجی کردار · ابلاغ و اثر و رسوخ · اتحاد و تعاون |
| عملی نتائج و اثرات | قابل مشاہدہ نتائج · اثر پذیری · تسلسل |

These are rows in `report_categories`, where the group is the شعبہ. They are
data, not code, so wording can change without a release. The same rows drive
the dashboard's quick access, which is why the two can never offer different
lists.

Nothing else in the reporting path changed: the same `ReportItem`, the same
evidence, repository, review and notification code. A submission must now name
a معیار; a draft may still be saved without one.

Two things the restructure had quietly broken, both fixed here:

- the dashboard's quick-access icons were keyed to the five *old* category keys,
  so all twelve had fallen back to one generic icon. The icon now lives on
  `ReportCategory`, read by both the form and the dashboard.
- the معاشرتی filter still looked for the group `social`, which no longer
  exists; it now looks for `social_dawah`.

**Verified**: analyzer and 25 tests pass; I read the migration's twelve rows
against this table.
**NOT VERIFIED**: that the twelve rows are present in your database and that
no thirteenth stale category remains. One query settles it:

```sql
select group_title, title, sort_order
from public.report_categories
where is_active
order by group_key, sort_order;
```

---

## 5. کمیونٹی بورڈ

- Reachable by every signed-in role, at `/community`, from the graduate and
  mentor dashboards and from the admin management list.
- Shows shared کارگزاری and board posts, newest first, paged.
- A مربی or منتظم may post. A فاضل or فاضلہ may comment, not post — enforced
  in the UI by hiding the action, and in the database by the insert policy.
- A کارگزاری reaches the board only when its owner shares it, one at a time,
  from their own list, after a dialog explaining that other people will see it.
  `reports.shared_at` records that choice and taking it back is one tap.
- An منتظم can hide any post or comment.

**Public and private are separate paths, not one path with a flag.** A عوامی
تبصرہ is a row in `community_comments`. A نجی جائزہ is a row in the evaluation
tables, read by the owner and their مربی only. The board is served by
`community_feed` and `community_karguzari`, which select only the columns the
board may show — the review text is not among them, so the board has no way to
render it even by mistake. The comment screen says so in words as well.

No Follow, Star or Award was added, as instructed. (حوصلہ افزائی /
`recognitions` is the pre-existing admin-granted record, untouched. It is not a
score and not a ranking.)

**Verified in the app**: the board, item and new-post screens compile, the
routes resolve, and the role gate on نئی پوسٹ reads `session.isMentor ||
session.isAdmin`.
**NOT VERIFIED**: the board against live data, and the RLS policies on
`community_posts` / `community_comments`. I could not sign in to try.

A regression I introduced earlier this phase and have now fixed: the three
community routes were lost when I removed duplicated blocks from the router,
leaving the board's three entry points pointing at nothing. They are restored
and the fix is in `ac143ef`.

---

## 6. No scores, marks, grades or ranking

- `EvaluationItem` no longer has `score`, `maxScore` or `ratio`.
- The mentor's review no longer writes `evaluation_scores`; the slider step is
  gone and the review is four steps of written guidance.
- The admin معیارات screen, the `StandardItem` model, its provider and its
  repository method are deleted.
- No leaderboard, ranking or points exist anywhere.

One thing I kept, and want to flag rather than decide silently: a practical
activity still shows «٣ / ١٠» — how many of its steps are done. That is
progress through a checklist, not a mark. Say the word and it goes.

**Verified**: analyzer clean after the removals; I grepped for score, mark,
grade and ratio across `lib/`.

---

## 7. Email confirmation — "This site can't be reached"

**What was actually wrong.** The confirmation message never linked to the app.
It linked to Supabase, which verified the token — *the address was confirmed at
that moment* — and then redirected the browser to the project's Site URL, still
Supabase's default `http://localhost:3000`. A phone has no such site, so the
browser reported that the site could not be reached, and the reader had every
reason to think signing up had failed.

**The fix.** The app now registers `pk.madrassa.tarbiat://auth-callback`:
`android:scheme` with the BROWSABLE category in the Android manifest, and
`CFBundleURLTypes` in `ios/Runner/Info.plist`. Both signups and the password
reset ask Supabase to redirect there, so Android and iOS hand the link back to
the app. The string is `AppConfig.authRedirectUrl`, and a test fails if the
three files disagree.

Nothing writes `email_confirmed_at` or `confirmed_at`. The link is still what
confirms the address, and a test now refuses either column anywhere in `lib/`.

**One step is yours** — it is a dashboard setting, not a migration.
`supabase/DASHBOARD_SETTINGS.md` has it in full; in short, under
**Authentication → URL Configuration**, set both Site URL and Redirect URLs to
`pk.madrassa.tarbiat://auth-callback`. Until that is set, Supabase refuses to
redirect to the scheme and the old localhost behaviour continues.

Two consequences worth knowing:

- A sign-in that fails because the address is unconfirmed now offers
  «تصدیقی پیغام دوبارہ بھیجیں». It appears only for that failure, because
  Supabase refuses to resend for an address already confirmed.
- پاس ورڈ بھول گئے؟ now leads somewhere. The link signs the account in, so
  before this it landed on a dashboard with the password still unchanged; there
  is now a screen that asks for the new one. This was not in your list — I
  added it because the button was already on screen and led nowhere.

**NOT VERIFIED**: no email was sent or opened in this session. I could not test
the deep link end to end without a device and your dashboard change. The three
files agreeing is verified; the round trip is not.

---

## 8. Upload note for a فاضلہ

The upload screen now carries, above the list,
«براہِ کرم کام کی تصاویر اپ لوڈ کریں، اپنی تصاویر نہیں۔» — placed above so it
is read on the way to the upload button rather than after it.

It shows for an account whose profile records `gender = 'female'`, which is how
you specified it. The profile already stored gender and the session already
selected every column; `AppUser` simply keeps it now instead of discarding it.
If you would rather everyone saw the note, it is a one-line change.

**NOT VERIFIED**: I could not sign in as a فاضلہ to see it render.

---

## 9. Reports section removed from the graduate dashboard

The separate summary-cards section is gone from the فاضل/فاضلہ dashboard;
کارگزاری is reached through quick access, which is now the only path and so
cannot disagree with itself.

**Verified**: the widget is deleted and nothing references it.

---

## 10. Everything enforced in the database, not only the UI

This was the instruction I treated as binding on every item above: the UI hides
things for the reader's sake, and the database refuses them for real.

- Self-write policies also require the matching role. Before this, owning a row
  was enough to write it, which meant an account with no graduate role could
  still have written کارگزاری, evidence and profile edits.
- `institutes` INSERT restricted.
- The board's reads go through `community_feed` / `community_karguzari`, which
  return only safe columns.
- Role-giving functions are SECURITY DEFINER and raise stable codes
  (`ADMIN_ONLY`, `INVITE_INVALID`) that the app translates to Urdu.
- Signup never sends a role; the database decides it.

**Verified up to commit `e99e292`**: every policy was probe-tested with
`set_config('request.jwt.claims')` + `set local role`, rolled back.
**NOT VERIFIED from `e53084a` onward** — the community tables and the category
rows. The Supabase connector was removed from this session before that
migration, so those policies have been written and reviewed but never probed.
If you want them proven, that is the first thing to do with a connector
restored.

---

## 11. Data and functionality preserved

No table was dropped. The two things removed from the database were the guest
*views* and the guest helper function, plus the scoring write path — no rows of
anyone's work. Reports, evidence, assignments, activities, recognitions,
notifications and the course register are all as they were, and the reporting
path still uses the same models and repositories, so existing کارگزاری keep
working with the new two-step picker.

**NOT VERIFIED**: row counts before and after. I had no database access at the
time the migration ran.

---

## 12. Checks that were actually run

| Check | Result |
|---|---|
| `flutter analyze` | **No issues found** |
| `flutter test` | **25 / 25 passed** |
| `flutter build apk --release` | see §13 |

Three new or changed tests this phase: that only three roles exist and nothing
points at a guest area; that each role lands on its own dashboard; that the
three files declaring the email-link scheme agree and that no Dart file touches
`email_confirmed_at`.

**What I could not test, and why.** Signing in as a فاضل, مربی and منتظم and
walking each screen needs either a real account or the Supabase connector.
Earlier in this session I ran the app in a browser pane, but the Flutter canvas
ignores the pane's synthetic pointer events, so I could load screens by URL and
read them — I could not tap anything. Every "NOT VERIFIED" above comes down to
that.

The verification I would ask you to do, in this order:

1. Set the two dashboard URLs (§7), then sign up a throwaway account on a phone
   and open the link. It should open the app, not the browser.
2. Sign in as a فاضل: file one کارگزاری through the two-step picker, share it
   to the board, comment on someone else's.
3. Sign in as a مربی: review that کارگزاری, post to the board, confirm the
   جائزہ is not visible on the board.
4. Sign in as a second فاضل and confirm the first one's جائزہ is not readable.
5. Sign in as منتظم: check the three counts, hide a comment.

---

## 13. APK

Reported below once the build finishes.

---

## 14. Google Play — what is needed before publishing

Nothing here has been published, as instructed. This is the list.

### Blocking

1. **A release signing key.** `android/app/build.gradle.kts` still says
   `signingConfig = signingConfigs.getByName("debug")` — the release build is
   signed with the debug keystore, and Play rejects that outright. You need
   your own keystore, and it must be kept safe: lose it and you can never
   update the app under the same listing.

   ```bash
   keytool -genkey -v -keystore madrassa-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Then `android/key.properties` (git-ignored, never committed) and a
   `signingConfigs.release` block reading it. I have not created the key: it is
   your signing identity, not something a tool should generate for you.

2. **An App Bundle, not an APK.** Play requires `.aab`:
   `flutter build appbundle --release`.

3. **A privacy policy at a public URL.** Required because the app collects
   names, email addresses, gender and uploaded photographs. There is no policy
   text in the app today and I did not invent one.

4. **The Data safety form.** Declare, truthfully: email address and name
   (account management), gender, photos and documents uploaded as evidence,
   all stored on Supabase; whether data is encrypted in transit (it is, HTTPS);
   and whether a user can request deletion.

5. **Target API level.** Play enforces a floor that rises each year. The build
   takes `targetSdk` from the Flutter SDK, so check the current requirement
   before the first upload.

### Needed for the listing

6. App icon 512×512 PNG; feature graphic 1024×500.
7. At least two phone screenshots — more if you want tablet placement.
8. Short description (≤80 chars) and full description (≤4000), in Urdu.
9. Content rating questionnaire.
10. Category, contact email, and the app's audience (this is not a children's
    app, which keeps Families policy out of scope).

### Worth doing first

11. **Decide what the app is for, in Play's terms.** A closed audience of
    فضلاء و فاضلات may be better served by **internal testing** or a
    **closed track** than by a public listing — it keeps the register and the
    board away from the open store while remaining installable by link.
12. Version bump per upload: `version: 1.0.0+1` in `pubspec.yaml`; the `+1`
    is `versionCode` and must rise with every upload.
13. An account-deletion path, which Play now asks about for any app with
    accounts. There is no in-app deletion today.

---

## 15. Known gaps

- Everything in §10 from `e53084a` onward is unprobed. That is the single
  largest gap.
- Evidence previews on the board were deliberately left out; the board shows
  text and the comment thread.
- A locked (submitted) کارگزاری hides its معیار along with the rest of the
  form. The list screen shows it, so nothing is lost, but it reads oddly.
- `karGuzariSummaryProvider` is unused since the summary cards went; harmless,
  but it is dead code.
- No in-app account deletion (see §14.13).
