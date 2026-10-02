# Supabase dashboard settings

Two settings live in the Supabase dashboard rather than in a migration, so
they cannot be applied from the repository. Both concern email links.

Project: `dvfaavutgxzuffninxpd`

---

## 1. URL configuration — the fix for "This site can't be reached"

**Authentication → URL Configuration**

| Field | Value to set |
|---|---|
| Site URL | `pk.madrassa.tarbiat://auth-callback` |
| Redirect URLs | `pk.madrassa.tarbiat://auth-callback` |

Add the same value a second time as `pk.madrassa.tarbiat://auth-callback/*`
if the dashboard asks for a pattern.

### Why

A confirmation message does not link to the app. It links to Supabase:

```
https://dvfaavutgxzuffninxpd.supabase.co/auth/v1/verify?token=…&type=signup&redirect_to=<Site URL>
```

Supabase verifies the token — this is the moment the address is actually
confirmed — and then redirects the browser to `redirect_to`. Left at the
default `http://localhost:3000`, the phone has no such site, so the browser
shows **"This site can't be reached"**. The address was confirmed a moment
earlier, but the reader is given every reason to believe it failed.

With the value above, Android and iOS hand the link back to مدرسہ تربیت ایپ,
because the app registers that scheme — `android:scheme="pk.madrassa.tarbiat"`
in `android/app/src/main/AndroidManifest.xml` and `CFBundleURLTypes` in
`ios/Runner/Info.plist`. The string itself is `AppConfig.authRedirectUrl`, and
a test fails if the three files disagree.

This applies to the password link as well: it signs the account in, and the
app then asks for the new password.

> These settings only affect links sent **after** the change. A message
> already sitting in someone's inbox still carries the old `redirect_to`.

---

## 2. Email confirmation itself

**Authentication → Providers → Email**

Keep **Confirm email** on. The address is confirmed by opening the link and by
nothing else — no part of the app or of these migrations writes
`email_confirmed_at` or `confirmed_at`.

If confirmation is deliberately turned off for a pilot, accounts are usable
immediately and the link stops mattering; turning it back on later does not
retroactively unconfirm anyone.

### Rate limits

**Authentication → Rate Limits** caps confirmation messages per hour, and the
built-in sender is meant for development only. Hitting the cap returns
`over_request_rate_limit`, which the app shows as
«بہت زیادہ کوششیں۔ کچھ دیر بعد دوبارہ کوشش کریں۔». For real use, configure a
custom sender under **Project Settings → Authentication → SMTP Settings**.

---

## What is already in the migrations

Everything else — tables, policies, functions, the twelve کارگزاری معیار, the
کمیونٹی بورڈ — is in `supabase/migrations/`, applied in filename order. The
latest is `20261001000008_community_board_and_categories.sql`.
