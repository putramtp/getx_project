# Patrol E2E Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One Patrol E2E test file per app feature (home, product, product masters, stock transactions, receive, outflow, delivery), running against the real backend on a real Android device, including write flows.

**Architecture:** A shared harness (`patrol_test/common/harness.dart`) owns app launch, login, list-loading waits and camera-permission handling; each feature file composes it. The app only gains `Key`s on text-less widgets — no logic changes. Write tests pick their data dynamically (first open PO / request / delivery).

**Tech Stack:** Flutter 3.47.7 (FVM), GetX, `patrol` 4.10.0, `patrol_cli` 4.8, Android device `140892557H014055`.

**Spec:** `docs/superpowers/specs/2026-10-26-patrol-e2e-suite-design.md`

## Global Constraints

- Tests live in `patrol_test/*_test.dart`; never edit/commit `patrol_test/test_bundle.dart`.
- Boot with `await initServices(); await $.pumpWidgetAndSettle(const MyApp());` — never `app.main()`.
- Every test starts logged out (`clearPackageData=true`); authenticated tests call `loginAsTestUser($)` first.
- Credentials only via `String.fromEnvironment('TEST_USERNAME' / 'TEST_PASSWORD')`; backend tests use `skip: !hasCredentials`.
- New Keys are named `<screen><Element>` camelCase, `const Key('...')`; no app logic changes.
- Wait for API content with `waitUntilVisible(timeout: apiTimeout)` (30 s), never `pumpAndSettle` on shimmer screens.
- Write tests run against a demo/dev tenant only. No candidate data → fail with an explicit message naming the missing data and `DemoTenantSeeder`.
- Run command for every task (Bash, env vars set by the user):
  `patrol test -t patrol_test/<file> --dart-define=TEST_USERNAME=$TEST_USERNAME --dart-define=TEST_PASSWORD=$TEST_PASSWORD`
- Each task ends with `flutter analyze` clean.
- Commit messages follow CLAUDE.md format (conventional subject + bullet body, **no** `Co-Authored-By`). Work on branch `test/patrol-e2e`; commit only if the user has approved committing.

## Review Focus

- **Skeleton matched as data:** a "first card" tap landing on a `Loading code 0000` placeholder → `waitForList` must block until placeholder text is gone (Task 1 test `waitForList ignores skeleton`).
- **Camera permission already granted** (second run on same device, or permission persisted) → `grantCameraIfAsked` must be a no-op, not a timeout failure (Task 6 runs the scanner twice in one test file).
- **Slow ngrok tunnel** (~13 s per call) → every post-API wait uses `apiTimeout`; no bare `pumpAndSettle` after a request.
- **Open data exhausted** (all PO/request lines fully received/outflowed) → explicit `fail('No open PO with a fillable line — reseed DemoTenantSeeder')`, never a silent pass (Tasks 6, 7).
- **Dialog close animation** — entering text then tapping `Save` while a dialog animates out must not throw "TextEditingController was used after being disposed"; tests assert no Flutter error by letting `patrolTest` fail on uncaught exceptions (default) — do not wrap in try/catch.

---

### Task 1: Shared harness + login test refactor

**Files:**
- Create: `patrol_test/common/harness.dart`
- Modify: `patrol_test/login_test.dart`

**Interfaces:**
- Produces (all in `harness.dart`):
  - `const String testUsername`, `const String testPassword`, `const bool hasCredentials`
  - `const Duration apiTimeout = Duration(seconds: 30)`
  - `Future<void> launchApp(PatrolIntegrationTester $)`
  - `Future<void> loginAsTestUser(PatrolIntegrationTester $)` — launches app, signs in, waits for `Quick Access`
  - `Future<void> waitForList(PatrolIntegrationTester $)` — pumps until none of `skeletonTexts` is on screen (polls every 250 ms up to `apiTimeout`, then `fail('List still loading after 30s')`)
  - `const List<String> skeletonTexts = ['Loading code 0000', 'Loading name placeholder', 'Loading placeholder title here', 'Loading item name', 'Loading item name placeholder']`
  - `Future<void> grantCameraIfAsked(PatrolIntegrationTester $)` — `if (await $.platform.mobile.isPermissionDialogVisible(timeout: Duration(seconds: 3))) await $.platform.mobile.grantPermissionWhenInUse();`
  - `String uniqueSuffix()` — `DateTime.now().millisecondsSinceEpoch.toString()`
  - `Future<void> expectScreen(PatrolIntegrationTester $, String appBarTitle)` — `waitUntilVisible` on the title with `apiTimeout`

- [ ] **Step 1:** Create branch `git checkout -b test/patrol-e2e`.
- [ ] **Step 2:** Rewrite `login_test.dart` to import `common/harness.dart` and use `launchApp`, `hasCredentials`, `loginAsTestUser`; keep both existing tests and their assertions. Add test `invalid credentials show an error` (`skip: !hasCredentials`): enter `testUsername` + password `'wrong-${uniqueSuffix()}'`, tap `Sign In`, `$('Error!').waitUntilVisible(timeout: apiTimeout)`, expect `Sign in to continue` still visible.
- [ ] **Step 3:** Run it → FAIL (harness missing, compile error).
- [ ] **Step 4:** Implement `harness.dart` per Interfaces.
- [ ] **Step 5:** Run `login_test.dart` → 3 tests PASS. `flutter analyze` clean.
- [ ] **Step 6:** Commit `test: add shared Patrol harness and login error case`.

### Task 2: Home

**Files:**
- Modify: `lib/app/modules/home/views/home_view.dart:45` — `key: const Key('homeAccountButton')`
- Modify: `lib/app/global/widget/functions_widget.dart:60` — `key: const Key('appBarBackButton')` on the `appBarOrder` back `IconButton`
- Create: `patrol_test/home_test.dart`

**Interfaces:**
- Consumes: Task 1 harness.
- Produces: Keys `homeAccountButton`, `appBarBackButton` (used by every later task to go back).

- [ ] **Step 1: Write tests** (all `skip: !hasCredentials`):
  - `dashboard shows its sections` — after login expect `Quick Access`, `Latest Transactions`, `Statistic`.
  - `quick access tiles open their screens` — table-driven over `{'PRODUCT': 'Product', 'RECEIVE ORDER': 'Receive Order Menu', 'OUTFLOW ORDER': 'Outflow Order Menu', 'Transaction': 'Stock Transactions', 'Category': 'Category', 'Brand': 'Brand', 'Unit': 'Unit'}`: tap tile → `expectScreen(title)` → tap `#appBarBackButton` → `Quick Access` visible. (Product screen title may also appear in its header; assert `findsWidgets`.)
  - `account info dialog opens and closes` — `#homeAccountButton` → `Account Info` → expect `Username`, `Role` → `Close`.
  - `logout returns to login` — `#homeAccountButton` → `Logout` → `Sign in to continue` visible.
- [ ] **Step 2:** Run → FAIL on missing `#homeAccountButton` / `#appBarBackButton`.
- [ ] **Step 3:** Add the two Keys.
- [ ] **Step 4:** Run → PASS; `flutter analyze` clean.
- [ ] **Step 5:** Commit `test: add home Patrol tests`.

### Task 3: Product

**Files:**
- Create: `patrol_test/product_test.dart`
- Modify (only if a step fails for lack of a finder): `lib/app/modules/product/views/product_view.dart:274` — `key: const Key('productSearchField')`

**Interfaces:** Consumes harness, `appBarBackButton`.

- [ ] **Step 1: Write tests** (`skip: !hasCredentials`; each starts `loginAsTestUser` → tap `PRODUCT` → `waitForList`):
  - `product list loads` — expect `Total Products`, `Products list`, `View details` `findsWidgets`.
  - `search narrows to the typed product` — read the first product name from the first `ProductTile` (`$.tester.widget<Text>` of the first item-name `Text` inside `find.byType(ProductTile).first`), tap tooltip `Search`, `enterText` into `#productSearchField`, wait 1 s (debounce 400 ms + API) → `waitForList` → that name visible, `ProductTile` count ≤ count before.
  - `filter popup applies and clears` — tooltip `Filter` → `Filter Options` → `Apply` → `waitForList`; again → `Clear` → `Filter Options` gone.
  - `view details opens product detail` — `View details`.first → `Product Detail`, `Basic Information`, `Pricing` visible.
  - `view transactions opens the transaction list` — `View Transactions`.first → `expectScreen('Transaction')` → `waitForList`.
- [ ] **Step 2:** Run → expect FAIL only on `#productSearchField`.
- [ ] **Step 3:** Add `productSearchField` Key.
- [ ] **Step 4:** Run → PASS; analyze clean.
- [ ] **Step 5:** Commit `test: add product Patrol tests`.

### Task 4: Product masters (category / brand / unit)

**Files:**
- Modify: `lib/app/global/widget/master_list_view.dart:198` — `key: const Key('masterLimitField')`
- Create: `patrol_test/product_master_test.dart`

**Interfaces:** Consumes harness.

- [ ] **Step 1: Write tests** (`skip: !hasCredentials`):
  - `category card opens its products` — `Category` tile → `waitForList` → tap first `masterListCard` (`find.byType` of the card's `InkWell` inside the list, `.first`) → `Product Category` visible.
  - `brand card opens its products` — same with `Brand` → `Product Brand`.
  - `unit card opens the unit dialog` — `Unit` → first card → `Product Unit` → `Close`.
  - `limit dialog rejects invalid input` — `Category` → tooltip `Filter` → `Set Limit` → `enterText` `'abc'` into `#masterLimitField` → `Apply` → `Please enter a valid number` visible.
- [ ] **Step 2:** Run → FAIL on `#masterLimitField`.
- [ ] **Step 3:** Add Key.
- [ ] **Step 4:** Run → PASS; analyze clean.
- [ ] **Step 5:** Commit `test: add product master Patrol tests`.

### Task 5: Stock transactions

**Files:** Create `patrol_test/stock_transaction_test.dart`.

- [ ] **Step 1: Write tests** (`skip: !hasCredentials`):
  - `stock transaction list loads` — `Transaction` tile → `expectScreen('Stock Transactions')` → `waitForList` → either `No stock transaction data.` or ≥1 row.
  - `date filter applies and clears` — tooltip `Filter` → `Filter Options` → `Apply` → `waitForList`; reopen → `Clear` → `Filter has been reset.` visible.
- [ ] **Step 2:** Run → expected PASS (no app change). A FAIL means a wrong finder: fix the test, not the app.
- [ ] **Step 3:** Analyze clean; commit `test: add stock transaction Patrol tests`.

### Task 6: Receive order (read + write)

**Files:**
- Modify (Keys):
  - `lib/app/global/widget/search_bar.dart:42` `searchBarField`, `:59` `searchBarSubmit`
  - `lib/app/global/widget/order_fill_widgets.dart:100` `orderFillFab`
  - `lib/app/global/widget/qty_input_dialogs.dart:111` and `:219` `qtyDialogField`; `:234` `qtyDialogExpiryField`; `:284` `receiveNumberField`
  - `lib/app/global/widget/functions_widget.dart:432` `serialDialogField`
  - `lib/app/modules/receive_order/views/receive_order_confirm_view.dart:122` `receiveConfirmScanFab`
  - `lib/app/global/widget/scanner_page.dart:235` `scannerManualEntryButton` — add optional `Key? key` param to `_circleButton(...)` and pass it to the outer `Material`
- Create: `patrol_test/receive_order_test.dart`

**Interfaces:**
- Consumes: harness (`grantCameraIfAsked`, `uniqueSuffix`, `waitForList`).
- Produces: all Keys above (reused by Tasks 7–8).

- [ ] **Step 1: Write read tests** (`skip: !hasCredentials`, start `RECEIVE ORDER` → `Receive Order Menu`):
  - `menu shows receiving entries` — `Receive Orders`, `By Purchase-order`, `By Supplier`.
  - `receive order list opens a detail` — `Receive Orders` → `Receive Order List` → `waitForList` → tap first card title → `Receive Order Detail`.
  - `purchase order search filters the list` — `By Purchase-order` → `waitForList` → read first card title (PO number) → tap `#searchBarField`, enter it, tap `#searchBarSubmit` → `waitForList` → PO number visible.
  - `supplier list loads` — `By Supplier` → `Supplier List` → `waitForList`.
- [ ] **Step 2: Write write test** `receiving a PO line reaches confirm serials`:
  1. `By Purchase-order` → `waitForList`; iterate cards top-down: open card → `Item Summary` → if `$('Fill')` exists break, else back. None → `fail('No open PO with a fillable line — reseed DemoTenantSeeder')`.
  2. Tap `Fill`.first → `Fill Item` → `#orderFillFab`.
  3. If `Enter Serial Number` shows: enter `E2E-${uniqueSuffix()}` in `#serialDialogField` → `Save`.
  4. Enter `1` in `#qtyDialogField`; if `#qtyDialogExpiryField` exists: tap it → date picker `OK`. Tap `Save` (or `OK`).
  5. `Continue` (bottom bar) until back on `Item Summary`.
  6. Tap `textContaining('Continue to receiving items')` → `Receive Number` → `#receiveNumberField` = `E2E-${uniqueSuffix()}` → `Save` → `textContaining('Continue to Receiving')` → `Continue`.
  7. `Confirm Serials` visible within `apiTimeout`.
  8. If `Nothing to confirm` → `Done` → `Purchase Order List`. Else: read the first `Pending` row's code `Text`, `#receiveConfirmScanFab` → `grantCameraIfAsked` → `#scannerManualEntryButton` → `#serialDialogField` = code → `Save` → `textContaining('Confirmed 1/')` visible → `Done`.
- [ ] **Step 3:** Run → FAIL on missing Keys.
- [ ] **Step 4:** Add all Keys listed in Files.
- [ ] **Step 5:** Run → PASS (run the file twice to cover the already-granted camera case); analyze clean.
- [ ] **Step 6:** Commit `test: add receive order Patrol tests`.

### Task 7: Outflow order (read + write)

**Files:** Create `patrol_test/outflow_order_test.dart`.

**Interfaces:** Consumes harness + Task 6 Keys (`orderFillFab`, `qtyDialogField`, `searchBarField`, `searchBarSubmit`).

- [ ] **Step 1: Write read tests** (start `OUTFLOW ORDER` → `Outflow Order Menu`):
  - `menu shows outflow entries` — `Outflow Orders`, `By Request`, `By Customer`, `Deliveries`.
  - `outflow order list opens a detail` — `Outflow Orders` → `waitForList` → first card → `Outflow Order Detail`.
  - `request and customer lists load` — `By Request` → `Outflow Request List` → `waitForList`; back; `By Customer` → `Customer List` → `waitForList`.
- [ ] **Step 2: Write write test** `outflowing a request line creates a delivery`:
  1. `By Request` → iterate cards for an `Item Summary` with `$('Fill')` (manage_sn false). None → `fail('No open request with a quantity-only line — reseed DemoTenantSeeder')`.
  2. `Fill`.first → `Scan Item` → `#orderFillFab` → `#qtyDialogField` = `1` → `Save` → `Qty: 1` visible → `Continue` until `Item Summary`.
  3. `textContaining('Continue to outflowing items')` → `Continue to Outflowing Items?` → `Continue`.
  4. `textContaining('completed')` within `apiTimeout` → `Create delivery?` → `Create` → `Delivery created.` → `Deliveries` visible.
- [ ] **Step 3:** Run → PASS (no new app change expected; a missing finder means add a Key per Global Constraints and note it in the commit).
- [ ] **Step 4:** Analyze clean; commit `test: add outflow order Patrol tests`.

### Task 8: Delivery (read + write)

**Files:**
- Modify: `lib/app/modules/delivery/views/delivery_detail_view.dart:260` `deliveryEditStatusDropdown`, `:318` `deliveryEditAddressField`
- Create: `patrol_test/delivery_test.dart`

**Interfaces:** Consumes harness, `searchBarField`/`searchBarSubmit` (if Deliveries uses the shared SearchBar; otherwise add `deliverySearchField`).

- [ ] **Step 1: Write read tests** (start `OUTFLOW ORDER` → `Deliveries`):
  - `delivery list loads` — `Deliveries` → `waitForList` → `All` chip visible.
  - `status chip filters the list` — tap the second chip → `waitForList` → every visible card shows that chip's status text, or `No deliveries found.`.
  - `search finds a delivery by code` — read first card code → search it → code visible.
  - `delivery detail opens` — first card → `Delivery Detail`, `Current status`, `Update status`.
- [ ] **Step 2: Write write test** `editing details then marking a status updates the delivery`:
  1. First card → `Delivery Detail` → read `Current status` value.
  2. `Edit details` → `Edit Delivery` → `ETA date` → picker `OK` → `ETA time` → picker `OK` → `#deliveryEditAddressField` = `E2E ${uniqueSuffix()}` → `Save changes` → `textContaining('updated.')` within `apiTimeout`.
  3. If any `textContaining('Mark ')` exists: tap first → `textContaining('updated.')` → `Current status` value differs from step 1. If none (terminal status) → assert the step-2 address text is visible instead.
- [ ] **Step 3:** Run → FAIL on missing Keys.
- [ ] **Step 4:** Add Keys.
- [ ] **Step 5:** Run → PASS; analyze clean.
- [ ] **Step 6:** Commit `test: add delivery Patrol tests`.

### Task 9: Full-suite run + docs

**Files:** Modify `CLAUDE.md` (Testing section).

- [ ] **Step 1:** Run `patrol test --dart-define=TEST_USERNAME=$TEST_USERNAME --dart-define=TEST_PASSWORD=$TEST_PASSWORD` (all files) → all PASS; record total duration.
- [ ] **Step 2:** In `CLAUDE.md` Testing section add: the harness (`patrol_test/common/harness.dart`) and its helpers, the per-feature file list, the new Keys convention list, and that write tests mutate the backend (demo/dev tenant only; reseed with `DemoTenantSeeder` when they fail for missing open data).
- [ ] **Step 3:** Commit `docs: document Patrol E2E suite`.
