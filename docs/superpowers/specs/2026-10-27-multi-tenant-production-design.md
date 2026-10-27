# Spec: Production URL & Multi-Tenant Sign-In (Mobile)

- **Tanggal:** 2026-10-27
- **Status:** Draft — belum dieksekusi
- **Scope:** `getx_project` (Flutter). Backend (`D:\laravel-project\MasterSystemBackend`) hanya konfigurasi/verifikasi; endpoint yang dibutuhkan sudah ada.

## 1. Latar belakang

Saat ini app memanggil **satu** base URL yang ditanam saat build (`AppConfig.apiBaseUrl`, `lib/app/config/app_config.dart`), default-nya tunnel ngrok. Login memanggil `POST /login` langsung ke host itu.

Backend memakai `stancl/tenancy` dengan `InitializeTenancyByDomain`: **tenant ditentukan oleh host** yang dipanggil (`<tenant>.domain.com/api/...`). Satu URL statis berarti satu tenant per APK — tidak bisa dipakai untuk banyak tenant di production.

## 2. Tujuan

1. **Satu APK untuk semua tenant.** Tenant baru tidak butuh build baru.
2. User **tidak perlu tahu/mengetik nama tenant** — cukup email + password.
3. Dev workflow (ngrok, satu tenant) dan Patrol E2E tetap jalan.
4. Tidak ada URL ngrok/dev yang ikut ter-ship di build production.

**Non-goal:** iOS release pipeline, custom domain per tenant (lihat §9), refactor modul lain.

## 3. Alur yang dipakai (sudah ada di backend)

```
App ──POST {CENTRAL}/api/workspace/sign-in {email, password[, tenant_id]}──▶ Central
      ◀── mode=handoff: {tenant{id,name,host,api_host}, handoff_token, expires_in:60}
      ◀── mode=choose : {tenants:[{id,name,host}]}   (email ada di >1 tenant)

(mode=choose) → user pilih → ulangi sign-in dengan tenant_id → mode=handoff

App ──POST https://{api_host}/api/sign-in/handoff {token: handoff_token}──▶ Tenant
      ◀── {data:{token, name, redirect_url}}

App simpan token + api_host → semua request selanjutnya ke https://{api_host}/api
```

Referensi backend:
- `routes/central_app_api.php` → `WorkspaceSignInController::signIn` → `App\Services\Central\WorkspaceSignInService::signIn` (bentuk respons, `describe()`).
- `routes/tenant_api.php:128` → `PassportAuthController::signInHandoff` → `SignInHandoffService::exchange` (handoff sekali pakai, TTL 60 dtk, harus ditukar di host tenant yang benar).
- Validasi: `email` wajib format email; `tenant_id` opsional (`WorkspaceSignInRequest`).
- Error: semua kegagalan kredensial = 401 dengan satu pesan konstan. Handoff gagal = 403 dengan pesan (`invalid/used`, `expired`, `not this company`, `no longer active`).

Catatan perbedaan dengan `/login` lama:
- `/login` tenant menerima **username atau email**; `workspace/sign-in` **hanya email**.
- Respons handoff hanya `token` + `name` — **tidak ada `roles`**. Roles + user id harus diambil setelahnya (lihat §5.4).
- `minimum_app_version` di respons adalah milik app Site Report (`config/site-report.php`) — **abaikan** di app warehouse.

## 4. Konfigurasi build (dua mode)

Ganti `AppConfig` jadi dua define yang saling eksklusif:

| Define | Mode | Dipakai untuk |
|---|---|---|
| `CENTRAL_API_URL` (mis. `https://app.domain.com/api`) | **workspace** | Production / staging multi-tenant |
| `API_BASE_URL` (mis. ngrok) | **direct** | Dev lokal, Patrol E2E — satu tenant, `POST /login` lama |

- Jika `CENTRAL_API_URL` diisi → mode workspace. Jika tidak → mode direct (perilaku sekarang).
- **Hapus** fallback ngrok hard-coded (`_devFallbackBaseUrl`) dari kode; dev menaruh URL ngrok di `--dart-define-from-file=env/dev.json` (gitignored), dengan `env/dev.example.json` ter-commit.
- Release guard: build `--release` tanpa `CENTRAL_API_URL` maupun `API_BASE_URL` → fail fast saat startup (assert/throw dengan pesan jelas), bukan diam-diam ke host salah.
- `env/prod.json` → `{"CENTRAL_API_URL": "https://app.<domain>/api"}`. Build: `flutter build apk --release --dart-define-from-file=env/prod.json`.
- `TENANT_API_SCHEME` tidak perlu: scheme tenant diambil dari scheme `CENTRAL_API_URL`, path `/api` ditambahkan ke `api_host`.

## 5. Perubahan di app

### 5.1 `AuthService` — simpan tenant aktif
Tambah (non-secret → `get_storage`):
- `tenantId`, `tenantName`, `tenantApiHost` (Rx + key storage), di-load di `init()`, di-clear di `clearToken()`.
- Getter `String get apiBaseUrl`:
  - mode direct → `AppConfig.apiBaseUrl`
  - mode workspace + `tenantApiHost != null` → `'$scheme://$tenantApiHost/api'`
  - mode workspace tanpa tenant → `AppConfig.centralApiUrl`
- Migrasi: user yang sudah login di build lama (punya token, tanpa `tenantApiHost`) di mode workspace → `clearToken()` saat `init()` supaya diarahkan login ulang.

### 5.2 `ApiProvider` — base URL dinamis
Setiap provider adalah instance `GetConnect` sendiri dengan `httpClient.baseUrl` yang di-set sekali di `onInit()`. Base URL harus mengikuti tenant aktif:
- Di `onInit()`: set `httpClient.baseUrl = _authService.apiBaseUrl` dan pasang `ever(...)` pada Rx tenant (`tenantApiHost`) yang meng-update `httpClient.baseUrl`; dispose worker di `onClose()`.
- **Verifikasi dulu** di source GetConnect 4.7 bahwa `GetHttpClient.baseUrl` dibaca per request (bukan di-cache saat konstruksi). Jika di-cache, alternatif: provider memanggil path absolut lewat helper `url(path)` di `ApiProvider`.
- Header `ngrok-skip-browser-warning` hanya dikirim bila host berakhiran `ngrok-free.app` / `ngrok.app` / `ngrok.io`.
- Penanganan 401 (`checkResponse`) tetap; `clearToken()` kini juga menghapus tenant.

### 5.3 Provider baru: `WorkspaceProvider`
`lib/app/data/providers/workspace_provider.dart`, extends `ApiProvider`, tapi selalu ke central (jangan ikut base URL tenant — override base URL ke `AppConfig.centralApiUrl` atau pakai URL absolut):
- `Future<Map<String, dynamic>> signIn(String email, String password, {String? tenantId})` → `postMap('/workspace/sign-in', ...)`
- `Future<Map<String, dynamic>> forgotPassword(String email)` → `postMap('/workspace/forgot-password', ...)` (opsional, lihat §8)

Dan di `LoginProvider` (tenant):
- `Future<Map<String, dynamic>> exchangeHandoff(String apiBaseUrl, String token)` → POST absolut ke `'$apiBaseUrl/sign-in/handoff'` (tenant belum disimpan saat ini dipanggil).

Model kecil (`data/models/`): `WorkspaceTenant {id, name, host, apiHost?}` dan `WorkspaceSignInResult {mode, tenant?, handoffToken?, tenants}`.

### 5.4 `LoginController.authLogin()`
```
if (AppConfig.isDirectMode) → alur lama (/login) — tidak berubah.
else:
  r = ApiExecutor.run(signIn(email, pwd, tenantId: _pickedTenantId))
  if r == null → return
  if r.mode == 'choose' → tampilkan pilihan tenant (bottom sheet), simpan pilihan, panggil ulang signIn dengan tenant_id
  if r.mode == 'handoff':
     base = '$scheme://${r.tenant.apiHost}/api'
     h = ApiExecutor.run(exchangeHandoff(base, r.handoffToken))   // segera; TTL 60 dtk
     if h == null → return
     await auth.setToken(h.token); auth.setUsername(h.name); auth.setTenant(r.tenant)
     resolve roles + userId via GET /user/currentDetail (provider yang sudah ada) → setRoles/setUserId
     successAlert; Get.offAllNamed(Routes.HOME)
```
- Password tidak boleh disimpan di antara langkah `choose` → `handoff` selain di `TextEditingController` yang sudah ada.
- Handoff 403 "expired" → pesan "Silakan masuk lagi" (sudah dari backend via `checkResponse`).
- **Verifikasi** respons `/user/currentDetail` berisi `roles` dalam bentuk yang sama dengan `/login` (`[{name}]`); jika tidak, sesuaikan parsing atau minta backend menambahkannya.
- `ApiExecutor` memakai satu `isLoading` untuk ketiga call berurutan; pastikan `isLoading` tidak dilepas di antara call sehingga tombol bisa ditekan dua kali (atau kunci tombol dengan flag terpisah).

### 5.5 UI login
- Mode workspace: label field jadi **Email**, keyboard `emailAddress`, validasi format email sebelum submit. Key tetap `loginUsernameField` (agar Patrol tidak pecah) — atau rename ke `loginEmailField` dan update harness sekaligus.
- Bottom sheet pilih perusahaan (`mode=choose`): list `name` + `host`, key `loginTenantOption_<index>`. Pakai widget shared yang ada; tutup dengan `closeRoute(...)` (bukan `Get.back()`).
- Tampilkan nama tenant aktif di Home/AppBar/drawer (mis. di bawah username) supaya user tahu sedang di perusahaan mana.

### 5.6 Logout
- Panggil `POST /logout` ke host **tenant** (revoke token) sebelum `clearToken()`; error diabaikan (tetap logout lokal).
- `clearToken()` menghapus tenant → base URL kembali ke central.

### 5.7 `NetworkService`
`_probeHost` saat ini statis dari `AppConfig.apiBaseUrl`. Ubah jadi getter dari `Uri.parse(authService.apiBaseUrl).host` supaya probe mengikuti tenant aktif.

## 6. Backend — checklist (konfigurasi, tanpa endpoint baru)

- [ ] `.env` production: `APP_URL`, `CENTRAL_APP_DOMAINS=app.<domain>`, `CENTRAL_ADMIN_DOMAINS=admin.<domain>` (lihat komentar di `.env.example` & `config/tenancy.php`). Host central yang tidak terdaftar akan dianggap tenant.
- [ ] Tiap tenant punya domain `<slug>.<domain>` (`php artisan tenant:create "<name>" <domain>`).
- [ ] Throttle `workspace-sign-in` cukup longgar untuk banyak user di belakang satu NAT/IP gudang — cek limiter-nya.
- [ ] Pastikan `/sign-in/handoff` tenant tidak terkena middleware `subscription.active` (sudah di luar group auth per `tenant_api.php:122-128`, verifikasi saja).
- [ ] Ikuti `docs/deploy-runbook.md` backend untuk sisanya.

## 7. Infrastruktur production

- **Domain sendiri** + **wildcard DNS** `*.<domain>` → server, plus record `app.` & `admin.`.
- **Wildcard TLS** (`*.<domain>`) — Let's Encrypt via DNS-01 challenge, atau Cloudflare proxy. Android menolak HTTP biasa secara default; jangan aktifkan cleartext.
- **Nginx** `server_name .<domain>;` → satu Laravel app (tenancy memilih tenant dari host).
- **Staging** terpisah (mis. `*.staging.<domain>`) dengan `env/staging.json` — Patrol write-tests (receive/outflow/delivery) jalan di sini, **bukan** di prod.
- Ngrok hanya untuk dev lokal.

## 8. Testing

- **Unit (`test/`)**: `AppConfig` mode selection; `AuthService.apiBaseUrl` (direct / workspace tanpa tenant / workspace dengan tenant); migrasi token lama tanpa tenant; parsing `WorkspaceSignInResult` (`handoff` & `choose`); header ngrok hanya untuk host ngrok.
- **Patrol**: tetap jalan di mode direct (`API_BASE_URL` = ngrok) — tidak ada perubahan perilaku. Tambah `patrol_test/workspace_login_test.dart` yang hanya jalan bila `CENTRAL_API_URL` + `TEST_EMAIL`/`TEST_PASSWORD` di-define (`skip:` seperti `hasCredentials`) dan diarahkan ke staging.
- **Manual sebelum rilis**: login user 1-tenant, user multi-tenant (choose), password salah, handoff lewat 60 dtk (simulasi dengan delay debug), tenant suspended, logout → login ke tenant lain di device yang sama, token expired (401) → kembali ke login + tenant terhapus.

## 9. Pertanyaan terbuka (putuskan sebelum eksekusi)

1. **Domain tenant**: semua subdomain `<slug>.<domain>`, atau ada tenant yang mau custom domain sendiri? (Alur ini tetap jalan untuk custom domain karena `api_host` datang dari backend — yang berubah hanya TLS/DNS per domain.)
2. **User yang login pakai username (bukan email)**: apakah semua user warehouse punya email unik? Jika tidak, butuh fallback — mis. field "Kode perusahaan" opsional yang memakai `/login` lama ke `<kode>.<domain>`.
3. **Hosting production**: VPS / cloud mana? Menentukan cara wildcard TLS.
4. **Forgot password** di mobile (`/workspace/forgot-password`) — masuk scope ini atau nanti?
5. Rename key `loginUsernameField` → `loginEmailField` sekarang atau tidak.

## 10. Urutan eksekusi yang disarankan

1. `AppConfig` dua mode + env files + release guard (§4) — app tetap jalan di mode direct.
2. `AuthService` tenant fields + `apiBaseUrl` getter + migrasi (§5.1) + unit test.
3. `ApiProvider` base URL dinamis + header ngrok kondisional + `NetworkService` (§5.2, §5.7) — verifikasi GetConnect dulu.
4. `WorkspaceProvider`, `exchangeHandoff`, models (§5.3).
5. `LoginController` + UI login + tenant chooser (§5.4–5.5), logout (§5.6).
6. Patrol mode direct tetap hijau (`patrol test -t patrol_test/login_test.dart`), lalu workspace test di staging.
7. Infra + backend checklist (§6–7), build `--dart-define-from-file=env/prod.json`.
8. Update `CLAUDE.md` (bagian Backend: ganti "ngrok URL in ApiProvider" dengan penjelasan dua mode).
