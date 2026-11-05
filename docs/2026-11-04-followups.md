# Follow-ups after email sign-in (2026-11-04)

> **Temporary file.** Work through the items below, tick them off, and **delete this file** once every item is done or moved elsewhere. Background: `docs/superpowers/specs/2026-10-27-multi-tenant-production-design.md` (rev. 3) and `CLAUDE.md` → Backend → "How the app reaches a tenant".

## Context for a fresh session

- App: `D:\PROJECT\getx_project` (Flutter, GetX). Backend: `D:\laravel-project\MasterSystemBackend` (Laravel, `stancl/tenancy`, branch `check_app`). Web: `D:\PROJECT\MasterSystemFrontEnd-V2`.
- Email sign-in (workspace mode) is built and verified on a device: central `workspace/sign-in` → `sign-in/handoff` on the company host → `GET /me`; the company chooser was tried by hand.
- Dev runs without a tunnel: `adb reverse tcp:80 tcp:80` + `--dart-define-from-file=env/dev-workspace.json` (VS Code: "Dev · workspace (email sign-in, USB)", which runs `adb reverse` itself through `tool/flutter_adb_reverse.bat`).
- Backend tenant HTTP tests only pass with `APP_URL=http://mc.mastersystem.test php artisan test …` on this machine.
- Dev tenant `mc` = `1c1df3fd-b3b9-4d58-a81d-aaa616d04e93` (`mc.mastersystembackend.test`); second tenant used for tests: `mtp` = `961934d1-beed-4979-9a17-6348e757b52e`.

## 1. Must do before the first workspace release

- [x] **Done 2026-11-04:** `sign-in/handoff` + `/check` moved to their own limiter `tenant-handoff` (60/min per address, 10/min per account resolved from the handoff row, without `throttle:api`); test `tests/Feature/Security/TenantHandoffLimitTest.php`. Backend change left uncommitted.
- [x] **Handoff throttle — 5 per minute per IP.** `POST /sign-in/handoff` sits in the `throttle:tenant-login` group (`routes/tenant_api.php`, limiter `tenant-login` in `app/Providers/RouteServiceProvider.php`: `Limit::perMinute(5)` by `ClientIpBucket`). A warehouse usually reaches the server from one IP (NAT), so more than 5 people signing in within a minute (shift start) get "Too many login attempts." after the central sign-in already succeeded. Not a regression (`/login` has the same limit), but email sign-in makes it the bottleneck. Options: a separate, looser limiter for `sign-in/handoff` (the single-use 60 s token is already the credential), or key it by token/user instead of IP. Add a backend test.
- [ ] **Production domain + HTTPS.** Central host `app.<domain>`, wildcard DNS + wildcard TLS for `*.<domain>`, `admin.` record; create `env/prod.json` from `env/prod.example.json`. Spec §8. Decide: the domain, and the hosting provider (decides how wildcard TLS is issued).
- [ ] **Backend production config.** `.env`: `APP_URL`, `CENTRAL_APP_DOMAINS=app.<domain>`, `CENTRAL_ADMIN_DOMAINS=admin.<domain>`; every tenant has a `<slug>.<domain>` domain. Spec §7.
- [ ] **Migrate every other server.** `php artisan migrate` (central: `domains.is_primary`) then `php artisan deploy:sync-tenants` (tenant migrations + every re-runnable provisioning seeder, per tenant; `--dry-run` prints the plan). The `idempotency_keys` tenant table (migration `2026_11_03_100000_create_idempotency_keys_table`) exists on dev only; the app sends `Idempotency-Key` on receive / outflow / work-order issue, and the `idempotent` middleware needs the table.

## 2. Should fix

- [x] **Done 2026-11-05:** `domains.is_primary` (central migration `2026_11_05_000001_add_is_primary_to_domains_table`, backfilled with each tenant's oldest domain; `mc` → `mc.mastersystembackend.test`), `App\Models\Domain` keeps one primary per tenant, `Tenant::primaryDomain()` replaces every `domains->first()` host read (sign-in `api_host`, mails, approval/report/asset links, impersonation). Tests `tests/Feature/Central/PrimaryDomainTest.php` + `WorkspaceSignInTest::api_host_is_the_primary_domain_not_the_first_row`. Backend change left uncommitted; other servers need `php artisan migrate`.
- [x] **`api_host` depends on the order of the `domains` rows.** `WorkspaceSignInService::describe()` uses `$tenant->domains->first()`. Tenant `mc` has `mc.mastersystembackend.test` (id 1) and `allowing-toucan-ghastly.ngrok-free.app` (id 8, **must stay — the Accurate webhook uses it**). If the order changes, the app is sent to the ngrok host. Fix in the backend: an explicit primary domain (column/flag, or prefer a domain under the configured tenant suffix), with a test.
- [ ] **Kept on purpose (2026-11-05, user's call) — delete before any non-dev data lands:** the dev account `choose.tester@example.com` (weak password, exists on `mc` user #16 and `mtp` user #1, role admin) once the chooser no longer needs trying; check the central mirror `central_tenant_users` loses both rows.
- [x] **Confirm the backend commit is pushed** (2026-11-05: `503225d6` is on `origin/check_app`): `POST /login` returns `must_change_password` (`app/Services/User/UserService.php`, test in `tests/Feature/Auth/TenantAuthTest.php`).

## 3. Minor / later

- [x] **Decided 2026-11-05: release note, no migration** — recorded in the spec §11 decision 4 (with the release-note sentence).
- [x] **Drafts from a direct build are not read by a workspace build.** Direct mode stores drafts under the plain scope, workspace mode under `<tenantId>/<scope>` (`DraftService.keyFor`). A user moving from a direct to a workspace build loses unsent drafts (they are signed out once anyway). Mention it in the release notes, or migrate plain scopes into the first company signed in to.
- [x] **Done 2026-11-05:** multipart requests carry the session they started in; the request modifier drops one whose session changed (`SessionChangedException`), so it is never sent. Test `test/helpers/multipart_session_test.dart`.
- [x] **Sign-out during a proof upload.** For a multipart body GetConnect awaits `body.toBytes()` before it builds the URL, so a sign-out in that window sends the upload to the central host; it fails with an error, nothing leaks. Very unlikely; leave unless it shows up.
- [x] **Done 2026-11-05:** `login_test` has two chooser tests (tag `chooser`) behind `TEST_MULTI_EMAIL` (+ `TEST_MULTI_PASSWORD`), run with the dedicated dev account `e2e.multi+1c1df3fd@example.com` (`mc` #17, `mtp` #2, admin) — 2/2 passed on device. `choose.tester` stays anyway (user's call, 2026-11-05) — do not delete it.
- [x] **Patrol does not cover the company chooser.** Only the widget test `test/widgets/company_chooser_sheet_test.dart` and a manual run. Add a Patrol test with an e2e account that belongs to two companies (the harness currently fails on such an account on purpose — `_signInByEmail` in `patrol_test/common/harness.dart`).
- [ ] **Deferred 2026-11-05 (user's call): leave as is for now.**
- [ ] **Patrol's Kotlin Gradle Plugin warning.** `patrol` 4.10.0 applies KGP; a future Flutter will refuse it. `patrol` 4.11.0 exists — try it when upgrading Flutter (needs a matching `patrol_cli`, check Patrol's compatibility table), then rerun `login_test` + `home_test` on a device.

## 4. Backend verification

- [x] **`WorkOrderCancelMaterialsTest`** — 2026-11-05: 14/14 passed (108 assertions).
- [x] **The full backend suite** — all green on the night of 2026-11-04 (reported by the user). The 2026-11-05 primary-domain change came after it and was covered by focused runs (`PrimaryDomainTest`, `WorkspaceSignInTest`, 19 files on the changed call sites).

## Suggested order

2 (delete the dev account) → 4 (backend verification) → production items when the domain and hosting are decided → 3 as convenient.
