# PROGRESS.md

Session log of all changes, plans, and modified files.

---

## Session: 2026-06-29 — Deliverable Gating, Product Name Sort, Delivery List Flicker Fix

### 1. Delivery restricted to `DO` (Delivery Order) type outflow orders
Only `DO` type outflow orders can have a delivery; other types (e.g. `SI` sales invoices) must not show the delivery CTA.
- The **"Create Delivery" / "View Deliveries" CTA** on the outflow order detail (`_deliveryCta`) now hides entirely (`SizedBox.shrink()`) for non-deliverable orders.
- Initially gated client-side (`type == 'DO'`), then **moved the rule to the backend** (per follow-up): `OutflowOrderResource` now emits **`is_deliverable`** (`$this->type === 'DO'`). Flutter's `OutflowOrderDetailModel` parses `is_deliverable`, and the controller getter reads it (`outflowOrderDetail.value?.isDeliverable ?? false`) instead of inferring from `type`. The deliverability rule now lives in one authoritative place on the server.
- The post-submit "Create delivery now?" auto-prompts (by-request / by-customer) were left unchanged — app-created outflow orders are always stamped `type = 'DO'` by `OutflowOrderService::newRequest`, so they're already DO-only.

### 2. Product summary lists ordered by name (alphabetical)
The product summary endpoints cursor-paginated by `items.id desc`, so the existing client-side `toggleSort` only reordered the loaded page. Moved sorting to the backend so the **whole list** is alphabetical.
- **Backend** (`StockTransactionController`): `summaryCurcor`, `summaryCurcorByItemCategory`, and `summaryCurcorByItemBrand` now `orderBy('items.name', $sortDir)` + `orderBy('items.id', $sortDir)` (id = stable cursor tiebreaker). Each accepts an optional **`sort_dir`** query param (`asc`/`desc`), defaulting to `asc`. `items.name` is already in the `groupBy`, so it's valid for cursor pagination.
- **Flutter** (`product_controller.dart`): `buildParams()` sends `'sort_dir'` from `isAscending`; `toggleSort()` now flips `isAscending` and calls `loadProducts()` (reload from backend) instead of the old in-memory `productSummaries.sort(...)`. The by-category / by-brand screens have no sort toggle, so they pick up the new `asc`-by-name default automatically (no Flutter change needed there).

### 3. Fix: delivery list flashed "No deliveries found." before showing the list
`DeliveryListController.loadDeliveries()` made two awaited calls. `ApiExecutor.run` flips `isLoading` off in its `finally`, so after the **first** call (fetch deliveries) the flag went false while the observable `deliveries` list was still empty — `_applyView()` only runs after the **second** call (fetch statuses). In that gap the `Obx` rendered the empty state, then the list popped back.
- Fix: `loadDeliveries()` now sets `isLoading = true` itself, passes **throwaway flags** (`false.obs`) to both inner `ApiExecutor.run` calls so they don't toggle the shared flag mid-load, and flips it back to `false` in a `finally` only after both fetches **and** `_applyView()` complete. The skeleton stays continuous — no empty-state flash. Bonus: `statusById` is now fully populated before `deliveries` is assigned, so status pill colors are correct on first paint (no grey flash).

### Modified Files
| File | Change |
|------|--------|
| **Backend** | |
| `app/Http/Resources/Inventory/OutflowOrderResource.php` | Added `is_deliverable` (`type === 'DO'`) |
| `app/Http/Controllers/Inventory/StockTransactionController.php` | `summaryCurcor` / `...ByItemCategory` / `...ByItemBrand` order by `items.name` (+ `items.id` tiebreaker); optional `sort_dir` param |
| **Flutter** | |
| `data/models/outflow_order_detail_model.dart` | Added `isDeliverable` (`is_deliverable`) to field/ctor/fromJson/toJson |
| `modules/outflow_order/controllers/outflow_order_list_detail_controller.dart` | `isDeliverable` getter reads backend flag |
| `modules/outflow_order/views/outflow_order_list_detail_view.dart` | `_deliveryCta` hides for non-deliverable orders |
| `modules/product/controllers/product_controller.dart` | `sort_dir` in `buildParams`; `toggleSort` reloads from backend |
| `modules/delivery/controllers/delivery_list_controller.dart` | `loadDeliveries` holds `isLoading` across both fetches + `_applyView` |

---

## Session: 2026-06-29 — Skeletonizer Loading States (app-wide)

### Goal
Replace every content/first-load "Loading…" placeholder across the app with **Skeletonizer** shimmer placeholders that mirror the real layout.

### What changed
- Added the **`skeletonizer`** package (`^1.4.3`, via `flutter pub add`).
- New shared helper `lib/app/global/widget/skeleton_widgets.dart`:
  - `skeletonOrderList(size, {accent, count})` — fake `orderListCard` rows (receive/outflow/delivery lists + PO/supplier/request/customer selection lists).
  - `skeletonLineList(size, {accent})` — fake `orderSerialLineCard` rows (record-detail line lists).
  - `skeletonSummaryList(size, {accent})` — fake `orderItemSummaryTile` rows (fill/scan item summaries).
  - `skeletonGenericList(size, {count})` — generic card rows for non-order lists (products, transactions, categories, brands, units).
  - `skeletonize({loading, child})` — wraps populated content so it shimmers during a refresh.
- Swapped the loading branch (`if (isLoading) return textLoading(...)`) for the matching helper in **30 view files** across `delivery`, `receive_order`, `outflow_order`, `product`, `product-category`, `product-brand`, `product-unit`, `transaction`, and `home`. Each uses its module accent (skyBlue/sageTeal/navy, mutedPurple/amber/softPurple, steelBlue, etc.).
- Detail/dashboard screens that show stale data during refresh (product detail, transaction detail, home KPI grid) were wrapped in `skeletonize(...)` instead.

### Notes / deliberately left as-is
- Button/FAB spinners, submit-action spinners, and infinite-scroll "loading more" footers (`orderListFooter` / bottom `CircularProgressIndicator`) stay as real spinners — Skeletonizer is for content placeholders only.
- Home **pie chart** kept its existing "No data" empty state (fl_chart canvas doesn't skeletonize cleanly).
- `textNoData()` remains the empty-state helper; the legacy `textLoading()` is now superseded (definition left in `functions_widget.dart`, no callers).
- `flutter analyze`: **No issues found** (whole project).

### Fix follow-up — "Vertical viewport was given unbounded height"
The skeleton list helpers initially used a plain `ListView` (no `shrinkWrap`). That works inside `Expanded` (bounded) but crashed where a skeleton is placed in an **unbounded** context — `product_view` (`SliverToBoxAdapter`) and `home_view` (scrolling `Column`). Fixed by making all four list helpers `shrinkWrap: true` with scrollable physics (removed `NeverScrollableScrollPhysics`): they now size to content in scroll/sliver contexts and scroll (instead of overflowing) inside bounded `Expanded` areas. One change in `skeleton_widgets.dart` covers every callsite.

### Tweak — removed skeleton from the home "Overview" grid
The home dashboard KPI grid (`_buildDashboardGrid`, the "Overview" section) was wrapped in `skeletonize(...)`; removed it (and the now-unused `isLoading` local) so the grid renders directly — its cards already show `0` until data loads, which reads cleaner than a shimmer. Latest Transactions still uses `skeletonGenericList`; the `skeleton_widgets.dart` import stays (still used there).

### Modified / Added Files
| File | Change |
|------|--------|
| `pubspec.yaml` | Added `skeletonizer: ^1.4.3` |
| `global/widget/skeleton_widgets.dart` | **New** — shared skeleton placeholders |
| `modules/delivery/views/*` (list, detail) | Loading → skeleton |
| `modules/receive_order/views/*` (9 files) | Loading → skeleton |
| `modules/outflow_order/views/*` (8 files) | Loading → skeleton |
| `modules/product/views/*`, `product-category/*`, `product-brand/*`, `product-unit/*` (8 files) | Loading → skeleton |
| `modules/transaction/views/*` (2 files), `modules/home/views/home_view.dart` | Loading → skeleton / `skeletonize` |
| `CLAUDE.md` | Added the "Loading states (Skeletonizer)" convention |

---

## Session: 2026-06-29 — New Feature: Delivery Tracking & Dispatch

### Goal
Surface the backend's existing delivery endpoints in the app: create a delivery from a completed outflow order, then track/update its status (Pending → Shipped → Delivered / Cancelled), ETA, address, and notes from the phone. New `delivery` module mirroring `outflow_order`. **No backend changes.**

### Backend contract notes (shaped the design)
- **`GET /delivery` has no pagination / search / filter** — returns every delivery at once. Breaks the app's cursor-pagination norm, so the delivery list loads all and filters **client-side** (search by code/customer/outflow code, sort, status-chip filter).
- **A delivery is header-only** — no line items/serials. Fields: `code`, `customer`, `outflow_order_code`, `status_id/name`, `estimate_at` (date), `estimate_time`, `address`, `description`, `updated_name`. So the detail screen is a logistics/status card, not an item list.
- **`PUT /delivery/{id}` requires `status_id` + `updated_by` + `estimate_at` + `address` on every call** (estimate_time/description optional). Quick status changes therefore resend the current ETA/address/notes; if those are missing (a freshly-created delivery has neither), the quick action falls back to the edit form.
- **`updated_by` needs the user id**, but `/login` returns only token/name/roles. Resolved lazily from **`GET /user/currentDetail`** (`data.id`) and cached in `AuthService` (new `userId` field, persisted).
- **`OutflowOrderResource` exposes `is_have_delivery`** (bool) but **no `delivery_id`**, and `POST /outflow-order/createDelivery` returns the outflow order (not the delivery). So after creating, the app routes to the **delivery list** (the hub) rather than deep-linking a specific delivery.

### What was built
- **Create from two entry points** (per decision): a **"Create Delivery" button** on the outflow order detail (shown when `!is_have_delivery`, else "View Deliveries"), **and** an **auto-prompt** ("Create delivery now?") after a successful outflow submit (by-request & by-customer). Both read the created outflow id from the submit response (`data.data.id`) / the detail's order id.
- **Delivery list** — all deliveries, client-side search/sort + colored status-chip filters (colors from `GET /delivery-status`).
- **Delivery detail** — logistics card + **quick status buttons** ("Mark Shipped/Delivered/Cancelled") + an **edit form** bottom sheet (status, ETA date+time pickers, address, notes).
- Shared `delivery_actions.dart` holds the create + confirm-dialog logic (used by the detail button and both submit controllers) to stay DRY.
- **Accent:** `steelBlue` / `lightSteelBlue` (distinct from outflow's purple).

### Added / Modified Files
| File | Change |
|------|--------|
| `data/models/delivery_model.dart` | **New** — shared list+detail shape |
| `data/models/delivery_status_model.dart` | **New** — status option (id/name/color) |
| `data/providers/delivery_provider.dart` | **New** — getDeliveries / getDeliveryDetail / getDeliveryStatuses / updateDelivery / createDelivery / getCurrentUserId |
| `modules/delivery/controllers/delivery_list_controller.dart` | **New** — load-all + client-side search/sort/status filter; status colors |
| `modules/delivery/controllers/delivery_detail_controller.dart` | **New** — load detail+statuses; lazy user-id; quick status + full update |
| `modules/delivery/views/delivery_list_view.dart` | **New** — list + search + status chips |
| `modules/delivery/views/delivery_detail_view.dart` | **New** — status banner, info card, quick actions, edit sheet |
| `modules/delivery/bindings/*` | **New** — list + detail bindings |
| `modules/delivery/delivery_actions.dart` | **New** — shared confirm-dialog + createDeliveryForOutflow helpers |
| `services/auth_service.dart` | Added `userId` (persisted) + `setUserId` / `currentUserId`; cleared on logout |
| `data/models/outflow_order_detail_model.dart` | Added `isHaveDelivery` (`is_have_delivery`) |
| `controllers/outflow_order_list_detail_controller.dart` | `hasDelivery`, `createDelivery()`, `viewDeliveries()` |
| `views/outflow_order_list_detail_view.dart` | "Create Delivery" / "View Deliveries" CTA |
| `controllers/outflow_order_by_request_detail_controller.dart` | Post-submit "create delivery?" prompt |
| `controllers/outflow_order_by_customer_detail_controller.dart` | Same as above |
| `views/outflow_order_home_view.dart` | "Logistics" section + "Deliveries" hero entry |
| `routes/app_routes.dart`, `app_pages.dart` | `DELIVERY_LIST` + `DELIVERY_DETAIL` routes/pages |

### Known leftover / follow-ups
- If delivery volume grows large, `GET /delivery` should gain server-side pagination (`/delivery/pagination`) and the list controller switched to the cursor pattern.
- After creating a delivery the app lands on the list (no delivery id is returned to deep-link the new record).

---

## Session: 2026-06-26 — Outflow: Item-Summary Redesign, Scan Cache, `manage_sn` Scan Gating

### 1. Item-Summary page theming fix
Both outflow "Item Summary" detail pages had off-theme colors that clashed with their own headers/scan actions. Switched every accent surface to the module color (By-Request = `mutedPurple`, By-Customer = `amber`):
- AppBar gradient: By-Request blue `#5170FD/#60ABFB` → `#6B5FB5/#7C73C0`; By-Customer sage `#778873/#A1BC98` → `#C4882A/#D8B174`.
- Continue button: `Colors.blue[900]` / `Color(0xff435663)` → module accent.
- Confirm dialog: light-blue icon bubble + default-blue buttons → accent tint icon + accent Continue / outlined Cancel.
- Added a `static const Color _accent` per view as the single source; removed the raw color literals.

### 2. Local cache of in-progress scans (`get_storage`)
Outflow scans live only in memory until the final `startOutflowingItem()` POST, so an app close mid-scan lost everything. Added a per-session cache (same store as `AuthService`):
- Key: `or_scanned_<orId>` (By-Request) / `or_cust_scanned_<customerId>` (By-Customer) → map of `line_id → [{code, qty}]`.
- Auto-persisted via an `ever(items, …)` worker (disposed in `onClose`) — writes on every scan add/edit/remove/clear; only non-empty lines stored; key removed when empty.
- Restored on load (`loadOrItems`/`loadOrByCustomerItems` read the cache first and layer it over the server's empty default).
- Cleared after a successful submit. A failed/offline load never wipes the cache.

### 3. Scan only when `manage_sn` is true
The scan page always opened the camera, even for non serial-tracked items. Now scanning is gated on `manage_sn` (the master serial-tracked flag):
- **`manage_sn` true** → scan the serial leaving stock (UNIQUE = one scan; BATCH = scan + qty). Entry `{code, qty}`.
- **`manage_sn` false** → quantity dialog only, no scanner. Entry `{qty}` (codeless).
- FAB icon is reactive: QR scanner vs quantity icon. Results list renders codeless entries as "Qty: N" with **Edit Quantity / Remove** row actions (scanned serials keep **Edit Code / Remove Code**).
- **No backend change**: `OutflowOrderService` sums each line's `qty` from the `scanned` entries, and `StockMutationTrait::createOutflowTransactionFromLocal` only matches/deducts serials for `serial_number_type ∈ [UNIQUE, BATCH]` — non-serial items just record qty, so a codeless `{qty}` entry is exactly what that path expects. The managed (scan) path is unchanged.

This mirrors the receive-side `manage_sn` model, except outflow **does** scan UNIQUE items (shipping existing serials out) whereas receive auto-generates them.

### 4. Fix: over-fill validation should cap at remaining (expected − received)
The intended cap is **remaining = expected − received** (e.g. expected 50, already-outflowed 10 → max 40). Two bugs:
- `setScannedQty` (new) had been left validating `qty > expected` only — allowed scanning up to the full expected, ignoring `received`.
- `addScannedCode` (pre-existing) also ignored `received` — `totalScannedQty + qtyToAdd > expectedQty`.

Both methods in **both** outflow controllers now validate `received + (scanned…) + qty > expectedQty` and report the remaining qty in the error. Consistent with the scan page's `Remaining = expected − (received + scanned)` display.

### 5. Manual serial input + scanner scoping
Added a manual-entry option for serials and scoped where the camera scanner is used.
- New shared helpers in `functions_widget.dart`: **`captureSerialInput({accent})`** — a bottom-sheet chooser offering "Scan barcode" **or** "Enter manually" (returns the code, or null) — and **`showManualSerialDialog({accent})`** — the manual text-entry dialog (autofocus, submit-on-done, accent-themed).
- **Outflow scan** (`manage_sn` true) → uses `captureSerialInput` (scan **or** manual). Removed the direct `flutter_barcode_scanner` import from both scan pages.
- **Receive fill** (BATCH + `manage_sn`) → **manual entry only** (`showManualSerialDialog`); **no scanner on receive**. Removed `flutter_barcode_scanner` imports from both fill views; updated the now-inaccurate UI (FAB icon `qr_code_scanner → keyboard`, "Scanned Serials" → "Serials", empty state "No serials scanned yet" → "No serials entered yet").
- **Scanner usage is now**: confirm-serials (scan only) + outflow (scan or manual). Receive fill never opens the camera. Verified via grep — `FlutterBarcodeScanner` remains in the receive module only in `receive_order_confirm_view.dart`.

### Modified Files
| File | Change |
|------|--------|
| `data/models/outflow_request_line_item_model.dart` | Added `manageSn`; fixed `manageExpired` default (`?? '-'` → `?? false`) |
| `controllers/outflow_order_by_request_detail_controller.dart` | `manage_sn` in item map; `setScannedQty`; scan cache (worker/read/persist/clear); remaining-based over-fill |
| `controllers/outflow_order_by_customer_detail_controller.dart` | Same as above (cache key `or_cust_scanned_*`) |
| `views/outflow_order_by_request_detail_view.dart` | `_accent = mutedPurple`; AppBar/Continue/dialog theming |
| `views/outflow_order_by_customer_detail_view.dart` | `_accent = amber`; AppBar/Continue/dialog theming |
| `views/scan_page_by_request.dart` | `manage_sn` scan gating; `_onScanTap`; `captureSerialInput`; codeless row rendering + `_showRowActions` |
| `views/scan_page_by_customer.dart` | Same as above |
| `global/widget/functions_widget.dart` | **New** `captureSerialInput` + `showManualSerialDialog` helpers |
| `views/receive_order_fill_by_po_view.dart` | Serial capture → manual only (`showManualSerialDialog`); scanner removed; labels/icons updated |
| `views/receive_order_fill_by_supplier_view.dart` | Same as above |

---

## Session: 2026-06-26 — Confirm-Serials Hardening, Receive-Detail Confirmation Info, qty Type Fix

### 1. Re-open Confirm Serials from the RO detail
Closes the prior "no entry point to re-open confirmation later" gap. Added a **"Confirm Serials" extended FAB** on `receive_order_list_detail_view` — shown only when the RO has serial numbers — routing to `RECEIVE_ORDER_CONFIRM` with `{ro_id, ro_code, back_route: receiveOrderListPage}`. Self-contained (the confirm binding registers its own provider/controller). `back_route = list` keeps the confirm screen's accent skyBlue, matching the detail page.

### 2. Confirmation status on the receive detail
Surface per-serial confirm state on the RO detail line cards.
- **Backend**: `ReceiveOrderLineResource` now emits `is_scanned` / `scanned_at` / `scanned_by_name` per serial (mirrors `ItemSerialNumberResource`, reads the existing pivot columns).
- **Flutter**: `SerialNumberModel` gained `isScanned` / `scannedAt` / `scannedByName`. `orderSerialLineCard` + `showSerialNumbersDialog` take an opt-in `showConfirmation` flag — line card shows "Confirmed X/Y" (green when all, orange otherwise); dialog shows per-serial "Confirmed by <name>" / "Pending". Receive detail passes `showConfirmation: true`; outflow detail keeps the default (false), unaffected.

### 3. Scan-state guard on the confirm screen
Prevent losing a scan by navigating away mid-save (all keyed off `isConfirming`):
- Scanner FAB disabled + spinner while a `confirmReceiveSerial` POST is in flight.
- Next/Finish button disabled + greyed; `goToNextItem()` early-returns while confirming.
- `WillPopScope` blocks back-navigation during a save (used `WillPopScope`, not `PopScope` — SDK predates it). **Gap**: the AppBar's own back arrow (`appBarOrder`) isn't intercepted.

### 4. Local cache of confirm progress (`get_storage`)
Per-RO cache key `ro_confirmed_<roId>` of confirmed codes. Written on each successful confirm, merged back on load (layered over server state), cleared on finish when all confirmed. Additive safety net only (server stays source of truth).

### 5. Confirm header redesign + RO label visibility
`_buildHeaderCard` reworked into a gradient banner (accent gradient + decorative circle, white scanner icon bubble, RO code as a light label, item name as prominent white `h4`) — replaces the gray-on-tint RO label that was hard to read.

### 6. qty / price type parse fix (detail models)
Backend `AsDecimalSix` cast returns **strings** (e.g. `"5"`), but `ReceiveOrderLine` / `OutflowOrderLine` (in the detail models) declared `qty` as `int` (`json['qty'] ?? 0`) and called `.toDouble()` on price strings — both threw at runtime for any populated line. Now parse leniently: `qty: (num.tryParse(json['qty']?.toString() ?? '') ?? 0).toInt()`, prices via `double.tryParse(...)`. Same lenient parse applied to `SerialNumberModel.qty`.

### Modified Files
| File | Change |
|------|--------|
| **Backend** | |
| `app/Http/Resources/Inventory/ReceiveOrderLineResource.php` | Per-serial `is_scanned` / `scanned_at` / `scanned_by_name` |
| **Flutter** | |
| `data/models/serial_number_model.dart` | Added `isScanned`/`scannedAt`/`scannedByName`; lenient `qty` parse |
| `data/models/receive_order_detail_model.dart` | Lenient `qty`/price parse (AsDecimalSix strings) |
| `data/models/outflow_order_detail_model.dart` | Same lenient `qty`/price parse |
| `global/widget/order_list_widgets.dart` | `showConfirmation` flag on `orderSerialLineCard` + `showSerialNumbersDialog` |
| `views/receive_order_list_detail_view.dart` | "Confirm Serials" FAB; `showConfirmation: true` on line cards |
| `controllers/receive_order_confirm_controller.dart` | `get_storage` confirm cache (read/merge/write/clear); `goToNextItem` guard |
| `views/receive_order_confirm_view.dart` | Scan-state guard (WillPopScope + disabled FAB/Next); header gradient redesign; accent from caller |

---

## Session: 2026-06-26 — Fill Serials: Quantity-Only Except BATCH + `manage_sn`

### Context / correction (two-step)
The earlier session let **every** `manage_sn` item scan a serial per unit during fill. That's wrong: serials are **auto-generated by the backend**, and the mobile scan exists only to confirm physical receipt. First pass removed serial capture entirely (quantity-only). Then refined: **BATCH + `manage_sn` is the one case that *does* capture serials at fill** — and dynamically, since one line can be split across batch serials (e.g. a batch of 5 entered as 2 + 3). All changes are mobile-only; no backend change.

### Final fill model
- **BATCH + `manage_sn`** → scan batch serial + enter qty (`addFilledSerial`); multiple serials per line allowed (2 + 3 = 5), over-fill guarded, duplicates rejected. Entry = `{serial, qty, expired_date}`.
- **UNIQUE / OTHER / non-`manage_sn`** → quantity-only (`addFilledQty`); backend generates the serials. Entry = `{qty, expired_date}`.

### Changes (Flutter only)
- Both detail controllers: `addFilledSerial()` restored but **BATCH-scoped** (each call = one batch serial with its own qty); `updateFilledAt()` keeps the `serial` param to preserve/replace a batch serial on edit.
- Both fill views: `_onFillTap` branches on `batchSerial = manage_sn && serialType == 'BATCH'`. BATCH+sn → scan → qty dialog → `addFilledSerial`; otherwise → qty dialog → `addFilledQty`. FAB icon, section header ("Scanned Serials" vs "Filled Results"), empty state, and filled-row rendering (serial + qty vs qty) all switch on `batchSerial`/per-entry `serial`. Row action is "Edit Serial" (re-scan + qty) for serial entries, "Edit Quantity" otherwise. Re-added the `flutter_barcode_scanner` import.
- **No backend change**: `createReceiveTransactionFromLocal` already keeps the entered `serial` as `serial_number` for `manage_sn` (line 44) and uses `count($selectedSerials)` / per-entry `qty` for BATCH; the generated SKU is the `internal_code`.

### Confirm-serials screen polish
- **Accent now matches the calling flow** instead of the old fixed green: the view derives accent from `controller.backRoute` — By-Supplier → `sageTeal`, By-PO (default) → `skyBlue`. Applied to AppBar gradient, scanner FAB, header card tint/icon, "Done" button, and the "Next Item" nav button. Genuine success states (confirmed checkmarks, "Confirmed" label, "Finish"/allDone) stay green.
- **Bottom-bar counter no longer crowds the centre-docked FAB**: the "X / Y confirmed" counter and the Next/Finish button are each wrapped in `Expanded` with a fixed `size * 7` center clearance gap; the counter `Flexible`-ellipsizes instead of sliding under the scanner button.

### Modified Files
| File | Change |
|------|--------|
| `controllers/receive_order_by_po_detail_controller.dart` | `addFilledSerial` (BATCH-scoped); `updateFilledAt` keeps `serial` |
| `controllers/receive_order_by_supplier_detail_controller.dart` | Same as above |
| `views/receive_order_fill_by_po_view.dart` | Fill branches on BATCH+`manage_sn`; serial UI for that case only |
| `views/receive_order_fill_by_supplier_view.dart` | Same as above |
| `views/receive_order_confirm_view.dart` | Accent matches caller (sky/sage); bottom-bar FAB clearance fix |
| `CLAUDE.md` | Rewrote "Serial numbers & `manage_sn`" — BATCH+sn captures serials, rest backend-generated |

### Known leftover
- Dead `editFilledCode`/`removeFilledCode` (match on a nonexistent `'code'` field) still present in both detail controllers — pre-existing, left untouched.

---

## Session: 2026-06-26 — Serial Confirmation, App Branding, Order UI Redesign & manage_sn Fill

### Goals
1. Scan/confirm serial numbers one-by-one immediately after a receive order is created.
2. Rebrand the app (logo splash, launcher icon, name "Warehouse app").
3. Redesign the entire receive + outflow surface (menus, lists, details, fill/scan) to the home-page design language.
4. Fix the broken "Edit/Remove" actions on filled results.
5. Capture real serial numbers during fill, but only for `manage_sn` items.

### 1. Serial Confirmation feature (hybrid → shipped: Pass-2 "scan to confirm", persisted)

- **Backend already had the scaffolding**: `stock_transaction_serials` pivot has `scanned_at` + `scanned_by` columns (unused), and `StockTransaction::serialNumbers()` already declares them in `withPivot`. `ItemSerialNumberResource` already exposes `is_scanned`/`scanned_at`/`scanned_by_name`. **No migration needed.**
- **New endpoint** `POST /receive-order/{id}/confirm-serials` (`ConfirmSerialRequest` → `ReceiveOrderController::confirmSerials` → `ReceiveOrderService::confirmSerials`). Accepts `{codes: [...]}` (one or many — serves per-scan and batch). Matches each code against the RO's serials by `internal_code`/`serial_number`, stamps `scanned_at`/`scanned_by`, idempotent. Returns `{confirmed, already_scanned, not_found}`.
- **Flow**: after `createReceiveData` succeeds, `startReceivingItem()` reads the created RO from the response and routes to a new **Confirm Serials** screen (UNIQUE items only). Each scan flips the serial green + POSTs per-scan. Persisted → reopening resumes prior progress.
- **Flutter**: `ReceiveConfirmSerialModel`, provider `getReceiveOrderSerials`/`confirmReceiveSerial`, `ReceiveOrderConfirmController`, `ReceiveOrderConfirmView` + binding + route `RECEIVE_ORDER_CONFIRM`.
- **Known gap**: no entry point to re-open confirmation later from the RO list detail (only auto-opens post-receive).

### 2. App branding

- Added dev deps `flutter_launcher_icons` + `flutter_native_splash`; config blocks in `pubspec.yaml`.
- Icon + splash use `assets/images/logo_short.png`. Created a padded `assets/images/logo_adaptive_fg.png` (logo centered in the ~66% safe zone) for the Android adaptive-icon foreground so the mask doesn't clip petals. White background (`#FFFFFF`).
- App name → **"Warehouse app"** (`AndroidManifest.xml` `android:label`, iOS `CFBundleDisplayName`).
- Regenerate with `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.

### 3. Receive + Outflow UI redesign (matches home design language)

Reskinned **every** receive + outflow screen while preserving all controller logic (search, debounced filters, cursor pagination, `Obx`, dialogs, scanner calls, navigation). Three new shared widget files:

- `order_menu_widgets.dart` — `orderMenuHero`, `orderMenuSectionHeader`, `orderMenuTile`.
- `order_list_widgets.dart` — `orderListCard`, `orderListFooter`, `orderDetailHeader`, `orderItemSummaryTile`, `orderSerialLineCard`, `showSerialNumbersDialog`.
- `order_fill_widgets.dart` — `orderFillHeaderCard`, `orderFillStatsCard` (+ `FillStat`), `orderScanFab`, `orderFillBottomBar`, `orderFillEmptyState`, `orderFillResultsContainer`.

**Per-module accent mapping**: receive = navy / By-PO `skyBlue` / By-Supplier `sageTeal`; outflow = purple (`mutedPurple`/`softPurple`) / By-Request `mutedPurple` / By-Customer `amber`.

### 4. Filled-result Edit/Remove fix

The bottom-sheet "Edit Code"/"Remove Code" were dead placeholders (`infoAlertBottom("you click edit code.")`), and the old `editFilledCode`/`removeFilledCode` matched a `'code'` field that filled entries (`{qty, expired_date}`) never have. Added index-based `updateFilledAt(index, {qty, expiredDate, serial})` + `removeFilledAt(index)` to both receive detail controllers, and made `_showItemQtyDialog` pre-fillable. Relabeled to "Edit Quantity"/"Remove".

### 5. manage_sn serial fill

- Backend summary already returned `manage_sn` (per-item bool = serial-tracked); Flutter wasn't parsing it. Added `manageSn` to both PO line-item models (also fixed `manage_expired` being parsed with `?? '-'` into a bool — now `?? false`), and carried `manage_sn` into the controllers' item maps.
- **Fill behavior now branches on `manage_sn`**: serial-managed items scan a serial per unit (BATCH = code + qty; expiry prompt if expiry-managed) via `addFilledSerial`; non-managed items keep the plain quantity dialog. Filled entries gain a `serial` field; edit row offers "Edit Serial" (re-scan) vs "Edit Quantity".
- **Backend persistence**: `StockMutationTrait::createReceiveTransactionFromLocal` now uses the captured serial as `serial_number` for `manage_sn` items (generated SKU stays as `internal_code`); non-managed items still use the generated SKU.

### Modified / Added Files

| File | Change |
|------|--------|
| **Backend** | |
| `routes/tenant_api.php` | Added `POST /receive-order/{id}/confirm-serials` |
| `app/Http/Requests/Inventory/ConfirmSerialRequest.php` | **New** — validates `codes` array |
| `app/Http/Controllers/Inventory/ReceiveOrderController.php` | `confirmSerials()`; `serial-number` eager-load adds `serial_number_type` |
| `app/Services/Inventory/ReceiveOrderService.php` | `confirmSerials()` (idempotent pivot stamping) |
| `app/Http/Resources/Inventory/ItemSerialNumberResource.php` | Added `serial_number_type` |
| `app/Traits/StockMutationTrait.php` | Receive serial capture: use entered serial as `serial_number` for `manage_sn` |
| **Flutter — models/providers** | |
| `lib/app/data/models/receive_confirm_serial_model.dart` | **New** |
| `lib/app/data/models/purchase_order_line_item_model.dart` | Added `manageSn`; fixed `manageExpired` default |
| `lib/app/data/models/purchase_order_line_item_by_supplier_model.dart` | Added `manageSn`; fixed `manageExpired` default |
| `lib/app/data/providers/receive_order_provider.dart` | `getReceiveOrderSerials`, `confirmReceiveSerial` |
| **Flutter — shared widgets** | |
| `lib/app/global/widget/order_menu_widgets.dart` | **New** |
| `lib/app/global/widget/order_list_widgets.dart` | **New** |
| `lib/app/global/widget/order_fill_widgets.dart` | **New** |
| **Flutter — receive_order** | |
| `controllers/receive_order_confirm_controller.dart` | **New** |
| `bindings/receive_order_confirm_binding.dart` | **New** |
| `views/receive_order_confirm_view.dart` | **New** |
| `controllers/receive_order_by_po_detail_controller.dart` | confirm nav; `manage_sn`; `addFilledSerial`/`updateFilledAt`/`removeFilledAt` |
| `controllers/receive_order_by_supplier_detail_controller.dart` | same as above |
| `views/*` (home, list, list_detail, by_po, by_po_detail, by_supplier, by_supplier_detail, fill_by_po, fill_by_supplier) | redesigned + serial fill |
| **Flutter — outflow_order** | |
| `views/*` (home, list, list_detail, by_request, by_request_detail, by_customer, by_customer_detail, scan_page_by_request, scan_page_by_customer) | redesigned |
| **Flutter — routes / branding** | |
| `lib/app/routes/app_routes.dart`, `app_pages.dart` | `RECEIVE_ORDER_CONFIRM` route + page |
| `pubspec.yaml` | launcher-icons + native-splash dev deps & config |
| `android/.../AndroidManifest.xml`, `ios/Runner/Info.plist` | app name "Warehouse app" |
| `assets/images/logo_adaptive_fg.png` | **New** — padded adaptive-icon foreground |

---

## Session: 2026-06-25 — Home Page UI Redesign

### Goal
Comprehensive visual overhaul of the home page — consistent navy brand palette, Plus Jakarta Sans font, redesigned widgets, and centralized design tokens.

### Changes

**Color system** — Added named palette constants to `variables.dart` (`navyDark`, `navyMid`, `navyLight`, `skyBlue`, `sageTeal`, `sageGreen`, `softPurple`, `mutedPurple`, `lightPurple`, `amber`, `steelBlue`, `lightSteelBlue`). Removed scattered `HexColor('#...')` and `Color(0xFF...)` literals from home page code.

**Font** — Migrated to **Plus Jakarta Sans** via `google_fonts`. All `AppTextStyle` methods updated to use `GoogleFonts.plusJakartaSans(...)`. Set in `ThemeData` via `fontFamily: GoogleFonts.plusJakartaSans().fontFamily` (not `GoogleFonts.plusJakartaSansTextTheme()` — that breaks Material3 AppBar colors).

**`_buildAppBar`** — Navy gradient (`navyDark → navyMid`) via `Container` `flexibleSpace`; white icons and avatar background.

**`_buildGreetingCard`** — Navy gradient card with decorative circles, live clock, app logo, greeting, username, and role pill.

**`_buildHeader`** — Stripped to a plain `Row`: icon + `h3` title + muted `h5` breadcrumb. No container or background.

**`_sectionTitle`** — Accent bar + icon bubble + `h5` title. `skyBlue` for Latest Transactions, `sageTeal` for Statistic.

**`_buildDashboardGrid`** — "Overview" label + year pill header; `Row`+`Expanded` replacing `GridView.extent`. `_MenuConfig` changed from `String hex1, hex2` to `Color color1, color2`.

**`_buildCircleMenu`** — White card with "Quick Access" label; `Row`+`Expanded` for dynamic height (avoids `GridView.extent` overflow).

**`_buildFooter`** — Single compact row, navy gradient, text changed to "Mastercool Inventory Management".

**`_pieChartItem`** — `Obx` checks `total == 0`; shows empty state (outline icon + text) instead of a blank chart when data is zero. Pie legend uses `navyDark`/`hex1`.

**`showAccountSheet`** (`home_controller.dart`) — Drag handle + navy gradient profile card (initials avatar + name + role pill) + `_sheetTile` menu items (Account Info, Logout).

**`_showAccountDetailDialog`** (`home_controller.dart`) — Custom `Get.dialog` with navy gradient header, large initials avatar, info rows (Username / Role / Company), full-width Close button.

**`MenuGrid`** (`menu_grid.dart`) — White card + colored border + shadow; gradient icon bubble; `AnimatedCounter` in `color1`; "View →" hint row.

**`CircleMenuItem`** (`menu_card.dart`) — Gradient rounded-rectangle background tinted by `iconColor`; icon in soft circular bubble; label in `iconColor.withOpacity(0.85)`.

### Modified Files

| File | Change |
|------|--------|
| `lib/app/global/variables.dart` | Added 12 named color constants |
| `lib/app/global/styles/app_text_style.dart` | All methods use `GoogleFonts.plusJakartaSans`; added `google_fonts` import |
| `lib/main.dart` | Set `fontFamily` via `GoogleFonts.plusJakartaSans().fontFamily`; added import |
| `lib/app/modules/home/views/home_view.dart` | Full home page UI overhaul |
| `lib/app/modules/home/controllers/home_controller.dart` | `showAccountSheet`, `_showAccountDetailDialog`, `_dialogInfoRow`, `_sheetTile`; pie chart colors |
| `lib/app/modules/home/views/widgets/menu_grid.dart` | `String hex1, hex2` → `Color color1, color2`; new card design |
| `lib/app/modules/home/views/widgets/menu_card.dart` | Gradient background, icon bubble, ripple |
| `CLAUDE.md` | Added Color Palette and Typography sections; updated DRY Code rules |

---

## Session: 2026-06-25 — Centralized API Error Handling

### Goal
Handle HTTP errors (404, 502, null response) from `ApiProvider` centrally so every controller automatically shows meaningful error messages instead of generic fallbacks like "Login failed. Please check your credentials."

### Root Cause Identified
`GetConnect`'s `addResponseModifier` does **not** propagate thrown exceptions to the caller — it silently catches them and returns a `Response` with `statusCode: null`. This caused controllers that returned raw `Response` objects (like `LoginProvider`) to fall through to their own hardcoded error messages.

### Plan Implemented

1. **Add `checkResponse()` to `ApiProvider`** — single place that throws a meaningful exception for null statusCode or non-2xx responses, preferring the server's `message` field over raw HTTP status text.
2. **Refactor all providers** — replace manual `if (statusCode == 200) { ... } else { throw ... }` blocks with `checkResponse(response)` + direct parsing.
3. **Fix POST providers** — `postPoLineToReceivedData` and `postOrLineToOutflowedData` were returning raw `Response`; changed to return `Map<String, dynamic>` and call `checkResponse`.
4. **Fix 4 "submit" controllers** — removed manual `response.isOk && response.body?['success'] == true` checks; a non-null result from `ApiExecutor.run()` now implies success.
5. **Fix `LoginProvider`** — changed return type from `Response` to `Map<String, dynamic>`, fixed `LoginController` to consume parsed data directly.
6. **Fix `ApiExecutor`** — strip `"Exception: "` prefix before passing to `errorAlert` so the user sees clean messages.

### Error Flow (after changes)

```
Provider throws Exception("HTTP 404: Not Found")
  └─► ApiExecutor.run() catches → errorAlert("HTTP 404: Not Found") → returns null
        └─► Controller: if (data == null) return;   ← exits cleanly, no double-error
```

---

## Modified Files

### Providers
| File | Change |
|------|--------|
| `lib/app/data/providers/api_providers.dart` | Removed `addResponseModifier`; added `checkResponse()` helper method |
| `lib/app/data/providers/login_provider.dart` | Returns `Map<String, dynamic>` instead of raw `Response`; uses `checkResponse` |
| `lib/app/data/providers/home_provider.dart` | All methods refactored to use `checkResponse`; removed try/catch boilerplate |
| `lib/app/data/providers/receive_order_provider.dart` | All methods use `checkResponse`; `postPoLineToReceivedData` returns `Map` |
| `lib/app/data/providers/outflow_order_provider.dart` | All methods use `checkResponse`; `postOrLineToOutflowedData` returns `Map` |
| `lib/app/data/providers/product_provider.dart` | All methods refactored to use `checkResponse` |
| `lib/app/data/providers/stock_transaction_provider.dart` | Refactored to use `checkResponse` |

### Helpers
| File | Change |
|------|--------|
| `lib/app/helpers/api_excecutor.dart` | Strips `"Exception: "` prefix before `errorAlert` call |

### Controllers
| File | Change |
|------|--------|
| `lib/app/modules/login/controllers/login_controller.dart` | Consumes `Map` directly; removed manual `statusCode == 200` check |
| `lib/app/modules/receive_order/controllers/receive_order_by_po_detail_controller.dart` | `startReceivingItem()` — removed `response.isOk` check |
| `lib/app/modules/receive_order/controllers/receive_order_by_supplier_detail_controller.dart` | `startReceivingItem()` — removed `response.isOk` check |
| `lib/app/modules/outflow_order/controllers/outflow_order_by_request_detail_controller.dart` | `startOutflowingItem()` — removed `response.isOk` check |
| `lib/app/modules/outflow_order/controllers/outflow_order_by_customer_detail_controller.dart` | `startOutflowingItem()` — removed `response.isOk` check |

---

## Controllers Verified Clean (no changes needed)

These controllers already followed the correct pattern before this session:

- `home_controller.dart`
- `product_controller.dart`
- `product_detail.controller.dart`
- `product_transaction_list_controller.dart`
- `product_category_controller.dart`
- `product_by_category_controller.dart`
- `product_brand_controller.dart`
- `product_by_brand_controller.dart`
- `product_unit_controller.dart`
- `stock_transaction_controller.dart`
- `stock_transaction_detail_controller.dart`
- `receive_order_list_controller.dart`
- `receive_order_list_detail_controller.dart`
- `receive_order_by_po_controller.dart`
- `receive_order_by_supplier_controller.dart`
- `outflow_order_list_controller.dart`
- `outflow_order_list_detail_controller.dart`
- `outflow_order_by_request_controller.dart`
- `outflow_order_by_customer_controller.dart`
- `return_controller.dart` (no API calls)
