# PLANNING.md — Warehouse App Review & Roadmap

> Codebase review of the Flutter + GetX warehouse app. Architecture is solid
> (clean provider → `ApiExecutor` → controller discipline); the debt is
> concentrated in the **view layer** (duplication, style drift) and
> **production-readiness** (security, config, offline). Nothing here needs a
> rewrite — this is a hardening + feature roadmap.

Legend: `[ ]` todo · `[~]` in progress · `[x]` done

---

## 🔴 P0 — Blockers before any real deployment

- [x] **Plaintext password in "Remember me"** — ~~`login_controller.dart:57`~~ Done.
      Password is no longer persisted; only the email is remembered (auto-login via
      token handles returning users). Legacy `saved_password` is purged on load.
- [x] **Auth token in unencrypted storage** — ~~`auth_service.dart:49`~~ Done. Token
      moved to `flutter_secure_storage` (Android `encryptedSharedPreferences`), with
      one-time migration of any existing plaintext token so users aren't logged out.
      `AuthService.init()` now loads it async via `Get.putAsync` in `main()`.
      `minSdkVersion` bumped to 23 (required by encrypted storage).
- [x] **Hardcoded ngrok base URL** — ~~`api_providers.dart:11`~~ Done. Introduced
      `lib/app/config/app_config.dart` reading `API_BASE_URL` / `API_TIMEOUT_SECONDS`
      from `--dart-define`, with the dev tunnel kept only as a fallback default.
      Build prod with `--dart-define=API_BASE_URL=https://api.yourdomain.com/api`.
- [x] **Auth middleware on only 2 of 29 routes** — ~~`app_pages.dart`~~ Done. Routes
      now built via a `_guard()` helper that injects `AuthMiddleware()` on every
      page except LOGIN, so a route can't ship unprotected. All 28 protected routes
      are now guarded.
- [x] **No crash reporting + no global error handler** — Done (foundation). Added
      `lib/app/helpers/crash_reporter.dart` wired in `main()` via `runZonedGuarded`
      + `FlutterError.onError` + `PlatformDispatcher.onError` + a friendly
      `ErrorWidget.builder`. All uncaught errors are captured/logged.
      **Remaining:** drop in a hosted reporter (Sentry/Crashlytics) at the single
      `TODO(reporter)` in `crash_reporter.dart` — needs a DSN/Firebase project.

---

## 🟡 P1 — Code quality (view layer holds the debt)

- [x] **Kill list-screen duplication** — Done for the master lists. Added
      `global/widget/master_list_view.dart` (`MasterListView<T>` scaffold +
      `masterListCard` + `masterMonogram`, limit dialog built in). The
      `product-category`, `product-unit`, `product-brand` views are now ~50-line
      thin configs (were ~290–445 lines each), sharing one card design + one dialog.
  - [x] The **by-category / by-brand** product-list screens extracted too — new
        `global/widget/product_by_filter_view.dart` (`ProductByFilterView`); both
        views are now ~30-line thin configs (were ~154 each). Also fixed the
        by-brand back-route bug (pointed at `productCategory`; now `productBrand`).
- [x] **Fix `appBarOrder` at the root** — Done. Signature now takes
      `Color? color1, Color? color2` (defaults `steelBlue`/`lightSteelBlue`); the
      `hexcolor` dependency dropped from the helper. All **25 call sites** converted
      to named constants — zero raw hex args remain. Added 3 gradient-end constants
      to `variables.dart` (`skyBlueLight`, `sageTealLight`, `amberLight`).
  - [x] Bug fixed: `receive_order_by_supplier_detail_view.dart` was passing
        `"75a340"` (missing `#`, wrong color) — now `sageTeal`/`sageTealLight`,
        matching the rest of the supplier flow.
- [x] **Inline `TextStyle` → `AppTextStyle`** — Done for all active code (~170
      conversions across ~30 files). Added `AppTextStyle.custom(...)` (one-off
      sizes) and `AppTextStyle.plain(...)` (color/weight-only, size inherited) so
      appearance is preserved exactly. `flutter analyze` clean.
      **Intentionally kept:** monospace serial styles (can't be Plus Jakarta Sans),
      `crash_reporter.dart` (dependency-free), and the `return`/whatsapp module
      (pending deletion below). `home_controller`'s chart styles were converted
      in place (moving styling fully out of the controller is a separate cleanup).
- [x] **Dispose dialog `TextEditingController`s** — Done. All 12 dialog-local
      controllers now disposed after the dialog closes: `Get.dialog` sites converted
      to `await` + `.dispose()` + return (fill-by-po/supplier qty+exp, both scan
      pages' batch + other dialogs, both receive-number dialogs); `Get.bottomSheet`
      (delivery edit) and `showGeneralDialog` (shared limit dialog) use
      `.whenComplete(dispose)`. `flutter analyze` clean.
- [x] **Delete or finish the `return` module** — Deleted. Removed the whole
      `lib/app/modules/return/` dir (dummy form, inline `DetailModel`, WhatsApp-clone
      views) plus all refs: `return` route/imports/`returnPage` const in
      `app_pages.dart`, `RETURN` in `app_routes.dart`, and the unwired
      `goToReturnPage()` in `home_controller`. `flutter analyze` clean, zero refs left.
      (If returns are needed later, rebuild properly per the P2 feature item.)
- [~] **Tests are effectively zero** — Started. Deleted the broken counter-template
      `widget_test.dart` and added **23 passing unit tests** (`flutter test`) covering
      pure logic with no backend/device deps: model parsing (`DashboardModel`
      hyphenated keys + round-trip, `StockTransactionModel` string-qty + nested order,
      product master models' `initial_code` mapping + null-description default),
      `functions.dart` helpers (`safeToInt`, `capitalizeFirstofEach`, url/image/pdf,
      `searchString`, color helpers, `formatPrice`), and `masterMonogram`.
  - [ ] Still to do: controller/pagination + `checkResponse` tests (need GetX/mock
        setup — `mocktail` not yet added).
- [ ] **Dependency hygiene** — `get` pinned old/unmaintained; `connectivity_plus 3.x`,
      `fl_chart 0.60`, `google_fonts 5.x` several majors behind. Confirm
      **Syncfusion** commercial license.
- [~] **Cleanup** — Commented-out dead code removed: the `dummyjson` `onInit` stub in
      `login_provider`, duplicated commented `onReady`/`onClose` stubs across
      product/by-category/by-brand controllers, the commented `_buildActionButtons`
      method + call site in `product_detail_view`, the dead metric-delta container +
      now-unused `percent` param (and fake `+8.00%`/`+2.34%` args) in `product_view`,
      the empty unused `openDetail` in `stock_transaction_controller`, dead comments in
      both receive detail controllers' `goToNextItem`, and stray `buildSyncButton`
      comments. `flutter analyze` clean.
  - [x] Dead `/item` route removed — `ITEM`/`itemPage` deleted from `app_routes.dart`
        (`Routes` + `_Paths`) and `app_pages.dart`. `flutter analyze` clean.
  - [ ] **Deferred (needs a decision):** `stock_transaction_detail` (view + binding +
        controller) is fully built but orphaned — no route registered and nothing
        navigates to it. Options: register + wire the list to open it, register-only,
        or delete as dead code. Left untouched for now.

---

## 🟡 P1 — UX resilience

- [~] **Offline support (highest-value gap)** — **Drafts done.** Added a sqflite
      local DB (`lib/app/services/draft_service.dart`, `DraftService` — permanent,
      opened async in `main()`) with a tiny JSON-blob API
      (`saveJson`/`readJson`/`remove`) + shared line-keyed helpers
      (`readLineDraft`/`buildLineDraftMap`). Every in-progress scan/fill screen now
      auto-persists (`ever(items, …)`) and restores on reopen, so a worker who scans
      50 serials **no longer loses the batch** to an app kill/crash/offline. The
      **receive fill** flow (by-PO + by-supplier) — the exact gap — now persists like
      outflow already did; the two outflow controllers + the receive-confirm cache
      were migrated off GetStorage onto `DraftService` (one unified store). Deps:
      `sqflite ^2.2.0` + `path ^1.8.3`. `flutter analyze` clean; +3 unit tests
      (`test/services/draft_service_test.dart`), full suite green (26 tests).
      **Remaining:** offline *reads* (browse lists/details with no connection) — the
      DB currently stores only outgoing drafts, not cached read data.
- [~] **Offline scan queue (outbox)** — Scope was set to **drafts + manual retry**
      (no data loss; submit still needs a connection and the worker re-submits when
      back online), delivered by the draft store above. **Deferred:** true background
      auto-replay of queued submits — the `receiveData`/`outflowData` responses carry
      a created-order id the flow uses inline (route to confirm-serials, delivery
      prompt), so background replay needs resume-later + notification UX; left as a
      separate, larger effort.
- [~] **Retry + error-vs-empty states** — Foundation done. `ApiExecutor.run` takes an
      optional `hasError` RxBool (set false on success / true on any failure); added a
      shared `errorRetry(size, onRetry:)` widget; wired through `MasterListView` +
      `ProductByFilterView` so category/unit/brand + by-category/by-brand now show an
      error+retry state (not "No data") when a load fails. `flutter analyze` + tests clean.
  - [x] Swept into all remaining list screens — product, stock-transaction,
        product-transaction-list, receive (list/by-PO/by-supplier), outflow
        (list/by-request/by-customer), and delivery. Each controller got a
        `hasError` RxBool wired to its first-load `ApiExecutor.run`; each view shows
        `errorRetry` (module-matched accent) before its empty state. Delivery's
        try/finally loader sets `hasError` in the primary null-branch. `flutter
        analyze` clean. **Every list screen now distinguishes error from empty with
        a Retry action.**
- [x] **Real reachability check** — Done. `NetworkService.checkConnection()` now does a
      DNS lookup of the API host (from `AppConfig`) with a 3s timeout after the
      interface check, so "connected to Wi-Fi, no internet" is correctly detected
      instead of proceeding to a generic failure. Interface-drop still fast-fails.
- [x] **Migrate scanner to `mobile_scanner`** — Done, **with continuous batch
      scanning**. Dropped `flutter_barcode_scanner 2.0.0` for `mobile_scanner ^3.4.0`
      (resolved 3.5.7 — pinned to 3.x for the Dart 3.0.1 SDK). New shared
      `global/widget/scanner_page.dart` (`ScannerPage`) with two modes off one
      widget: **continuous batch** (`onCode` set — camera stays open, each scan fed
      back, live colored feedback + running count, torch/flip/manual-entry controls,
      debounced same-code re-reads, serialized against the in-flight save) and
      **single-shot** (`scanSingle()` — pops the first code, for BATCH/OTHER flows
      that need a follow-up qty dialog). Feedback is a dependency-free
      `global/scan_feedback.dart` (`ScanFeedback`/`ScanStatus`) so controllers stay
      Flutter-light. **Continuous wired into:** confirm-serials (new
      `confirmAnyScan` auto-matches a label across *all* items, not just the selected
      tab) and outflow UNIQUE items (new `scanUnique` on both outflow controllers,
      one scan = one unit). BATCH/OTHER + manual entry keep the single-shot path via
      the updated `captureSerialInput`. iOS `NSCameraUsageDescription` added; Android
      `compileSdkVersion` bumped **33 → 34** (mobile_scanner's `androidx.camera`
      requires compiling against 34; min/target/runtime unchanged) and Kotlin
      **1.7.10 → 1.8.22** + stdlib-jdk7/jdk8 constraints (the camera libs pull
      kotlin-stdlib 1.8, which collided with an older transitive jdk8 stub).
      `flutter analyze` clean; `flutter test` green (26); **debug APK builds
      (`app-debug.apk`)**; zero `flutter_barcode_scanner` refs left.

---

## 🟢 P2 — Features (ranked by warehouse value)

- [~] **Offline scan queue (outbox)** — see P1; listed here as the flagship feature.
      Drafts + manual retry shipped (no data loss); true background auto-replay of
      queued submits still deferred.
- [x] **Continuous/batch barcode scanning** — Done via `mobile_scanner` (see the
      P1 scanner-migration item). Continuous mode is live on confirm-serials and
      outflow UNIQUE items.
- [ ] **Stock count / cycle-count (opname) module** — core function currently missing:
      scan bin → count → reconcile vs system qty.
- [ ] **Bin / location tracking** — where an item physically lives; put-away/pick guidance.
- [~] **Low-stock alerts & reorder thresholds** — a low-stock badge already renders on
      the product tile + detail (`ProductSummaryModel.lowStock`, hardcoded `qty_remaining < 10`).
      **Remaining:** configurable reorder threshold (not hardcoded), a dashboard badge/count,
      and push notifications below minimum.
- [ ] **Finish the Returns flow** — stubbed today; a genuine warehouse need.
- [ ] **Reports & export** — CSV/PDF of transactions, receive/outflow, delivery
      (already have `data_table_2` + Syncfusion).
- [ ] **Role-based UI** — `roles` are stored but not used to gate features.
- [ ] **Biometric / PIN unlock** (`local_auth`) — quick re-auth on shared devices;
      lets you avoid persisting credentials.
- [x] **Wire dashboard gaps** — Moot: the orphaned `goToReturnPage()` was removed
      with the `return` module (P1). Revisit only if/when Returns is rebuilt.

---

## Suggested execution order

1. Security + config (secure storage, kill plaintext password, env base URL) — small, high-stakes.
2. Full route protection + crash reporting — small.
3. Extract shared list widget + `appBarOrder` → `Color` — pays down the most debt.
4. Offline scan outbox + `mobile_scanner` — biggest real-world UX upgrade.
5. Then features (cycle-count + bin tracking are highest-leverage).

---

## Health snapshot (what's already good)

- Provider → `ApiExecutor` → controller pattern is clean and consistent.
- No try/catch in providers; no `statusCode`/`isOk`/`response.body` checks in controllers.
- Every provider calls `checkResponse`; connectivity gating is centralized.
- Skeletonizer loading states + consistent alert helpers.
- Debt is isolated to the **view layer** and the **abandoned `return` module** — not the architecture.
