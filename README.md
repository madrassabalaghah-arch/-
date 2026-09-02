# کارواں فضلاء مدرسہ ڈاٹ پی کے

**MADRASSA.PK Graduate Platform** — علم سے عمل، عمل سے اثر تک

An Urdu-first, right-to-left Flutter application for tracking the training,
practical activities and performance reports of madrassa graduates, with
mentor supervision and central administration. Backed by Supabase for
authentication, data, storage and realtime.

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
    ├── graduate/   dashboard, reports, evidence, activities, profile
    ├── mentor/     dashboard, assigned graduates, reviews, evaluations
    └── admin/      users, roles, wifaqs, institutes, activities, standards
```

The design system lives in `core/theme/` — colours, gradients, spacing, radii
and typography are tokens. Screens never hardcode a brand colour.

All user-facing text is Urdu and lives in `core/constants/app_strings.dart`.

## Roles

Three roles, stored in `public.user_roles` — never as a column on the profile,
because a profile column would let anyone who can edit their own profile grant
themselves administrator.

| Role | Sees |
|---|---|
| `graduate` — فاضلہ / فاضل | only their own records |
| `mentor` — مربی | only graduates assigned to them |
| `admin` — منتظم | the whole system |

New signups always receive `graduate`. The role is chosen by the database in
`private.handle_new_user()`, never sent by the client, so an account cannot
request its own privileges. Addresses listed in `private.bootstrap_admins`
receive `admin` instead — that is how the first administrator exists at all.

## Security

Row level security is enabled on all 19 public tables, with policies for both
read and write. The helper functions that policies call
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

Migrations are in `supabase/migrations/`. Nineteen tables covering profiles and
roles, mentor assignments, activities and per-graduate progress, reports,
evidence, evaluations and their per-standard scores, recognitions, follow-ups
and notifications.

Two storage buckets: `avatars` (public) and `evidence` (private, read through
signed URLs). Nine tables are published to Supabase Realtime.

## Tests

```bash
flutter test
```

Covers Urdu rendering, global RTL, the brand palette, that protected routes are
unreachable without a session, and that the authentication screens can be
backed out of.
