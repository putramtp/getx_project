# Navy Header & Accent Components Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 9 per-screen AppBar gradients and hard-coded card/button colors with one navy `appHeader`, one `AppAccent` color source, and a small set of reusable components used by every screen except Home.

**Architecture:** Build the foundation first (colors → `AppAccent` → `appHeader` → pills/buttons/icons → `accentHeaderCard`), each with widget tests. Then migrate screens module by module onto those components, deleting the old helpers as their last caller disappears. Screens stay GetX views; only `global/` gains new files.

**Tech Stack:** Flutter 3.47.7 (FVM), GetX 4.7, google_fonts (Plus Jakarta Sans via `AppTextStyle`), skeletonizer, flutter_test, Patrol 4.10.

**Spec:** `docs/superpowers/specs/2026-10-27-navy-header-ui-design.md` (mockups: https://claude.ai/artifact/JjGFy486gXT3sYUitoJUMC). Read §1–§4 before each task; this plan does not repeat the per-screen table.

## Global Constraints

- **No git commits.** Project rule (user memory): leave all changes uncommitted. Every "commit" step below is "leave uncommitted".
- `home_view.dart` is not modified.
- Text styles only via `AppTextStyle`; colors only via named constants (`variables.dart`) or `AppAccent`; no new `Color(0x…)` outside `variables.dart`.
- Sizes derive from `SizeConfig.defaultSize` (`size`), dp values in the spec are at 400 dp width (`size ≈ 9.6`).
- Close routes with `closeRoute()` (`global/functions.dart`), never `Get.back()`.
- Keep `Key('appBarBackButton')` on the back button.
- New shared widgets live in `lib/app/global/widget/` as top-level functions taking `double size` first, like `order_*_widgets.dart`.
- Existing shared widgets keep their `Color` parameters (callers pass `AppAccent.x.base` / `.text`); only new components take `AppAccent`. (Refines spec §3.5.)
- Widget tests: `GoogleFonts.config.allowRuntimeFetching = false` (verified to work with `AppTextStyle` in tests).
- Verify with: `flutter analyze` (no new issues), `flutter test`, and `patrol build android -t patrol_test/<file>` for edited Patrol files.

## Review Focus

1. **Long text on a 320 dp phone** (titles like "Outflow Requests", supplier "PT Sinar Jaya Abadi Sentosa Makmur") → one line with ellipsis, no RenderFlex overflow. Tests: Task 2 (`appHeader`), Task 4 (`accentHeaderCard`).
2. **Missing optional data** (`supplierName`, `receiveNumber`, `billNumber`, `date` null/empty) → that footer part disappears; never prints "null" or a dangling "·". Test: Task 4 (`headerFooterText`).
3. **Progress out of range** (over-filled line, expected = 0, segments summing > 1) → bar clamps to 0..1 with no exception. Test: Task 4.
4. **Back after a create/submit flow lands on a stale screen**: after "Create Delivery" the outflow detail must show "View Deliveries", not "Create Delivery" again, and Confirm Serials → back must show a refreshed PO/Supplier list. Owned by Task 5 (confirm `leave()`) and Task 9 (delivery reload); asserted in Patrol `delivery_test` / `receive_order_test`.
5. **API status color unreadable on white** (`delivery_statuses.color` defaults to `#fff`) → outline buttons and pills fall back to `navyMid`. Test: Task 1 (`readableOnWhite`) and Task 3 (`accentOutlineButton`).

---

### Task 1: Color tokens and `AppAccent`

**Files:**
- Modify: `lib/app/global/variables.dart` (append after the amber block)
- Create: `lib/app/global/accent.dart`
- Test: `test/helpers/accent_test.dart`

**Interfaces:**
- Produces: constants `skyBlueDark` `0xFF3D78B4`, `amberDark` `0xFF9B6B21`, `sageTealDark` `0xFF517D6D`, `stockInColor` `0xFF2E9B5F`, `stockOutColor` `0xFFD2453B`; `enum AppAccent { navy, slate, sky, sage, purple, amber, steel }` with `Color base, light, text`, `Color tint([double a = 0.12])`, `LinearGradient get gradient`; `const LinearGradient navyGradient`; `AppAccent accentFor(String name)`; `Color readableOnWhite(Color c)`.

- [ ] **Step 1: Write failing tests** in `test/helpers/accent_test.dart`:
  - `AppAccent.sky.text == skyBlueDark`, `AppAccent.amber.text == amberDark`, `AppAccent.sage.text == sageTealDark`, `AppAccent.purple.text == mutedPurple`, `AppAccent.slate.base == navyMid`, `AppAccent.steel.light == lightSteelBlue` (values per spec §2).
  - `AppAccent.sky.tint().a` ≈ `0.12` and `tint(0.2).a` ≈ `0.2`.
  - `accentFor('Indo Kemas') == accentFor('Indo Kemas')` (deterministic) and `accentFor('')` returns `AppAccent.slate` (sum 0 → index 0).
  - `readableOnWhite(const Color(0xFFFFFFFF)) == navyMid`; `readableOnWhite(const Color(0xFFEEEEEE)) == navyMid`; `readableOnWhite(steelBlue) == steelBlue`.
- [ ] **Step 2: Run** `flutter test test/helpers/accent_test.dart` → FAIL (`accent.dart` not found).
- [ ] **Step 3: Add the five constants** to `variables.dart` and **implement `accent.dart`** exactly as spec §2 (enum table, `navyGradient = LinearGradient(colors: [navyDark, navyMid])`, `accentFor` = code-unit sum % 6 over `[slate, sky, sage, purple, amber, steel]`). `readableOnWhite`: return `navyMid` when `c.computeLuminance() > 0.7`, else `c`.
- [ ] **Step 4: Run** `flutter test test/helpers/accent_test.dart` → PASS.
- [ ] **Step 5: Leave uncommitted.**

### Task 2: Test harness and `appHeader`

**Files:**
- Create: `test/widgets/pump_ui.dart` (test helper, not a test)
- Create: `lib/app/global/widget/app_header.dart`
- Modify: `lib/main.dart:77-79` (`appBarTheme`)
- Test: `test/widgets/app_header_test.dart`

**Interfaces:**
- Consumes: `AppAccent`, `navyGradient` (Task 1); `closeRoute` (`global/functions.dart`); `skeletonize` (`global/widget/skeleton_widgets.dart`).
- Produces:
  - `Future<void> pumpUi(WidgetTester t, Widget home, {double width = 400})` — sets `t.view.physicalSize = Size(width, 800)`, `devicePixelRatio = 1`, `SizeConfig.defaultSize = width * 0.024`, `GoogleFonts.config.allowRuntimeFetching = false`, pumps `GetMaterialApp(home: home)`; resets the view on teardown.
  - `PreferredSizeWidget appHeader(String title, {required AppAccent accent, required IconData icon, String? subtitle, bool subtitleLoading = false, List<Widget> actions = const [], bool showBack = true, VoidCallback? onBack})` — `onBack` defaults to `() => closeRoute()`.
  - `Widget headerAction(IconData icon, {required String tooltip, required VoidCallback onPressed})`.

- [ ] **Step 1: Write failing tests** in `test/widgets/app_header_test.dart` (each builds `Scaffold(appBar: appHeader(...))` via `pumpUi`):
  - `'renders title, subtitle and white tile icon'`: finds `'Item Summary'`, `'By PO · PO-2026-0187'`, and an `Icon` with `icon == Icons.receipt_long_rounded` and `color == skyBlue`.
  - `'back pops the route'`: push a second page with `Get.to(() => Scaffold(appBar: appHeader('Second', accent: AppAccent.sky, icon: Icons.list_alt_rounded)))`, tap `find.byKey(const Key('appBarBackButton'))`, `pumpAndSettle`, expect `'Second'` findsNothing.
  - `'onBack overrides pop'`: with `onBack: () => tapped = true`, tap back → `tapped == true` and the page is still shown.
  - `'showBack false hides the back button'`: `find.byKey(const Key('appBarBackButton'))` findsNothing.
  - `'subtitleLoading shows a skeleton'`: `find.byType(Skeletonizer)` findsOneWidget.
  - `'long text does not overflow at 320 dp'`: `pumpUi(width: 320)` with title `'Outflow Order Detail Summary'` and subtitle `'By Customer · PT Sinar Jaya Abadi Sentosa Makmur'`; `expect(tester.takeException(), isNull)`.
- [ ] **Step 2: Run** `flutter test test/widgets/app_header_test.dart` → FAIL.
- [ ] **Step 3: Implement `pump_ui.dart` and `app_header.dart`** per spec §3.1 (toolbar `size * 6.25`, `flexibleSpace` `navyGradient` left→right, `scrolledUnderElevation: 3`, `surfaceTintColor: Colors.transparent`, `SystemUiOverlayStyle.light` with transparent status bar, leading `IconButton` 48 dp target with the key, `leadingWidth: size * 5.4`, tile `size * 3.75` radius `size * 1.05` white with `accent.base` icon `size * 1.9`, title `AppTextStyle.custom(size, scale: 1.67, weight: FontWeight.w700, color: Colors.white)`, subtitle scale 1.25 w500 white @ .74, both `maxLines: 1` ellipsis). `headerAction`: 40 dp, radius `size * 1.25`, `Colors.white.withValues(alpha: 0.14)`, white icon, `tooltip`.
- [ ] **Step 4: Set `appBarTheme`** in `main.dart` to `AppBarTheme(backgroundColor: navyDark, foregroundColor: Colors.white, iconTheme: IconThemeData(color: Colors.white))`.
- [ ] **Step 5: Run** `flutter test test/widgets/app_header_test.dart` → PASS.
- [ ] **Step 6: Leave uncommitted.**

### Task 3: Pills, buttons and stock direction icon

**Files:**
- Create: `lib/app/global/widget/accent_pill.dart`, `lib/app/global/widget/app_buttons.dart`, `lib/app/global/widget/stock_direction_icon.dart`
- Test: `test/widgets/accent_components_test.dart`

**Interfaces:**
- Consumes: Task 1, `pumpUi` (Task 2).
- Produces:
  - `Widget accentPill(double size, String text, {required AppAccent accent, IconData? icon, bool outlined = false})` — text `accent.text`, fill `accent.tint(.12)` or white + `accent.tint(.3)` border.
  - `Widget statusPill(double size, String text, Color color, {IconData? icon})` — text/icon `readableOnWhite(color)`, fill `color @ .13`.
  - `Widget navyButton(double size, String label, {required VoidCallback? onPressed, IconData? icon, bool loading = false})` — full width, height `size * 4.6`, radius `size * 1.4`, `navyGradient`; `onPressed == null` → grey fill `Colors.grey.shade400`; `loading` → white `CircularProgressIndicator` and ignores taps.
  - `Widget accentOutlineButton(double size, String label, {required Color color, required VoidCallback? onPressed, IconData? icon})` — white fill, 1.5 dp border at 45 %, text/icon `readableOnWhite(color)`.
  - `Widget stockDirectionIcon(double size, {required bool isIn})` — 32 dp square, radius 10, border 1.5 dp at 55 %, fill at 7 %, `Icons.south_rounded` / `Icons.north_rounded` in `stockInColor` / `stockOutColor`.

- [ ] **Step 1: Write failing tests:**
  - `'navyButton calls onPressed and shows label'`; `'navyButton loading ignores taps'` (tap → callback count stays 0, finds `CircularProgressIndicator`); `'navyButton disabled when onPressed null'` (no exception on tap).
  - `'accentOutlineButton falls back to navy for white API colors'`: `color: const Color(0xFFFFFFFF)` → the label `Text` style color `== navyMid`.
  - `'accentPill uses the dark text shade'`: `accentPill(10, '12 left', accent: AppAccent.amber)` → text color `== amberDark`.
  - `'stockDirectionIcon shows south for IN, north for OUT'` with colors `stockInColor` / `stockOutColor`.
- [ ] **Step 2: Run** `flutter test test/widgets/accent_components_test.dart` → FAIL.
- [ ] **Step 3: Implement the three files** to the interfaces above.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Leave uncommitted.**

### Task 4: `accentHeaderCard`

**Files:**
- Create: `lib/app/global/widget/accent_header_card.dart`
- Modify: `lib/app/global/widget/order_menu_widgets.dart:12` (`_decorCircle` → public `decorCircle`, update its two internal callers)
- Test: `test/widgets/accent_header_card_test.dart`

**Interfaces:**
- Consumes: Tasks 1–3, `decorCircle(double diameter, Color color)`.
- Produces:
  - `class HeaderStat { const HeaderStat(this.label, this.value, {this.color}); final String label; final String value; final Color? color; }`
  - `class ProgressSegment { const ProgressSegment(this.fraction, this.color, {this.legend}); final double fraction; final Color color; final String? legend; }`
  - `class AccentProgress { const AccentProgress(this.segments, {required this.caption, this.showLegend = false}); … }`
  - `Widget accentHeaderCard({required double size, required AppAccent accent, required IconData icon, required String label, required String title, String? code, Widget? badge, List<HeaderStat> stats = const [], String? footer, IconData footerIcon = Icons.info_outline_rounded, AccentProgress? progress, Widget? child})`
  - `String? headerFooterText(List<String?> parts)` — joins non-null, non-blank parts with `' · '`; returns `null` when none remain.

- [ ] **Step 1: Write failing tests:**
  - `'headerFooterText drops missing parts'`: `headerFooterText(['PT Mitra', null, '  ', 'RN-1'])` == `'PT Mitra · RN-1'`; `headerFooterText([null, ''])` isNull.
  - `'renders label, title, code, stats and caption'`: finds `'Purchase order'`, `'#PO-2026-0187'`, `'BR-007'`, `'Expected'`, `'48'`, `'1 of 3 lines complete'`.
  - `'footer null renders no footer row'`: `footer: null` → `find.byIcon(Icons.store_rounded)` findsNothing when `footerIcon: Icons.store_rounded`.
  - `'progress clamps out-of-range segments'`: segments `[ProgressSegment(0.9, navyMid), ProgressSegment(0.5, skyBlue)]` and a `ProgressSegment(-0.2, red)` → `tester.takeException()` isNull and the filled widths sum ≤ track width.
  - `'no overflow at 320 dp'` with title `'Scanner Zebra DS2208 Barcode Reader Black'`, four stats and a 60-char footer → `takeException()` isNull.
- [ ] **Step 2: Run** `flutter test test/widgets/accent_header_card_test.dart` → FAIL.
- [ ] **Step 3: Implement** per spec §3.2: radius `size * 1.7`; border `accent.tint(.18)`; background `LinearGradient(begin: topLeft, end: bottomRight, colors: [white, white, accent.tint(.11)], stops: [0, .45, 1])`; `Stack` with `decorCircle(size * 11, accent.tint(.09))` at top-right `(-3.4, -4)·size` and `decorCircle(size * 7, accent.light.withValues(alpha: .12))`; icon tile `size * 4.4` radius `size * 1.3` with `accent.gradient`. Stats: white box radius `size * 1.2`, 1 dp `accent.tint(.14)` border, `IntrinsicHeight` row of `Expanded` columns divided by `VerticalDivider`, label `AppTextStyle.small` above value `AppTextStyle.h5(… weight: w700, color: stat.color ?? navyDark)`. Progress: track `accent.tint(.14)` height `size * 0.6`, segments clamped with `fraction.clamp(0.0, 1.0)` and the running total capped at 1. Title `maxLines: 1` ellipsis; footer `maxLines: 1` ellipsis.
- [ ] **Step 4: Run** → PASS; run `flutter test` (all) → PASS.
- [ ] **Step 5: Leave uncommitted.**

### Task 5: Swap every AppBar, delete dead code, update Patrol titles

**Files:**
- Modify: the 26 views calling `appBarOrder(` (list with `grep -rln "appBarOrder(" lib`) — each gets `appHeader(title, accent:, icon:, subtitle:)` with title / icon / accent / subtitle from spec §4.
- Modify: `lib/app/modules/product/views/product_detail_view.dart` (move `_buildAppBar` row into `Scaffold.appBar: appHeader('Product Detail', accent: AppAccent.slate, icon: Icons.info_outline_rounded, subtitle: product.itemCode)`; remove the row from the scroll view).
- Modify: `lib/app/modules/receive_order/controllers/receive_order_confirm_controller.dart` (add `leave()`), `receive_order_confirm_view.dart` (`onBack: controller.leave`).
- Delete: `lib/app/modules/transaction/views/stock_transaction_detail_view.dart`, `controllers/stock_transaction_detail_controller.dart`, `bindings/stock_transaction_detail_binding.dart`.
- Modify: `lib/app/global/widget/functions_widget.dart` (delete `costumAppbar`, `titleApp`, `appBarOrder`).
- Modify: `patrol_test/home_test.dart`, `receive_order_test.dart`, `outflow_order_test.dart`, `delivery_test.dart`, `product_test.dart`, `product_master_test.dart`.

**Interfaces:**
- Consumes: `appHeader` (Task 2), `AppAccent` (Task 1).
- Produces: `void ReceiveOrderConfirmController.leave()` — `closeRoute()`, then `loadPurchaseOrders()` on `ReceiveOrderByPoController` and `loadSuppliers()` on `ReceiveOrderBySupplierController` when registered.

- [ ] **Step 1: Update Patrol expectations first** (they are the failing tests for this task): in `home_test._quickAccess` → `'PRODUCT': 'Products'`, `'RECEIVE ORDER': 'Receive'`, `'OUTFLOW ORDER': 'Outflow'`, `'Category': 'Categories'`, `'Brand': 'Brands'`, `'Unit': 'Units'`; `expectScreen` strings per spec §5 (`'Receive Order Menu'`→`'Receive'`, `'Purchase Order List'`→`'Purchase Orders'`, `'Receive Order List'`→`'Receive Orders'`, `'Receive Order Detail'`→`'Receive Order'`, `'Supplier List'`→`'Suppliers'`, `'Outflow Order Menu'`→`'Outflow'`, `'Outflow Order Detail'`→`'Outflow Order'`, `'Transaction'`→`'Transactions'`); `product_master_test._openMaster(tile, title)` takes the plural title separately. In `receive_order_test`, after the Confirm Serials back tap, assert the PO list is visible and `waitForList($)` succeeds.
- [ ] **Step 2: Swap AppBars** in all views per spec §4; subtitles use controller data already loaded (`currentOrder.poNumber`, `currentSupplier.name`, …) and pass `subtitleLoading: controller.isLoading.value` where the value arrives with the detail call (wrap the header's `Obx` only if the subtitle depends on an Rx). Every screen that passed `routeBackName` now pops.
- [ ] **Step 3: Implement `leave()`** and wire Confirm Serials `onBack`.
- [ ] **Step 4: Delete** the three stock-transaction-detail files and `appBarOrder` / `costumAppbar` / `titleApp`.
- [ ] **Step 5: Verify:** `grep -rn "appBarOrder\|costumAppbar\|titleApp\|StockTransactionDetail" lib test patrol_test` → no matches; `flutter analyze` → no new issues; `flutter test` → PASS; `patrol build android -t patrol_test/home_test.dart` (and the other five edited files) → builds.
- [ ] **Step 6: Leave uncommitted.**

### Task 6: Order headers and main buttons

**Files:**
- Modify: `receive_order_by_po_detail_view.dart:364`, `receive_order_by_supplier_detail_view.dart:367`, `outflow_order_by_request_detail_view.dart:335`, `outflow_order_by_customer_detail_view.dart:338`, `receive_order_list_detail_view.dart:54`, `outflow_order_list_detail_view.dart:30` (header builders) and the "Continue to …" `FilledButton`s in the four Item Summary views.
- Modify: `lib/app/global/widget/order_list_widgets.dart` (delete `orderDetailHeader` once unused).

**Interfaces:**
- Consumes: `accentHeaderCard`, `HeaderStat`, `ProgressSegment`, `AccentProgress`, `headerFooterText` (Task 4); `accentPill`, `statusPill`, `navyButton` (Task 3).

- [ ] **Step 1: Item Summary headers** (spec §4 rows): PO → `AppAccent.sky`, icon `Icons.request_page_rounded`, label `'Purchase order'`, title `'#${po.poNumber}'`, badge `accentPill(po.status)`, stats Expected / Received (`navyMid`) / Receiving now (`skyBlueDark`) summed from `items`, footer `headerFooterText([po.supplier, formatted po.date])`, progress segments received/expected (`navyMid`) + receiving/expected (`skyBlue`) with legend, caption `'$done of $total lines complete'`. Supplier → `AppAccent.sage`, `Icons.storefront_rounded`, label `'Supplier'`, title supplier name, same stats/progress. Request / Customer → `AppAccent.purple` / `amber`, labels `'Outflow request'` / `'Customer'`, stats Reserved / Outflowed / Outflowing, caption `'… lines outflowed'`.
- [ ] **Step 2: Receive Order / Outflow Order headers:** badge = `type` pill (receive: `AppAccent.sky` for PO, `sage` otherwise; outflow: `AppAccent.steel`), stats Lines / Total qty (`+n` `stockInColor`, `-n` `stockOutColor`) / Date, footer `headerFooterText([supplierName, receiveNumber])` / `([customerName, billNumber])`; receive adds progress `'$confirmed of $total serials confirmed'` (green) from the line serials, hidden when no serials.
- [ ] **Step 3: Buttons:** replace the four "Continue to … items (N …)" buttons with `navyButton(size, label, onPressed:, icon: Icons.receipt_long_rounded, loading: …)`; `orderItemSummaryTile` callers pass `actionColor: accent.text`.
- [ ] **Step 4: Delete `orderDetailHeader`** when `grep -rn "orderDetailHeader(" lib` shows no callers.
- [ ] **Step 5: Verify:** `flutter analyze`; `flutter test`; manually open one PO and one request on the emulator (`flutter run`) and check no overflow with a long supplier name.
- [ ] **Step 6: Leave uncommitted.**

### Task 7: Fill, scan and confirm chrome

**Files:**
- Modify: `lib/app/global/widget/order_fill_widgets.dart` (`orderScanFab`, `orderFillBottomBar`, add `orderFillResultsTitle`, delete `orderFillHeaderCard` / `orderFillStatsCard` / `FillStat` when unused)
- Modify: `receive_order_fill_by_po_view.dart`, `receive_order_fill_by_supplier_view.dart`, `scan_page_by_request.dart`, `scan_page_by_customer.dart`, `receive_order_confirm_view.dart`
- Test: `test/widgets/order_fill_widgets_test.dart`

**Interfaces:**
- Produces: `Widget orderFillResultsTitle(double size, String title, {required int count, required AppAccent accent})`; `orderScanFab(... color:)` keeps its signature — `color` now tints the icon on a white FAB with a 3 dp `navyDark` ring; `orderFillBottomBar(... accent:)` keeps its signature — bar uses `navyGradient`, "Continue" white, "Clear" white @ .78 with `Color(0xFFFF9C94)` icon → add that as `clearOnNavy` in `variables.dart`.

- [ ] **Step 1: Write failing tests:** `'bottom bar uses navy gradient'` (find a `DecoratedBox`/`Container` whose `BoxDecoration.gradient == navyGradient`); `'scan fab is white with accent icon'` (`FloatingActionButton.backgroundColor == Colors.white`, icon color `== mutedPurple`); `'results title shows count'` (`orderFillResultsTitle(10, 'Filled Results', count: 2, accent: AppAccent.sky)` finds `'2 entries'`; count 1 → `'1 entry'`).
- [ ] **Step 2: Run** `flutter test test/widgets/order_fill_widgets_test.dart` → FAIL.
- [ ] **Step 3: Restyle the widgets; replace each view's header + stats pair** with `accentHeaderCard` (label `'Item'`, title item name, badge `accentPill(remaining > 0 ? '$remaining left' : 'Done', outlined: true)`, four `HeaderStat`s colored per spec §4 last paragraph, progress received (`navyMid`) + filled/scanned (`accent.base`) over expected/reserved). Confirm Serials: `accentHeaderCard` with Total / Confirmed (`stockInColor`) / Remaining and a green progress, bottom pill on `navyGradient`, FAB per `orderScanFab`.
- [ ] **Step 4: Run** the widget tests → PASS; `flutter analyze`; `patrol build android -t patrol_test/receive_order_test.dart`.
- [ ] **Step 5: Leave uncommitted.**

### Task 8: Inventory screens and master lists

**Files:**
- Modify: `product/views/product_view.dart` (summary card + "Products list" row), `product/views/product_detail_view.dart` (product card), `global/widget/product_by_filter_view.dart` (header card), `product/views/product_transaction_list_view.dart:283` and `transaction/views/stock_transaction_view.dart:140` (leading → `stockDirectionIcon`; product transactions `Scaffold.backgroundColor: Colors.white`).
- Modify: `global/widget/master_list_view.dart:258` (`masterListCard`), `product-brand/views/product_brand_view.dart`, `product-category/views/product_category_view.dart`, `product-unit/views/product_unit_view.dart`; delete `getAccentColor2` from `global/functions.dart` when unused.
- Test: `test/widgets/master_list_card_test.dart` (new; `test/helpers/master_monogram_test.dart` stays as is).

**Interfaces:**
- Produces: `enum MasterKind { brand, category, unit }`; `Widget masterListCard({required double size, required MasterKind kind, required String avatarText, required String title, required String subtitle, required VoidCallback onTap, bool subtitleMissing = false})` (removes `accent` / `subtitleColor`; accent = `accentFor(title)`).

- [ ] **Step 1: Write failing tests:** `'master card tile uses palette accent'` (tile `BoxDecoration.color == accentFor('Indo Kemas').tint(.14)`); `'kind badge icon'` (brand → `Icons.sell_rounded`, category → `Icons.category_rounded`, unit → `Icons.straighten_rounded`); `'missing subtitle is italic grey'` (`subtitleMissing: true` → `fontStyle == FontStyle.italic`).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Restyle `masterListCard`** per spec §3.6 and update the three callers: unit passes `avatarText: unit.name`, `title: description.isNotEmpty ? description : unit.name`, `subtitle: unit.name`. Product view: `accentHeaderCard`-style summary via `accentHeaderCard(accent: slate, icon: Icons.inventory_2_rounded, label: 'Inventory', title: 'Products', stats: [Total products, Stock in hand])` plus count pill on the "Products list" row (keep that exact text — `product_test` looks for it). Product detail: `accentHeaderCard(accent: slate, icon: Icons.inventory_2_rounded, label: 'Product', title: itemName, code: itemCode, badge: statusPill('Available'/'Low Stock'), stats: [Stock in hand, In, Out], progress: qtyRemaining / qtyIn)`. Product by filter: `accentHeaderCard(label: 'Product Brand' | 'Product Category', title: name, code: code)` — no stats; the label text stays exactly `'Product Brand'` / `'Product Category'` (Patrol).
- [ ] **Step 4: Run** `flutter test` → PASS; `flutter analyze`; `patrol build android -t patrol_test/product_master_test.dart`.
- [ ] **Step 5: Leave uncommitted.**

### Task 9: Hubs, list colors and delivery

**Files:**
- Modify: `receive_order_home_view.dart`, `outflow_order_home_view.dart`, `order_menu_widgets.dart` (add `orderMenuInfoCard`), `receive_order_list_view.dart`, `receive_order_list_detail_view.dart` (line cards + FAB `navyDark`), `outflow_order_list_view.dart` + `outflow_order_list_detail_view.dart` (cards `mutedPurple`).
- Modify: `delivery/views/delivery_detail_view.dart`, `delivery/delivery_actions.dart`, `outflow_order/controllers/outflow_order_list_detail_controller.dart`, the two post-submit callers in `outflow_order_by_request_detail_controller.dart:312` / `outflow_order_by_customer_detail_controller.dart:282`.

**Interfaces:**
- Produces: `Widget orderMenuInfoCard({required double size, required String title, required String subtitle, required IconData icon, required AppAccent accent, required VoidCallback onTap})`; `Widget deliveryStatusPanel(double size, {required DeliveryStatusModel current, required List<DeliveryStatusModel> others, required void Function(DeliveryStatusModel) onMark, required VoidCallback onEdit})`; `createDeliveryForOutflow(int id, {RxBool? isLoading, bool replace = false})`.

- [ ] **Step 1: Hubs:** both `orderMenuHero` calls get `[navyDark, navyMid]`; Receive section header color `navyDark`; Outflow "Deliveries" hero → `orderMenuInfoCard(accent: AppAccent.steel, icon: Icons.local_shipping_rounded, title: 'Deliveries', subtitle: 'Track & dispatch deliveries')` (no counts).
- [ ] **Step 2: List colors** per spec §4 (receive history `navyDark`, outflow history `mutedPurple`).
- [ ] **Step 3: Delivery detail:** `accentHeaderCard(accent: steel, icon: Icons.route_rounded, label: 'Delivery', title: '#code', badge: statusPill(status.name, hex color), stats: [ETA ('No ETA set' when null), Customer])`; delete the status banner; replace the status button wrap + "Edit details" with `deliveryStatusPanel`; `onMark` on a status whose `name.toLowerCase().contains('cancel')` first shows a confirm dialog (closed via `closeRoute`).
- [ ] **Step 4: Stale-back fix (Review Focus 4):** `outflow_order_list_detail_controller.createDelivery` awaits `createDeliveryForOutflow` and, on `true`, calls `loadOutflowOrderDetail()` before navigating, so popping back shows "View Deliveries". Post-submit callers pass `replace: true`, which uses `Get.offAndToNamed(AppPages.deliveryListPage)` so the submitted Item Summary is not underneath. Extend `patrol_test/delivery_test.dart`: after creating a delivery from an outflow detail and tapping back, expect `'View Deliveries'` and no `'Create Delivery'`.
- [ ] **Step 5: Verify:** `flutter analyze`; `flutter test`; `patrol build android -t patrol_test/delivery_test.dart` and `outflow_order_test.dart`.
- [ ] **Step 6: Leave uncommitted.**

### Task 10: Docs and full verification

**Files:**
- Modify: `CLAUDE.md` (Architecture → `global/` bullet, "Order-module UI", "Color Palette", "Alert helpers" untouched): document `appHeader`, `AppAccent`, `accentHeaderCard`, `navyButton`, `accentPill`/`statusPill`, `stockDirectionIcon`, `orderMenuInfoCard`, the three `*Dark` shades, the "one color per page / buttons navy / cross-module color" rules, and remove `appBarOrder` mentions.
- Modify: `docs/superpowers/specs/2026-10-27-navy-header-ui-design.md`: §3.5 — existing widgets keep `Color` params; §3.1 — `appHeader` gains `onBack`; §3.2 — `footer` is `String?` (built with `headerFooterText`) plus `footerIcon`; §1 — add `clearOnNavy`.

- [ ] **Step 1: Update both docs.**
- [ ] **Step 2: Run** `flutter analyze` → no new issues vs. the baseline from before Task 1; `flutter test` → all PASS; `patrol build android` (all) → builds. With a device + credentials: `patrol test --dart-define=TEST_USERNAME=… --dart-define=TEST_PASSWORD=…` against the demo tenant → PASS.
- [ ] **Step 3: Visual pass** on an emulator at a small width (e.g. 360×640): open each screen in spec §4 once; no overflow stripes, header/back consistent, Home unchanged.
- [ ] **Step 4: Leave uncommitted;** report the changed-file list to the user.
