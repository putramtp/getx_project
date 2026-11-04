# Spec: Email Sign-In & Multi-Tenant Hosts (Mobile)

- **Created:** 2026-10-27 · **Revised:** 2026-11-04 (rev. 3 — as built)
- **Status:** §12 steps 1–7 **implemented and verified on a device** (2026-11-04, not committed yet). Remaining: step 8 — production infrastructure and backend configuration (§7–8) before the first workspace release.
- **Scope:** `getx_project` (Flutter). The backend (`D:\laravel-project\MasterSystemBackend`) needed **no code change** for this: every endpoint already existed and is what the web frontend (`D:\PROJECT\MasterSystemFrontEnd-V2`) uses.

**Revision history**
- **rev. 1 (2026-10-27)** — first draft.
- **rev. 2 (2026-11-04)** — roles/user from `GET /me` (`/user/currentDetail` had been removed from the app); dev **without ngrok** through `adb reverse` + a `Host` header; the ngrok domain kept for the Accurate webhook.
- **rev. 3 (2026-11-04)** — as built: real file names, where the implementation differs from rev. 2 (marked **As built** below), decisions taken (§11), test results (§10).

## 1. Background

Before this change the app called **one** base URL baked in at build time (`AppConfig.apiBaseUrl`, with an ngrok fallback in code) and signed in with `POST /login` on that host.

The backend uses `stancl/tenancy` with `InitializeTenancyByDomain`: **the tenant is chosen by the `Host` of the request** (`<tenant>.<domain>/api/...`, matched against the central `domains` table); each company has its own database, and a token only works on its own company's host. One static URL meant one tenant per APK.

The web frontend has no baked-in URL: the API host is the page's own host (`src/api/index.jsx` → `apiHostFor()`), and its email-first sign-in (`CompanySignIn.jsx` → `SignInHandoff.jsx`) moves the user from the central host to their company's host. The app now does the same.

## 2. Goals

1. **One APK for every tenant.** A new tenant needs no new build.
2. Users **never type a company name** — email + password only, as on the web.
3. A release build knows **one URL: the central API**.
4. Dev and Patrol run **without ngrok**; no ngrok/dev URL ships in a release build.

**Non-goals:** iOS release pipeline, a custom domain per tenant (works, but DNS/TLS is per domain), a change-password screen (the app points to the web).

## 3. Flow (backend, unchanged)

```
App ──POST {CENTRAL}/api/workspace/sign-in {email, password[, tenant_id]}──▶ Central
      ◀── mode=handoff: {tenant{id,name,host,api_host}, handoff_token, expires_in: 60}
      ◀── mode=choose : {tenants:[{id,name,host}]}        (the password matches in >1 company)
      ◀── 401 "The email or password is incorrect."       (every refusal, same body)
      ◀── 429 {retry_after}                               (30/min per IP, 20/hour per email)

(choose) → the user picks a company → sign-in again with tenant_id → handoff

App ──POST {scheme}://{api_host}/api/sign-in/handoff {token}──▶ Tenant
      ◀── {data: {token, name, redirect_url}}              (403 + message: used / expired / wrong company / inactive)

App ──GET {api_host}/api/me (Bearer)──▶ Tenant
      ◀── {user{id,name,email,must_change_password}, roles[], permissions[], tenant_id, …}   (no `data` wrapper)

App stores token + api_host → every later request goes to {scheme}://{api_host}/api
```

Backend references:
- `routes/central_app_api.php` → `WorkspaceSignInController::signIn` → `App\Services\Central\WorkspaceSignInService` (`matchCompanies()`, `describe()`).
- `routes/tenant_api.php` → `PassportAuthController::signInHandoff` → `SignInHandoffService::exchange` (single use, 60 s TTL, must be redeemed on the right tenant host; throttled with the login routes).
- `GET /me` → `UserContextController` → `UserContextService::getContext` (reachable while a password change is owed: `withoutMiddleware(['subscription.active', 'password.changed'])`).
- Forgot password: `POST {CENTRAL}/api/workspace/forgot-password {email}` — mails every company that has the email; always the same answer.
- Logout: `POST {api_host}/api/logout` revokes **and deletes** the token row.

Differences from the old `/login`:
- `/login` takes **username or email**; `workspace/sign-in` takes **email only**.
- The handoff answer has only `token` + `name`; roles and `must_change_password` come from `/me`.
- `minimum_app_version` in the answer belongs to the Site Report app (`config/site-report.php`) — **ignored** here.
- Throttle is looser (30/min per IP, 20/hour per email vs. 5/min per IP on `/login`).

## 4. Build configuration (two modes)

`lib/app/config/app_config.dart`; every run and build passes an env file (`--dart-define-from-file`).

| Define | Mode | Used for |
|---|---|---|
| `CENTRAL_API_URL` (e.g. `https://app.<domain>/api`; dev `http://mastersystembackend.test/api`) | **workspace** | Production / staging / dev multi-tenant |
| `API_BASE_URL` (a tenant host) | **direct** | Single-tenant builds, legacy dev — old `POST /login` |
| `DEV_CONNECT_ADDRESS` (e.g. `127.0.0.1`, optionally `:port`) | either, **debug builds only** | Connect to this address while sending the real `Host` header (§6) |
| `API_TIMEOUT_SECONDS` | either | Request timeout (default 30) |

- `CENTRAL_API_URL` set → workspace mode; otherwise direct mode.
- The hard-coded ngrok fallback is **gone**. `AppConfig.defaultApiUrl` is the central URL (workspace) or `API_BASE_URL` (direct).
- **As built — the guard covers every build, not only release:** without either URL (or with one that is not an `http(s)` URL with a host), `main()` shows a "This build is not configured" screen (`Key('configErrorMessage')`) and `initServices()` throws, so a test fails at once. `AppConfig.describeConfigurationError` is the pure, tested check.
- The tenant scheme comes from `CENTRAL_API_URL`'s scheme (else `API_BASE_URL`'s, else https); `/api` is appended to `api_host`.

Env files (`env/`, see `env/README.md`; only `*.example.json` is committed, `env/*.json` is gitignored):

| File | Contents |
|---|---|
| `dev.example.json` (committed) | workspace over USB: `CENTRAL_API_URL=http://mastersystembackend.test/api`, `DEV_CONNECT_ADDRESS=127.0.0.1` |
| `direct.example.json` (committed) | one company host |
| `prod.example.json` (committed) | `CENTRAL_API_URL=https://app.example.com/api` |
| `dev.json` (local) | direct mode through the ngrok tunnel (the pre-change workflow) |
| `dev-usb.json` (local) | direct mode over USB: `API_BASE_URL=http://mc.mastersystembackend.test/api` + `DEV_CONNECT_ADDRESS` |
| `dev-workspace.json` (local) | same as `dev.example.json` |

Release: `flutter build apk --release --dart-define-from-file=env/prod.json`.

## 5. App changes (as built)

### 5.1 `ApiEndpoints` — `lib/app/services/api_endpoints.dart` (pure, unit-tested)
- `tenantApiUrl(apiHost)` → `'$scheme://$apiHost/api'` (host trimmed, lower-cased, dots stripped); `tenantScheme`.
- `apiBaseUrl({tenantApiHost})` → direct URL / company host / central URL by mode and session.
- `mustDropStoredSession(token, tenantApiHost)` → the old-session rule (§5.2).
- `connect(Uri)` → `(uri, hostHeader)`: in dev-connect mode the URL pointed at `DEV_CONNECT_ADDRESS` (its port wins, else the URL's) with the original authority as `Host`; otherwise unchanged.
- `probeHost(apiUrl)` → the dev connect address, else the URL's host (for `NetworkService`).

### 5.2 `AuthService` — the active company
- New (not secret → `get_storage`): `tenantId`, `tenantName`, `tenantApiHost` (keys `tenant_id_key`, `tenant_name_key`, `tenant_api_host_key`); loaded in `init()`, written by `setTenant(id:, name:, apiHost:)`, cleared by `clearToken()`.
- `endpoints` (an `ApiEndpoints`, injectable for tests); `apiBaseUrl` and `currentTenantName` getters.
- Old sessions: a token stored without a company host is cleared once at `init()` **in workspace mode** (the user signs in again — nothing says which company host it belongs to). Direct mode keeps it.

### 5.3 `ApiProvider` — dynamic base URL
- **As built:** GetConnect builds the URL as `baseUrl + path` when a request is created (`GetHttpClient.createUri`, which **always** prefixes the base — an absolute URL does not work). So `ApiProvider` overrides `get`/`post`/`put`/`patch`/`delete`/`request` and `getBytes` to set `httpClient.baseUrl = requestBaseUrl` right before each call. No `ever()` worker per provider instance (nothing to dispose).
- Hooks for a provider bound to another host: `requestBaseUrl` (default `AuthService.apiBaseUrl`) and `sendsToken` (default true); `authService` is exposed to subclasses.
- Request modifier: bearer token (when `sendsToken` and not already set), `Accept: application/json`, `ngrok-skip-browser-warning` **only** for ngrok hosts (`isNgrokHost`), and in dev-connect mode `Host` + `request.copyWith(url:)` from `ApiEndpoints.connect`.
- `signOut()` revokes with `POST /logout` on the company host in the background, then `clearToken()` also clears the company, so the base URL falls back to central.

### 5.4 `WorkspaceProvider` — `lib/app/data/providers/workspace_provider.dart`
`requestBaseUrl` = the central URL, `sendsToken` = false:
- `signIn(email, password, {tenantId})` → `POST /workspace/sign-in` → `WorkspaceSignInResult`.
- `forgotPassword(email)` → `POST /workspace/forgot-password` → the server's message.

Models — `lib/app/data/models/workspace_sign_in_model.dart`: `WorkspaceTenant {id, name, host, apiHost?}`, `WorkspaceSignInResult {mode, tenant?, handoffToken?, tenants}`; an incomplete handoff, an empty choice or an unknown mode is a readable `FormatException`.

### 5.5 `WorkspaceSession` — `lib/app/services/workspace_session.dart`
One place for the sequence, used by `LoginController` **and** the Patrol harness:
1. **As built — save the company first** (`setTenant`), so the base URL already is its host (no absolute URL, §5.3).
2. `POST /sign-in/handoff {token}` → the access token → `setToken`.
3. `GET /me` → name, roles (names), `must_change_password`.
4. `must_change_password == true` → revoke the token, `clearToken()`, throw `PasswordChangeRequiredException` (its message is `ApiProvider.passwordChangeNotice`).
5. Any failure clears what was saved — no half session is left behind.

### 5.6 `ApiExecutor` — `sessionBound`
`ApiExecutor` drops the error of a call that started under an older session (sign-in/out in between). The sign-in itself changes the session on purpose, so **as built** it runs with `ApiExecutor.run(..., sessionBound: false)`, or its failures (expired link, refused account) would never be shown.

### 5.7 Login UI — `modules/login/`
- Workspace mode: the field reads **Email** (`Key('loginEmailField')`, email keyboard and autofill, no autocorrect); validation = email format + password ≥ 6 (`loginFieldErrors(..., email: true)`). Direct mode keeps Username (`Key('loginUsernameField')`).
- `LoginController._workspaceLogin` runs `signIn` + `WorkspaceSession.complete` inside **one** `ApiExecutor` call, so the button stays disabled throughout; a `choose` answer opens `showCompanyChooser` (`views/company_chooser_sheet.dart`, tiles `loginCompanyChoice_<index>`, closed with `closeRoute`) and signs in again with the picked `tenant_id`. The password stays in the field's controller only.
- Success: "Signed in to `<company>` as `<name>`". Password change owed: the web notice.
- Forgot password: `WorkspaceProvider.forgotPassword` in workspace mode, `/send-email-reset` in direct mode (same dialog).
- "Remember me" stores the typed email/username.
- Home's account sheet shows the company under the name (`Key('homeAccountCompany')`, workspace mode).
- `LoginBinding` registers `WorkspaceProvider`.

### 5.8 `NetworkService`
The probe host is read on every check: `auth.endpoints.probeHost(auth.apiBaseUrl)` — the session's host, or `DEV_CONNECT_ADDRESS` in dev-connect mode (a `.test` name never resolves on a phone, which would always report "No internet connection").

### 5.9 Drafts per company — `DraftService` (added in rev. 3)
Document ids only mean something inside one company (PO 42 of one company is not PO 42 of another). `DraftService(namespace:)` stores every scope as `<tenantId>/<scope>` in workspace mode (`keyFor`), so drafts **and** `SubmitKey` idempotency keys are kept apart with no controller change. Direct mode has no company id and keeps the plain scope, so existing drafts stay readable. Wired in `initServices()`: `namespace: () => Get.find<AuthService>().tenantId.value ?? ''`.

## 6. Dev without ngrok

The web works on the PC because the hosts file (Laragon) points `*.test` at `127.0.0.1`; a phone does not share that file. The app reproduces it:

1. USB: `adb reverse tcp:80 tcp:80` — the phone's `127.0.0.1:80` reaches the PC's web server (lost on unplug/reboot; run it again).
2. Run: `flutter run --dart-define-from-file=env/dev-workspace.json` (or `env/dev-usb.json` for direct mode).
3. The app connects to `127.0.0.1` and sends `Host: mastersystembackend.test` (central) or `Host: mc.mastersystembackend.test` (the `api_host` the backend answered) — the server picks the tenant from `Host`.
4. Plain HTTP is allowed **only in debug builds** (`android/app/src/debug/AndroidManifest.xml`, `usesCleartextTraffic`); release stays HTTPS-only.

Wi-Fi alternative: `DEV_CONNECT_ADDRESS=<PC LAN IP>` with port 80 open in the Windows firewall.

The ngrok tunnel is no longer needed for the app; its domain stays registered on tenant `mc` for the **Accurate webhook** (§9).

## 7. Backend checklist (configuration only)

- [ ] Production `.env`: `APP_URL`, `CENTRAL_APP_DOMAINS=app.<domain>`, `CENTRAL_ADMIN_DOMAINS=admin.<domain>` (see `.env.example` & `config/tenancy.php`). A central host that isn't listed is treated as a tenant.
- [ ] Every tenant has a `<slug>.<domain>` domain (`php artisan tenant:create "<name>" <domain>`).
- [ ] `workspace-sign-in` throttle is loose enough for many users behind one warehouse NAT/IP (30/min per IP today); `sign-in/handoff` shares the tenant login throttle (5/min per IP).
- [ ] Optional: an explicit "primary" domain per tenant (see §9).
- [ ] Follow the backend's `docs/deploy-runbook.md` for the rest.

Related backend change made alongside (direct mode, not this spec): `POST /login` now also returns `must_change_password`, so the old sign-in refuses such an account at once (`TenantAuthTest`).

## 8. Production infrastructure

- **Own domain** + **wildcard DNS** `*.<domain>` → the server, plus `app.` & `admin.` records.
- **Wildcard TLS** (`*.<domain>`) — Let's Encrypt via DNS-01, or a Cloudflare proxy. Never enable cleartext in release.
- **Nginx** `server_name .<domain>;` → one Laravel app (tenancy picks the tenant from the host).
- **Staging** (`*.staging.<domain>`, `env/staging.json`) — the Patrol write tests (receive/outflow/delivery) run there, **not** in production.

## 9. Risks & notes

- **`api_host` is the tenant's first domain** (`describe()` → `$tenant->domains->first()`). Tenant `mc` has two: `mc.mastersystembackend.test` (id 1) and `allowing-toucan-ghastly.ngrok-free.app` (id 8, **kept for the Accurate webhook** — it was removed once on 2026-11-04 and restored with the same id the same day). While that order holds, the app is sent to the right host. A backend "primary domain" flag would remove the dependency on row order (optional, outside this spec).
- `adb reverse` is lost when the cable is unplugged or the phone restarts.
- Users who only have a username cannot use workspace mode; direct mode stays for single-tenant builds.
- The company chooser (`choose`) is covered by a widget test only: no dev account belongs to two companies with the same password. Add one before release to try it on a device.

## 10. Testing (results 2026-11-04, device `140892557H014055`)

**Unit / widget (`flutter test`) — 164 pass.** New for this spec:
- `test/services/api_endpoints_test.dart` — config check, tenant URL & scheme, dev-connect rewrite + `Host` (with ports), probe host.
- `test/services/auth_service_tenant_test.dart` — `AuthService.init()` with mocked storage: old session dropped (workspace) / kept (direct), `setTenant` → restart → `clearToken`.
- `test/services/workspace_session_test.dart` — handoff + `/me` on the company host, password change owed (token revoked, no session), refused handoff (company cleared), `WorkspaceProvider` requests (central URL, no token, optional `tenant_id`).
- `test/models/workspace_sign_in_model_test.dart` — `handoff` / `choose` / malformed answers.
- `test/services/draft_service_db_test.dart` — drafts per company, plain scope in direct mode.
- `test/widgets/company_chooser_sheet_test.dart` — pick a company, dismiss.
- `test/helpers/…` — ngrok host check, email validation.

**Patrol (real backend over `adb reverse`, no tunnel):**

| Run | Result |
|---|---|
| Full suite, **workspace mode** (`env/dev-workspace.json`, `TEST_EMAIL`) | 45 ✅ / 2 ❌ → both fixed and re-run green: `home_test` 6/6 (the new company-name test used `waitUntilVisible` on a text row), `receive_order_test` 8/8 (dev data had run out — see below) |
| `login` + `home`, direct mode over USB (`env/dev-usb.json`) | 10 ✅, 1 skipped (workspace-only test) |
| `login` + `home`, direct mode over ngrok (`env/dev.json`) | 10 ✅ |

Harness (`patrol_test/common/harness.dart`): credentials follow the mode (`TEST_EMAIL` / `TEST_USERNAME`, comma-separated, `accountFor`); `loginAsTestUser` uses `WorkspaceProvider` + `WorkspaceSession` in workspace mode; `loginViaForm` types into `loginAccountFieldKey`; `login_test` is mode-aware; `home_test` checks the company name in the account sheet (workspace only).

**Dev data:** the PO receive test needs a priced, non-serial open line. Re-running `DemoTenantSeeder` does **not** add POs (the deals seeder runs once per tenant behind a `tenant_settings` marker), so `PO-SMP-E2E-20261104` (50 units, non-serial item, price 100,000) was added on `mc`; 48 left after the run.

**Manual before release:** single-company user, multi-company user (choose), wrong password, handoff after 60 s (debug delay), suspended company, logout → sign in to another company on the same device (drafts must not cross over), expired token (401) → back to login with the company cleared.

## 11. Decisions

Taken (2026-11-04):
1. **Username sign-in** only in direct-mode builds; workspace builds sign in by email.
2. **Existing sessions** in workspace builds are signed out once (no company host to keep them on).
3. **Drafts are kept per company** (§5.9).

Still open (needed for release only):
1. **Production central host** (`app.<domain>`) and the tenant domain pattern.
2. **Hosting provider** — decides how the wildcard TLS certificate is issued.

## 12. Execution order

1. ✅ `AppConfig` two modes + `DEV_CONNECT_ADDRESS` + env files + configuration guard (§4); `ApiEndpoints` (§5.1).
2. ✅ `AuthService` company fields + `apiBaseUrl` + old-session migration (§5.2).
3. ✅ `ApiProvider` per-request base + dev-connect `Host` + ngrok header only for ngrok + `NetworkService` (§5.3, §5.8). Direct mode verified unchanged.
4. ✅ `WorkspaceProvider`, models, `WorkspaceSession`, `ApiExecutor.sessionBound`, drafts per company (§5.4–5.6, §5.9).
5. ✅ Login UI + company chooser + forgot password + company name on Home (§5.7).
6. ✅ Patrol harness + tests over `adb reverse`; direct-mode Patrol still green (§10).
7. ✅ `CLAUDE.md` (Commands/API config, Testing, Backend → "How the app reaches a tenant").
8. ⏳ Infra + backend checklist (§7–8); build with `--dart-define-from-file=env/prod.json`.
