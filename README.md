# مدرسہ تربیت ایپ

**Madrassa Tarbiat App** — علم سے عمل، عمل سے اثر تک

An Urdu-first, right-to-left Flutter application for tracking the تربیت,
practical activities and کارگزاری of فضلاء و فاضلات, with مربی supervision
and central administration. Backed by Supabase for authentication, data,
storage and realtime.

مدرسہ تربیت ایپ is the application. MADRASSA.PK is the organisation that
runs it; the two are not the same name and the package id
(`pk.madrassa.madrassa_graduate_app`) is unchanged, because changing it would
orphan every installed copy.

---

## Stack

| Layer | Choice |
|---|---|
| UI | Flutter (Material 3), Urdu-first, forced RTL |
| State | Riverpod |
| Routing | GoRouter, with role-aware redirects |
| Backend | Supabase — Auth, Postgres, Storage, Realtime |
| Security | Postgres row level security on every table |

## Running it

The Supabase URL and publishable key have development defaults compiled in, so
the app runs with no extra flags:

```bash
flutter pub get
flutter run -d chrome
```

To point at a different project, override at build time. Dart has no `VITE_`
convention — that prefix belongs to Vite bundlers; the Dart equivalent is a
compile-time constant:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

Release builds:

```bash
flutter build apk --release --split-per-abi   # Android, per architecture
flutter build web --release                   # Web
```

## Architecture

```
lib/
├── core/           config, Urdu strings, theme tokens, routing, utils
├── shared/         models, repositories, Riverpod providers, widget library
└── features/
    ├── auth/       sign in, sign up, session and role loading
    ├── graduate/   dashboard, کارگزاری, evidence, activities, profile
    ├── mentor/      dashboard, assigned فضلاء و فاضلات, جائزہ
    ├── community/   کمیونٹی بورڈ, shared کارگزاری and عوامی تبصرے
    └── admin/       users, roles, wifaqs, institutes, activities
```

A کارگزاری is filed under one of four بنیادی شعبے and then one of that
شعبہ's three ذیلی معیار. Both come from `report_categories`, where the group
is the شعبہ — so the twelve معیار are data, not code, and an منتظم can
change the wording without a release.

Nothing in the application carries a score, a mark, a grade or a ranking. A
جائزہ is the مربی's written guidance; there is no number attached to it, and
no leaderboard anywhere.

The design system lives in `core/theme/` — colours, gradients, spacing, radii
and typography are tokens. Screens never hardcode a brand colour.

All user-facing text is Urdu and lives in `core/constants/app_strings.dart`.

## Roles

Three roles, stored in `public.user_roles` — never as a column on the profile,
because a profile column would let anyone who can edit their own profile grant
themselves administrator.

| Role | Sees |
|---|---|
| `graduate` — فاضل / فاضلہ | only their own records |
| `mentor` — مربی | only فضلاء و فاضلات assigned to them |
| `admin` — منتظم | the whole system |

An منتظم adds another مربی or منتظم by invitation: the database issues a
single-use code, and the signup trigger takes the role from the invitation,
never from anything the client sends.

New signups always receive `graduate`. The role is chosen by the database in
`private.handle_new_user()`, never sent by the client, so an account cannot
request its own privileges. Addresses listed in `private.bootstrap_admins`
receive `admin` instead — that is how the first administrator exists at all.

## Security

Row level security is enabled on every table in the public schema, with
policies for both read and write. A policy for writing one own row also
requires the matching role, so holding a row is not on its own enough to
write it. The helper functions that policies call
(`has_role`, `is_admin`, `is_mentor_of`, `can_view_graduate`) live in the
`private` schema, **not** `public`.

That placement is deliberate. PostgREST exposes only `public` and
`graphql_public`, so a helper in `private` is usable inside a policy but
unreachable over the REST API. When they lived in `public`, anyone holding the
publishable key could call `/rest/v1/rpc/has_role` and probe which accounts
were administrators. Moving one back to `public` reintroduces that hole.

The publishable (anon) key is compiled into the client by design — it is meant
to be public, and row level security is what protects the data. **The
service-role key must never appear in this repository or in any client build.**

Verify the posture at any time — every table must return `[]` for an
anonymous caller:

```bash
curl -s "$URL/rest/v1/profiles?select=*" -H "apikey: $PUBLISHABLE_KEY"
```

## Database

Migrations are in `supabase/migrations/`, applied in order. Tables covering
profiles and roles, the course register, staff invitations, mentor
assignments, activities and per-graduate progress, کارگزاری and its
categories, evidence, جائزہ, the کمیونٹی بورڈ with its عوامی تبصرے,
recognitions, follow-ups and notifications.

The کمیونٹی بورڈ is served by `community_feed` and `community_karguzari`,
which return only the columns the board may show. A نجی جائزہ is not among
them: the private review and the public comment are separate tables read
through separate paths, so the board cannot leak one as the other.

Two storage buckets: `avatars` (public) and `evidence` (private, read through
signed URLs). Nine tables are published to Supabase Realtime.

## Tests

```bash
flutter test
```

Covers Urdu rendering, global RTL, the brand palette, that protected routes
are unreachable without a session, that the authentication screens can be
backed out of, that each role lands on its own dashboard, that کل and فعال
are counted from different things, and that the three files declaring the
email-link scheme agree.

## Email links

A confirmation or password link goes to Supabase, which verifies the token
and then redirects to `AppConfig.authRedirectUrl` —
`pk.madrassa.tarbiat://auth-callback`, registered in the Android manifest and
the iOS `Info.plist`. That URL must also be listed in the Supabase dashboard
under **Authentication → URL Configuration → Redirect URLs**, and it belongs
in **Site URL** as well. Left at Supabase's default of
`http://localhost:3000` the phone has nothing to open and reports that the
site cannot be reached, even though the address was confirmed.

An address is confirmed by opening its link. Nothing in the application
writes `email_confirmed_at`, and a test refuses that column anywhere in
`lib/`.
