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
```

## Architecture

This is a Flutter warehouse management app using the **GetX** pattern throughout. The app is organized under `lib/app/` with the following layers:

### Layer Responsibilities

- **`data/models/`** — Plain Dart model classes with `fromJson`/`toJson`.
- **`data/providers/`** — All HTTP calls. Every provider extends `ApiProvider` (which extends `GetConnect`) and inherits the base URL and bearer token injection automatically. Providers call `checkResponse(response)` immediately after every `await get/post/put/delete` call — this throws a descriptive exception for null statusCode or non-2xx responses (preferring the server's `message` field). After `checkResponse`, providers parse and return typed objects. They never catch errors; that is `ApiExecutor`'s job.
- **`helpers/api_excecutor.dart`** — `ApiExecutor.run()` is the single wrapper for all controller-level API calls. It checks connectivity, gates on `isLoading` to prevent double-calls, runs the provider task, and shows an `errorAlert` on failure (stripping the `"Exception: "` prefix for clean user-facing messages). Returns `null` on any error so controllers can do a simple `if (data == null) return;`.
- **`services/`** — Long-lived `GetxService` singletons registered in `main()` as `permanent: true`: `AuthService` (token/username/roles stored in `get_storage`), `ApiProvider` (HTTP client), `NetworkService` (connectivity monitoring).
- **`middleware/auth_middleware.dart`** — `AuthMiddleware` is applied to protected routes in `AppPages`; it redirects to `/login` if no token is stored.
- **`modules/`** — Feature modules, each with `bindings/`, `controllers/`, and `views/` subfolders. A binding uses `Get.lazyPut()` to wire providers and controllers together.
- **`routes/`** — `app_routes.dart` defines path constants; `app_pages.dart` maps them to views + bindings + optional middleware.
- **`global/`** — Shared code: `alert.dart` (snackbar helpers), `functions.dart` (formatting/utility), `size_config.dart` (responsive sizing), `variables.dart` (palette constants), `widget/` (reusable widgets), `styles/app_text_style.dart`. The receive/outflow screens share three widget files: `widget/order_menu_widgets.dart` (menu hero/section/tile), `widget/order_list_widgets.dart` (list card, pagination footer, detail header, item-summary tile, serial line + dialog), and `widget/order_fill_widgets.dart` (fill/scan header, stats card, scan FAB, bottom bar). The scan-flow quantity/serial dialogs (batch qty, other-item qty, receive item qty+expiry, receive number) live in `widget/qty_input_dialogs.dart` — each owns its `TextEditingController` inside a `StatefulWidget` so it is disposed only after the dialog's exit animation. **Never** `dispose()` a controller right after `await Get.dialog(...)`: the future resolves the instant `Get.back()` fires, while the field is still mounted for the close animation, which throws "A TextEditingController was used after being disposed".

### Key Patterns

**Cursor-based pagination** — List controllers hold `cursorNext` (`RxnString`) and `hasMore` (`RxBool`). `loadProducts()` resets the cursor and fetches the first page; `loadMore()` appends the next page. This pattern is used across `product`, `receive_order`, `outflow_order`, and `transaction` modules. **Exception:** the `delivery` module's `GET /delivery` is **not** paginated server-side (returns all rows), so `DeliveryListController` loads everything once and filters/sorts/status-filters **client-side** — no cursor.

**Debounced search** — Search input triggers a 400 ms debounce timer that cancels any pending timer before calling `loadProducts()` again with updated `buildParams()`. Filters (date range, price, qty threshold) are collected in `buildParams()` and sent as query params to the backend.

**Responsive sizing** — `SizeConfig.init(context)` is called once in `MyApp.build`. All sizes throughout the app derive from `SizeConfig.defaultSize` (2.4% of the narrower screen dimension). Pass `size` (the default size value) into widgets rather than hardcoding pixel values.

**Navigation** — All navigation uses `Get.toNamed(AppPages.<constant>)` with named route constants from `app_routes.dart`. Arguments are passed via `Get.toNamed(..., arguments: obj)` and read in the receiving controller via `Get.arguments`.

**Alert helpers** — Use the functions in `global/alert.dart` (`errorAlert`, `successAlertBottom`, `errorAlertBottom`, `warningAlertBottom`, `infoAlertBottom`) for user feedback, not raw `Get.snackbar`.

**Loading states (Skeletonizer)** — Content/first-load loading uses the **`skeletonizer`** package via shared helpers in `global/widget/skeleton_widgets.dart`, never a plain "Loading…" label. Inside the `Obx`, the loading branch returns a shimmering placeholder that mirrors the real layout: `skeletonOrderList` (lists of `orderListCard`), `skeletonLineList` (`orderSerialLineCard` detail lists), `skeletonSummaryList` (`orderItemSummaryTile` fill/scan lists), or `skeletonGenericList` (product/transaction/master lists). For a screen that shows already-populated/stale data during a refresh, wrap its body in `skeletonize(loading: <flag>, child: <body>)`. Pass the module's accent color (same one its cards use). **Do not** skeletonize button/FAB spinners or infinite-scroll "loading more" footers — those stay as `CircularProgressIndicator`. The legacy `textLoading()` helper is superseded; `textNoData()` is still the empty-state.

**Provider error handling** — Every provider method follows this pattern:
```dart
Future<SomeType> getSomething() async {
  final response = await get('/endpoint');
  checkResponse(response);          // throws for null/non-2xx — do not skip
  return SomeType.fromJson(response.body['data']);
}
```
Never return raw `Response` from a provider. POST methods also call `checkResponse` and return `Map<String, dynamic>` (or a typed model). Do not add try/catch in providers — let exceptions propagate to `ApiExecutor`.

**Controller API call pattern** — All API calls go through `ApiExecutor.run()`. After the call, a null check is the only error handling needed:
```dart
final data = await ApiExecutor.run(isLoading: isLoading, task: () => provider.getSomething());
if (data == null) return;   // error already shown by ApiExecutor
// use data directly
```
Never check `response.statusCode`, `response.isOk`, or `response.body?['success']` in a controller.

**Order-module UI** — All receive/outflow/delivery screens (menus, lists, selection, details, fill/scan, confirm) are thin compositions over the shared `order_*_widgets.dart` files; do not hand-roll list cards, gradient headers, stat cards, or bottom bars. Each module/sub-flow has a fixed accent color: **receive** = `navyDark` (hero) / `skyBlue` (By-PO) / `sageTeal` (By-Supplier); **outflow** = `mutedPurple`/`softPurple` (hero) / `mutedPurple` (By-Request) / `amber` (By-Customer); **delivery** = `steelBlue` / `lightSteelBlue`. AppBar `hex1`/`hex2` and tile accents must match the module's color.

**Delivery tracking** — The `delivery` module tracks the logistics leg of a completed outflow order (status Pending/Shipped/Delivered/Cancelled, ETA, address, notes). A delivery is **header-only** (no line items). Created via `POST /outflow-order/createDelivery {id}` — from the outflow detail's "Create Delivery" CTA (shown when `is_have_delivery` is false) **or** the post-submit auto-prompt; both then route to the delivery list (the backend returns no delivery id to deep-link). Status updates go through `PUT /delivery/{id}`, which **requires `status_id` + `updated_by` + `estimate_at` + `address` on every call** — quick status buttons resend current values, falling back to the edit form when ETA/address are missing. `updated_by` is the current user id, resolved lazily from `GET /user/currentDetail` and cached in `AuthService.userId` (the `/login` response omits it). Shared create/confirm logic lives in `modules/delivery/delivery_actions.dart`.

**Serial numbers & `manage_sn`** — `manage_sn` (bool on the `items` table, default `false`) is the **single criterion** for serial tracking: **mobile and backend, receive and outflow all gate on it** — never on `serial_number_type` alone. `serial_number_type` (`UNIQUE`/`BATCH`/`OTHER`) only shapes *how* serials are captured when `manage_sn` is on.

- **`manage_sn == true`** — serial-tracked. The backend auto-generates an SKU per unit (UNIQUE) / per batch entry (BATCH) at receive and stores that SKU as **both `serial_number` and `internal_code`**; it is printed on the label. **Workers always scan the printed SKU label** — at receive to *confirm*, at outflow to pick which stock leaves — and a scanned SKU/serial is **required** on every outflow entry.
- **`manage_sn == false`** — quantity-only everywhere. No serials are generated (receive) or attached (outflow), **even for `UNIQUE`/`BATCH`** items; the stock-transaction qty stands on its own.

**Receive fill** (only when `manage_sn`, split by `serial_number_type`): **BATCH** — worker enters a qty per batch via `addFilledSerial`, producing `filled` entries `{serial, qty, expired_date}`; one line can split across several batch entries (5 = 2 + 3), over-fill is guarded and duplicate serials rejected. **UNIQUE / OTHER** — quantity-only via `addFilledQty` `{qty, expired_date}`. Edit/remove by index (`updateFilledAt`/`removeFilledAt`).

**Outflow scan** (`_onScanTap`): `manage_sn == false` → quantity-only via `setScannedQty` (`{qty}`); otherwise by `serial_number_type` — **UNIQUE** scans unit-by-unit (`scanUnique`, camera stays open), **BATCH/OTHER** scan once then enter qty (`addScannedCode`). Serial entries are `{serial_number, qty}` — **the payload key is `serial_number`** (not `code`); non-serial entries are `{qty}`.

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
