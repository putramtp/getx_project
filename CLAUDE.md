# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
flutter run

# Build APK
flutter build apk

# Analyze (lint)
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Patrol E2E tests (real device/emulator; app starts logged out each test)
patrol test -t patrol_test/login_test.dart
patrol test -t patrol_test/login_test.dart --dart-define=TEST_USERNAME=... --dart-define=TEST_PASSWORD=...
```

The Flutter SDK is pinned per-project with **FVM** (`.fvmrc` → 3.47.7); it is also the machine-wide default (`fvm global`, user PATH → `C:\Users\Asus\fvm\default\bin`); the old `C:\flutter` 3.10 SDK is no longer on PATH. Android uses the Kotlin-DSL Gradle files (`*.gradle.kts`, AGP 9 / Gradle 9). `kotlin.incremental=false` in `android/gradle.properties` is required because the project (D:) and pub cache (C:) are on different drives.

## Commit Messages

When asked for a commit message, give it in this format — a conventional-commit subject line, a blank line, then a short bullet body (one line per change area). **Do not add a `Co-Authored-By` trailer** or any other attribution line.

```
chore: upgrade to Flutter 3.47.7 and add Patrol E2E tests

- Pin Flutter 3.47.7 via FVM; bump all deps to latest
- Fix breaking APIs: mobile_scanner 7 torch state, connectivity_plus 7 list results
- Add Patrol 4.10 with patrol_test/login_test.dart
```

Subject: `<type>: <summary>` (`feat`, `fix`, `chore`, `refactor`, `docs`, `test`), imperative, ≤ ~72 chars. Body bullets: what changed and, where non-obvious, why.

## Testing (Patrol E2E)

Unit tests live in `test/` (`flutter test`, no device). End-to-end UI tests use **Patrol** (`patrol` 4.10 dev dependency + `patrol_cli` 4.8, installed via `dart pub global activate patrol_cli`) and run on a **real Android device or emulator** — Patrol drives the actual app, so it can also tap native UI (permission dialogs, notifications) via `$.platform`.

- **Run**: `patrol test -t patrol_test/<name>_test.dart` (one file) or `patrol test` (all of `patrol_test/`). Needs a device visible to `adb devices`. `patrol build android -t ...` compiles the app + instrumentation APKs without a device — use it to verify the test setup builds.
- **Where tests go**: `patrol_test/*_test.dart` (not `integration_test/`). `patrol_test/test_bundle.dart` is **generated** by `patrol_cli` on every run — it is gitignored and excluded from the analyzer; never edit or commit it.
- **Harness** (`patrol_test/common/harness.dart`): every test is declared with `e2eTest(...)` (not bare `patrolTest`) — it drains GetX snackbars after the test, since a snackbar still animating at teardown fails the test and GetX's global snackbar queue would leak into the next one. Use `loginAsTestUser($)` to start on Home — it signs in via `POST /login` (no form typing), stores the token in `AuthService`, then pumps `MyApp`; retries on tunnel errors. Only `login_test` uses `loginViaForm($)` to exercise the real form. Then `waitForList($)` (waits until no skeleton text for 1.5 s, taps `Retry` up to 2×), `listCards()` / `tapListCard($, i)` / `listCardTitle($, i)`, `expectScreen($, title)`, `waitForSuccess($, finder)` (fails with the app's error-snackbar text), `appears($, finder)` for optional dialogs, `grantCameraIfAsked($)`, `uniqueSuffix()`. Order-flow helpers (`openOrderWithAction`, `continueBackToSummary`, `outflowOneRequestLine`) live in `patrol_test/common/order_flow.dart`. To search a list for a card that meets a condition, use `openFirstCardWhere` (tracks cards by title and scrolls; never count cards once and loop by index — the list only builds visible cards and reloads after Back). `expectAboveSystemNavBar($, finder)` asserts a bottom button isn't under the 3-button nav bar; `waitUntilTrue` waits on controller state. One file per feature: `login`, `home`, `product`, `product_master`, `stock_transaction`, `receive_order`, `outflow_order`, `delivery`.
- **Write tests mutate the backend**: the receive/outflow/delivery write tests submit real receives, outflows and delivery updates — run them only against a demo/dev tenant. They pick data dynamically (first PO/request with a `Fill` line) and fail with an explicit message when none is open.
- **Booting the app**: tests call `await initServices();` then `await $.pumpWidgetAndSettle(const MyApp());` — **never `app.main()`**. `main()` wraps startup in `CrashReporter.runGuarded` and overrides `FlutterError.onError`, which clashes with the test harness. `initServices()` (in `lib/main.dart`) is the single source of the service registration order, shared by `main()` and the tests — add new permanent services there, not in `main()`.
- **Clean state per test**: `clearPackageData=true` (in `android/app/build.gradle.kts`) wipes storage before each test, so every test starts **logged out on the login screen**. A test that needs an authenticated screen must call `loginAsTestUser($)` first.
- **Credentials**: never hard-code them. Read via `String.fromEnvironment('TEST_USERNAME' / 'TEST_PASSWORD')`, pass with `--dart-define=TEST_USERNAME=... --dart-define=TEST_PASSWORD=...`, and mark backend-dependent tests `skip: !hasCredentials` (from the harness) so the suite still runs without them. These tests hit the real backend through the current ngrok URL in `ApiProvider`.
- **Finders**: prefer visible text (`$('Sign In')`) for buttons/labels; for inputs and icon-only widgets add a `Key` in the view and find it with `$(#keyName)` — e.g. the login fields use `Key('loginUsernameField')` / `Key('loginPasswordField')`. Name new keys `<screen><Element>` in camelCase.
- **Waiting**: screens use Skeletonizer shimmer, which never "settles". Use `$('…').waitUntilVisible(timeout: ...)` for content after an API call rather than relying on `pumpAndSettle`.
- **Patrol gotchas found while writing the suite**: tap with `settlePolicy: SettlePolicy.noSettle` when the result is a GetX snackbar (the default settle outlives the 3 s snackbar); `enterText` unfocuses by default, so use `hideKeyboard: false` on the shared `SearchBarWidget` (its submit ✓ icon only exists while focused); hint text and SnackBars under a dialog barrier aren't hit-testable — use `waitUntilExists`, not `waitUntilVisible`.
- **Scanner flows**: the camera can't be driven in a test. Exercise serial/scan logic through the **manual-entry** path (keyboard button in `ScannerPage` / the qty+serial dialogs) instead of `mobile_scanner`.
- **Native setup (already done — keep it intact)**: `testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"`, `ANDROIDX_TEST_ORCHESTRATOR` + `androidTestUtil("androidx.test:orchestrator:...")` in `android/app/build.gradle.kts`; `android/app/src/androidTest/java/com/example/getx_project/MainActivityTest.java`; the `patrol:` block (app name, Android package, iOS bundle id) in `pubspec.yaml`. Upgrading `patrol` requires a matching `patrol_cli` — check Patrol's compatibility table.
- **Known warning**: the build warns that the `patrol` plugin still applies the Kotlin Gradle Plugin (not Built-in Kotlin). It builds fine today; a future Flutter may reject it until Patrol ships an update.

## Architecture

This is a Flutter warehouse management app using the **GetX** pattern throughout. The app is organized under `lib/app/` with the following layers:

### Layer Responsibilities

- **`data/models/`** — Plain Dart model classes with `fromJson`/`toJson`.
- **`data/providers/`** — All HTTP calls. Every provider extends `ApiProvider` (which extends `GetConnect`) and inherits the base URL and bearer token injection automatically. Providers call `checkResponse(response)` immediately after every `await get/post/put/delete` call — this throws a descriptive exception for null statusCode or non-2xx responses (preferring the server's `message` field, then appending any `error`/`errors` detail). After `checkResponse`, providers parse and return typed objects. They never catch errors; that is `ApiExecutor`'s job. **Prefer the shared `ApiProvider` helpers** for the three common shapes instead of re-writing `get → checkResponse → parse`: `getList<T>(path, Model.fromJson, {query})` for a `{"data":[...]}` list (null-tolerant), `getMap(path, {query})` for a JSON-object body (pagination envelopes), and `postMap(path, body)` for a POST returning a JSON object. Only single-model getters (`Model.fromJson(response.body['data'])`) and custom parses stay inline.
- **`helpers/api_excecutor.dart`** — `ApiExecutor.run()` is the single wrapper for all controller-level API calls. It checks connectivity, gates on `isLoading` to prevent double-calls, runs the provider task, and shows an `errorAlert` on failure (stripping the `"Exception: "` prefix for clean user-facing messages). Returns `null` on any error so controllers can do a simple `if (data == null) return;`.
- **`services/`** — Long-lived `GetxService` singletons registered in `main()` as `permanent: true`: `AuthService` (token/username/roles stored in `get_storage`), `ApiProvider` (HTTP client), `NetworkService` (connectivity monitoring).
- **`middleware/auth_middleware.dart`** — `AuthMiddleware` is applied to protected routes in `AppPages`; it redirects to `/login` if no token is stored.
- **`modules/`** — Feature modules, each with `bindings/`, `controllers/`, and `views/` subfolders. A binding uses `Get.lazyPut()` to wire providers and controllers together.
- **`routes/`** — `app_routes.dart` defines path constants; `app_pages.dart` maps them to views + bindings + optional middleware.
- **`global/`** — Shared code: `alert.dart` (snackbar helpers), `functions.dart` (formatting/utility), `size_config.dart` (responsive sizing), `variables.dart` (palette constants), `widget/` (reusable widgets), `styles/app_text_style.dart`. Every screen except Home uses the shared chrome: `accent.dart` (`AppAccent` enum — the single color source — plus `navyGradient`, `accentFor(name)`, `readableOnWhite(color)`), `widget/app_header.dart` (`appHeader` navy AppBar, `obxHeader` for Rx subtitles, `headerAction`), `widget/accent_header_card.dart` (`accentHeaderCard` patterned card under the AppBar with `HeaderStat` / `AccentProgress` / `ProgressSegment`, `headerFooterText`; `accentMetricCard` + `HeaderMetric` — the same card as a summary of side-by-side metrics, each with its own gradient icon tile, used by Products), `widget/accent_pill.dart` (`accentPill`, `statusPill` for API colors), `widget/app_buttons.dart` (`navyButton` main action, `accentOutlineButton`) and `widget/stock_direction_icon.dart` (`stockDirectionIcon` IN/OUT leading), `widget/stock_level_tile.dart` (`stockLevelTile` product-row leading: remaining qty colored by `StockLevel` ok/low/out, low = under 10). The receive/outflow screens share three widget files: `widget/order_menu_widgets.dart` (menu hero/section/tile, `orderMenuInfoCard`, `decorCircle`), `widget/order_list_widgets.dart` (list card, pagination footer, `orderSummaryHeader` + `lineTotals` for Item Summary, `orderRecordHeader` for Receive/Outflow Order detail, item-summary tile, serial line + dialog), and `widget/order_fill_widgets.dart` (`orderFillItemHeader`, `orderFillResultsTitle`, scan FAB, navy bottom bar). Master lists (Category/Brand/Unit) use `MasterListView` + `masterListCard(kind: MasterKind.x)`. The scan-flow quantity/serial dialogs (batch qty, other-item qty, receive item qty+expiry, receive number) live in `widget/qty_input_dialogs.dart` — each owns its `TextEditingController` inside a `StatefulWidget` so it is disposed only after the dialog's exit animation. **Never** `dispose()` a controller right after `await Get.dialog(...)`: the future resolves the instant `Get.back()` fires, while the field is still mounted for the close animation, which throws "A TextEditingController was used after being disposed".

### Key Patterns

**Cursor-based pagination** — List controllers hold `cursorNext` (`RxnString`) and `hasMore` (`RxBool`). `loadProducts()` resets the cursor and fetches the first page; `loadMore()` appends the next page. This pattern is used across `product`, `receive_order`, `outflow_order`, and `transaction` modules. The end-of-list line is always `NoMoreDataFooter(size: size)` (`functions_widget.dart`) — it adds bottom room plus the nav-bar inset; don't hand-roll a "No more data" `Text`. **Exception:** the `delivery` module's `GET /delivery` is **not** paginated server-side (returns all rows), so `DeliveryListController` loads everything once and filters/sorts/status-filters **client-side** — no cursor.

**Debounced search** — Search input triggers a 400 ms debounce timer that cancels any pending timer before calling `loadProducts()` again with updated `buildParams()`. Filters (date range, price, qty threshold) are collected in `buildParams()` and sent as query params to the backend.

**Responsive sizing** — `SizeConfig.init(context)` is called once in `MyApp.build`. All sizes throughout the app derive from `SizeConfig.defaultSize` (2.4% of the narrower screen dimension). Pass `size` (the default size value) into widgets rather than hardcoding pixel values.

**Navigation** — All navigation uses `Get.toNamed(AppPages.<constant>)` with named route constants from `app_routes.dart`. Arguments are passed via `Get.toNamed(..., arguments: obj)` and read in the receiving controller via `Get.arguments`.

**Alert helpers** — Use the functions in `global/alert.dart` (`errorAlert`, `successAlertBottom`, `errorAlertBottom`, `warningAlertBottom`, `infoAlertBottom`) for user feedback, not raw `Get.snackbar`. **Snackbar + `Get.back()` pitfall:** in GetX 4.7, `Get.back()` closes an open snackbar *instead of* the route — so a dialog/bottom sheet closed with `Get.back()` right after (or while) a snackbar is showing stays open. **Never call `Get.back()`** — close dialogs, sheets and pages with `closeRoute([result])` from `global/functions.dart`, which pops the root navigator and leaves snackbars alone (covered by `test/helpers/close_route_test.dart`).

**Loading states (Skeletonizer)** — Content/first-load loading uses the **`skeletonizer`** package via shared helpers in `global/widget/skeleton_widgets.dart`, never a plain "Loading…" label. Inside the `Obx`, the loading branch returns a shimmering placeholder that mirrors the real layout: `skeletonOrderList` (lists of `orderListCard`), `skeletonLineList` (`orderSerialLineCard` detail lists), `skeletonSummaryList` (`orderItemSummaryTile` fill/scan lists), or `skeletonGenericList` (product/transaction/master lists). For a screen that shows already-populated/stale data during a refresh, wrap its body in `skeletonize(loading: <flag>, child: <body>)`. Pass the module's accent color (same one its cards use). **Do not** skeletonize button/FAB spinners or infinite-scroll "loading more" footers — those stay as `CircularProgressIndicator`. The legacy `textLoading()` helper is superseded; `textNoData()` is still the empty-state.

**Provider error handling** — Use the shared helpers on `ApiProvider` (`getList`/`getMap`/`postMap`) for the common shapes; only single-model / custom parses stay inline, and those still follow this pattern:
```dart
Future<SomeType> getSomething() async {
  final response = await get('/endpoint');
  checkResponse(response);          // throws for null/non-2xx — do not skip
  return SomeType.fromJson(response.body['data']);
}
```
Never return raw `Response` from a provider. POST methods also call `checkResponse` and return `Map<String, dynamic>` (or a typed model). Do not add try/catch in providers — let exceptions propagate to `ApiExecutor`. `checkResponse` surfaces the backend's `message` and then appends any `error` (string) or `errors` (Laravel validation map, flattened) detail on a new line, so the real cause — not just the generic summary — reaches the user. For a null status (transport failure) it appends GetConnect's `statusText` (e.g. "Broken pipe"). `ApiProvider.get` resends a GET **once** when it died on a stale keep-alive socket (`isStaleConnection`: broken pipe / connection reset) — the ngrok tunnel closes idle connections; POST/PUT/DELETE are never resent. Numeric fields the API sends as DECIMAL strings (`"180000000"`) must go through `safeToInt`, never `json[...] ?? 0` into an `int`.

**Controller API call pattern** — All API calls go through `ApiExecutor.run()`. After the call, a null check is the only error handling needed:
```dart
final data = await ApiExecutor.run(isLoading: isLoading, task: () => provider.getSomething());
if (data == null) return;   // error already shown by ApiExecutor
// use data directly
```
Never check `response.statusCode`, `response.isOk`, or `response.body?['success']` in a controller.

**Screen chrome (all screens except Home)** — The AppBar is always `appHeader(title, accent:, icon:, subtitle:)`: navy gradient, white back arrow (`Key('appBarBackButton')`, always pops via `closeRoute()`; override with `onBack`), and the module color appears **only** in the white icon tile. Rules: **one accent per page** (the tile's `AppAccent`; icon chips, list cards, pills and progress use it); **buttons are navy** (`navyButton`, the fill/scan bottom bar, the FAB ring) — except a button that opens another module uses that module's color ("Create Delivery" / "View Deliveries" = steel); small accent text on white uses `AppAccent.text` (the `*Dark` shades for sky/amber/sage); API colors go through `readableOnWhite`/`statusPill`. The card under the AppBar is `accentHeaderCard` (no solid gradient block); only the hub hero cards keep a full gradient.

**Order-module UI** — All receive/outflow/delivery screens (menus, lists, selection, details, fill/scan, confirm) are thin compositions over the shared `order_*_widgets.dart` files and the components above; do not hand-roll list cards, header cards, stat cards, or bottom bars. Accents (`AppAccent`): **receive** = `navy` (menu/history) / `sky` (By-PO) / `sage` (By-Supplier); **outflow** = `purple` (menu/history/By-Request) / `amber` (By-Customer); **delivery** = `steel`; **inventory** (products, master data, transactions) = `slate`. Hub heroes use `[navyDark, navyMid]`.

**Delivery tracking** — The `delivery` module tracks the logistics leg of a completed outflow order (status Pending/Shipped/Delivered/Cancelled, ETA, address, notes). A delivery is **header-only** (no line items). Created via `POST /outflow-order/createDelivery {id}` — from the outflow detail's "Create Delivery" CTA (shown when `is_have_delivery` is false) **or** the post-submit auto-prompt; both then route to the delivery list (the backend returns no delivery id to deep-link). Status updates go through `PUT /delivery/{id}`, which **requires `status_id` + `updated_by` + `estimate_at` + `address` on every call** — quick status buttons resend current values, falling back to the edit form when ETA/address are missing. `updated_by` is the current user id, resolved lazily from `GET /user/currentDetail` and cached in `AuthService.userId` (the `/login` response omits it). Shared create/confirm logic lives in `modules/delivery/delivery_actions.dart`.

**Serial numbers & `manage_sn`** — `manage_sn` (bool on the `items` table, default `false`) is the **single criterion** for serial tracking: **mobile and backend, receive and outflow all gate on it** — never on `serial_number_type` alone. `serial_number_type` (`UNIQUE`/`BATCH`/`OTHER`) only shapes *how* serials are captured when `manage_sn` is on.

- **`manage_sn == true`** — serial-tracked. The backend auto-generates an SKU per unit (UNIQUE) / per batch entry (BATCH) at receive and stores that SKU as **both `serial_number` and `internal_code`**; it is printed on the label. **Workers always scan the printed SKU label** — at receive to *confirm*, at outflow to pick which stock leaves — and a scanned SKU/serial is **required** on every outflow entry.
- **`manage_sn == false`** — quantity-only everywhere. No serials are generated (receive) or attached (outflow), **even for `UNIQUE`/`BATCH`** items; the stock-transaction qty stands on its own.

**Receive fill** (only when `manage_sn`, split by `serial_number_type`): **BATCH** — worker enters a qty per batch via `addFilledSerial`, producing `filled` entries `{serial, qty, expired_date}`; one line can split across several batch entries (5 = 2 + 3), over-fill is guarded and duplicate serials rejected. **UNIQUE / OTHER** — quantity-only via `addFilledQty` `{qty, expired_date}`. Edit/remove by index (`updateFilledAt`/`removeFilledAt`).

**Outflow scan** (`_onScanTap`): `manage_sn == false` → quantity-only via `setScannedQty` (`{qty}`); otherwise by `serial_number_type` — **UNIQUE** scans unit-by-unit (`scanUnique`, camera stays open), **BATCH/OTHER** scan once then enter qty (`addScannedCode`). Serial entries are `{serial_number, qty}` — **the payload key is `serial_number`** (not `code`); non-serial entries are `{qty}`. On the outflow detail `orderItemSummaryTile`, the action reflects this gate: `manage_sn == true` shows **"Scan"** (`qr_code_scanner_rounded`), `manage_sn == false` shows **"Fill"** (`edit_rounded`) — mirroring the receive tiles, since a quantity-only line just fills a qty rather than scanning a label.

**Serial confirmation** — After `createReceiveData` returns the created RO, `startReceivingItem()` routes to the **Confirm Serials** screen (`RECEIVE_ORDER_CONFIRM`). It loads the RO's actual generated serials (`getReceiveOrderSerials`) and shows the UNIQUE ones — so only `manage_sn` items appear. Scanning a printed SKU label flips it green and POSTs `POST /receive-order/{id}/confirm-serials` (`{codes:[...]}`, one-per-scan or batched), stamping `scanned_at`/`scanned_by` on the `stock_transaction_serials` pivot — persisted and idempotent, so reopening resumes progress.

### Color Palette

All named color constants live in `lib/app/global/variables.dart`. Import it and use the named constants — never use raw `Color(0xFF...)` or `HexColor('#...')` literals in new code.

**Primary palette (navy brand):**
- `navyDark` (`#124076`) — primary dark; AppBar gradient start, card headers
- `navyMid` (`#2A5A8C`) — gradient midpoint
- `navyLight` (`#5B8FA6`) — gradient end / lighter accents

**Accent colors:**
- `skyBlue` (`#4A90D9`) — Latest Transactions section, CTA highlights
- `sageTeal` (`#5B8C7A`) / `sageGreen` — Statistic / nature tones
- `softPurple` (`#7C73C0`) / `mutedPurple` / `lightPurple` — purple accent range
- `amber` (`#C4882A`) — warm accent
- `steelBlue` / `lightSteelBlue` — secondary blue tones

**Text-safe shades / semantic colors:**
- `skyBlueDark` / `amberDark` / `sageTealDark` — small accent text on white (≥ 4.5:1); read them via `AppAccent.x.text`
- `stockInColor` / `stockOutColor` — stock IN/OUT (arrows, `+n` / `-n` quantities)
- `clearOnNavy` — "Clear" icon on the navy bottom bar; `cardOutline` — 1 dp outline on white list cards

Prefer `AppAccent` (`base`, `light`, `text`, `tint(a)`, `gradient`) over picking raw accent constants in screens.

Legacy `hex1`–`hex6` constants remain for backward compat but new code should use named constants.

### Typography

The app uses **Plus Jakarta Sans** throughout via the `google_fonts` package.

- `lib/app/global/styles/app_text_style.dart` — all static methods return `GoogleFonts.plusJakartaSans(...)`. Use these everywhere; never write inline `TextStyle(...)`.
- `lib/main.dart` — font is set via `fontFamily: GoogleFonts.plusJakartaSans().fontFamily` inside `ThemeData`. Do **not** use `GoogleFonts.plusJakartaSansTextTheme()` — it strips AppBar colors in Material3.

Available text styles: `h1`–`h5`, `body`, `bodyBold`, `small`, `info`, `infoBold`, `overline`, `success`, `error`, `iconText`. All accept `size` (from `SizeConfig.defaultSize`), optional `color`, and optional `weight`.

### App Identity (name, icon, splash)

- App display name is **"Warehouse app"** — set in `android/app/src/main/AndroidManifest.xml` (`android:label`) and `ios/Runner/Info.plist` (`CFBundleDisplayName`).
- Launcher icon + splash are generated from `assets/images/logo_short.png` via `flutter_launcher_icons` and `flutter_native_splash` (config blocks in `pubspec.yaml`). The Android adaptive-icon foreground uses `assets/images/logo_short.png`'s padded variant `assets/images/logo_adaptive_fg.png` (logo centered in the ~66% safe zone) on a white background so the mask doesn't clip it.
- After changing the logo, regenerate with: `dart run flutter_launcher_icons` then `dart run flutter_native_splash:create`. Do not hand-edit the generated mipmap/drawable/`styles.xml` files.

### DRY Code

**Don't Repeat Yourself** — Before adding any widget, helper, or logic, check `global/` for an existing counterpart.

- **Widget reuse**: Shared widgets live in `lib/app/global/widget/`. A widget used in two or more modules must be extracted there, not duplicated.
- **Style reuse**: All text styles come from `AppTextStyle`. Never write `TextStyle(...)` inline if an equivalent `AppTextStyle.*` method exists.
- **Color reuse**: Always use named constants from `variables.dart`. Never copy-paste `Color(0xFF...)` literals.
- **Gradient reuse**: The brand gradient is `[navyDark, navyMid]` (or `[navyDark, navyMid, navyLight]`). Define it once as a local getter — never copy-paste the color list.
- **Data classes**: Use private data classes (e.g. `_MenuConfig`) to configure repeated widget builds instead of copy-pasting widget trees. `_MenuConfig` uses `Color color1, color2` (not hex strings).
- **Section headers**: Repeated heading rows (icon + title) belong in a single `_sectionHeader` helper, not duplicated per-section.
- **Dynamic-height layouts**: Use `Row` + `Expanded` instead of `GridView.extent` when child height should be driven by content. `GridView.extent` forces a fixed aspect ratio and overflows when content exceeds it.
- **No dead code**: Delete commented-out code. Use `git log` to recover it if needed.

### Backend

The Laravel backend lives at **`D:\laravel-project\MasterSystemBackend`**.

The API base URL is configured in `ApiProvider.onInit()` (`api_providers.dart`). The current value points to an ngrok tunnel that exposes the local Laravel server; update it there when the URL changes. Authentication uses a Bearer token stored by `AuthService` and automatically injected into every request via `httpClient.addRequestModifier`.

When the ngrok URL is stale or wrong, requests return 404/502. `checkResponse()` in `ApiProvider` catches these and throws `Exception("HTTP 404: Not Found")` (or the server's `message` field if available). `ApiExecutor` surfaces this to the user as a clean snackbar.

**Serial flow (backend)** — `manage_sn` (from the `items` table, surfaced by the PO/OR line `summary` resources) is the single gate: `StockMutationTrait` only touches serials when `manage_sn && serial_number_type ∈ {UNIQUE, BATCH}`.

- **Receive** — `POST /purchase-order/receiveData` → `createReceiveTransactionFromLocal` (`selected_serials => $item['filled']`) generates one `ItemSerialNumber` per unit/batch entry with the **SKU as both `serial_number` and `internal_code`**, plus a `stock_transaction_serials` pivot (`qty` = 1 for UNIQUE, the entry qty for BATCH). `POST /receive-order/{id}/confirm-serials` later stamps `scanned_at`/`scanned_by`.
- **Outflow** — `POST /outflow-request/outflowData` → `createOutflowTransactionFromLocal` attaches exactly the serials the app sent, resolving each via `resolveOutflowSerial()` — matched against `internal_code` **or** `serial_number`, scoped to the line's `item_id` — and marks them out of stock. `OutflowDataRequest` requires `code`/`serial_number` on every scanned entry **when `manage_sn` is true** (`qty` always required). The edit path (`updateOutflowTransactionFromLocal`) mirrors the same `manage_sn` gate, resolving ids via `fillSelectedSerialIds()`.
- **Non-`manage_sn`** lines create only the qty stock transaction — no serials, on either flow. There is **no auto-selection** of serials; they always originate from the app's scan (outflow) or the backend SKU generator (receive).
