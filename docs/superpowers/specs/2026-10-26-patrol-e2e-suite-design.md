# Patrol E2E Suite — Design

Date: 2026-10-26
Status: Draft (awaiting review)

## Goal

Cover every user-facing feature of the warehouse app with Patrol E2E tests that run
against the real backend on a real Android device, including the write flows
(receive, outflow, delivery). Features are implemented and verified one at a time.

## Decisions (from brainstorming)

| Topic | Decision |
|---|---|
| Backend scope | Read **and** write. Write tests create real stock transactions, serials and deliveries. |
| Test data | Chosen **dynamically in the app**: the first PO / request / delivery that still allows the action. No backend seeder, no fixture IDs. |
| Structure | **One file per feature + shared harness** (approach A). No page objects. |
| Credentials | `--dart-define=TEST_USERNAME=... --dart-define=TEST_PASSWORD=...`; backend-dependent tests use `skip: !hasCredentials`. |
| Target backend | Demo/dev tenant only — write tests mutate data permanently. |

## Constraints discovered in the code

- The shared `SearchBar` (`global/widget/search_bar.dart`) searches only when the
  suffix check icon is tapped; that icon shows only while the field is focused. Enter
  does nothing. The Product screen is the exception (400 ms debounce on typing).
- Skeleton placeholders render real text (`Loading code 0000`, `Loading placeholder
  title here`, `Loading item name`, …). "Tap first card" must wait for these to
  disappear.
- `ScannerPage` always mounts `MobileScanner`, even on the manual path → the camera
  permission dialog must be granted via `$.platform`. Manual entry is the icon-only
  keyboard button at `scanner_page.dart:235`.
- Fill / Scan pages are opened with `Get.to(...)`, not named routes; reach them via the
  "Fill" / "Scan" tile action.
- `stock_transaction_detail_view.dart` is not registered in `AppPages` → not tested.
- `successAlertBottom` title is "Success"; error "Error"; warning "Warning".

## Components

### `patrol_test/common/harness.dart`

- `hasCredentials` — both dart-defines non-empty.
- `launchApp($)` — `initServices()` + `pumpWidgetAndSettle(const MyApp())`.
- `loginAsTestUser($)` — fills `#loginUsernameField` / `#loginPasswordField`, taps
  `Sign In`, waits for `Quick Access` (30 s, matches `AppConfig.apiTimeoutSeconds`).
- `waitForList($)` — waits until skeleton placeholder text is gone (then real content
  or the empty-state text is on screen).
- `grantCameraIfAsked($)` — grants the native permission dialog if visible.
- `uniqueSuffix()` — timestamp-based suffix for receive numbers / addresses.
- Timeout constants (`apiTimeout`).

`patrol_test/login_test.dart` is refactored to use the harness.

### Keys added to the app (Key only — no logic change)

| Key | Location |
|---|---|
| `homeAccountButton` | `modules/home/views/home_view.dart:45` |
| `appBarBackButton` | `global/widget/functions_widget.dart:60` |
| `searchBarField`, `searchBarSubmit` | `global/widget/search_bar.dart:42`, `:59` |
| `orderFillFab` | `global/widget/order_fill_widgets.dart:100` |
| `receiveConfirmScanFab` | `modules/receive_order/views/receive_order_confirm_view.dart:122` |
| `scannerManualEntryButton` | `scanner_page.dart:235` |
| `qtyDialogField` | quantity TextFields in `global/widget/qty_input_dialogs.dart` |
| `receiveNumberField` | `global/widget/qty_input_dialogs.dart:284` |
| `serialDialogField` | `global/widget/functions_widget.dart:432` |
| `masterLimitField` | `global/widget/master_list_view.dart:198` |
| `deliveryEditStatusDropdown`, `deliveryEditAddressField` | `modules/delivery/views/delivery_detail_view.dart:260`, `:318` |

Icon buttons that already have a tooltip (Product Sort/Search/Filter, SearchBar
Sort/Filter) are found by tooltip instead of a new Key.

## Test files and scenarios

Implemented and verified in this order; each must pass on the device before the next
starts.

1. **`home_test.dart`**
   - Dashboard sections visible (`Quick Access`, `Latest Transactions`, `Statistic`).
   - Each Quick Access tile (PRODUCT, RECEIVE ORDER, OUTFLOW ORDER, Transaction,
     Category, Brand, Unit) opens the screen with the expected AppBar title, then back.
   - Account → `Account Info` dialog → `Close`.
   - Account → `Logout` → `Sign in to continue`.
2. **`product_test.dart`**
   - List loads (`Total Products`, `Products list`).
   - Search by the first product's name narrows the list.
   - Filter popup: `Apply` and `Clear`.
   - `View details` → Product Detail (`Basic Information`, `Pricing`) → back.
   - `View Transactions` → `Transaction` screen.
3. **`product_master_test.dart`**
   - Category: first card → `Product Category` screen.
   - Brand: first card → `Product Brand` screen.
   - Unit: first card → `Product Unit` dialog → `Close`.
   - Limit dialog: invalid input → `Please enter a valid number`.
4. **`stock_transaction_test.dart`**
   - List loads; date filter `Apply` and `Clear`.
5. **`receive_order_test.dart`**
   - Read: menu tiles; `Receive Order List` → detail; `Purchase Order List` search;
     `Supplier List` loads.
   - Write: open the first PO whose Item Summary has a `Fill` tile → fill qty 1 (fill
     expiry via date picker if shown; for BATCH + `manage_sn` enter serial
     `E2E-<ts>` first) → `Continue to receiving items` → receive number `E2E-<ts>` →
     `Continue` → lands on `Confirm Serials`. If a `Pending` label exists, read its code
     from the screen and confirm it through the scanner's manual-entry button
     (expect `Confirmed 1/n`); otherwise expect `Nothing to confirm` → `Done`.
6. **`outflow_order_test.dart`**
   - Read: menu tiles; `Outflow Order List` → detail; `Outflow Request List` and
     `Customer List` load.
   - Write: open the first request with a **`Fill`** tile (`manage_sn == false`; the
     Scan path needs a serial known to be in stock, which cannot be chosen
     dynamically) → qty 1 → `Continue to outflowing items` → `Continue` → expect
     `completed` → `Create delivery?` → `Create` → `Deliveries` screen.
7. **`delivery_test.dart`**
   - Read: list loads; status chip filter; search; first card → `Delivery Detail`.
   - Write: `Edit details` → address `E2E <ts>` + ETA → `Save changes` → expect
     `updated`; then tap an available `Mark <status>` and expect the
     `Current status` value to change.

## Error handling / data exhaustion

Write tests consume open PO/request quantity. When no candidate is found the test
**fails with an explicit message** (e.g. `No open PO with a fillable line — reseed
DemoTenantSeeder`) rather than passing silently.

## Verification

Each file: `patrol test -t patrol_test/<file> --dart-define=TEST_USERNAME=...
--dart-define=TEST_PASSWORD=...` on the attached device, plus `flutter analyze`
clean, before moving on. Credentials are never committed.

## Out of scope

- Camera-based scanning (manual-entry path only).
- Outflow `Scan` (serial) path, receive-by-supplier write path (read-only coverage).
- iOS.
