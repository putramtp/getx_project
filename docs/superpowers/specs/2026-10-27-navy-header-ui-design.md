# Navy Header & Accent Components — Design

Date: 2026-10-27
Status: Draft (awaiting review)
Mockups: AppBar spec — https://claude.ai/artifact/FCXvpEvSif7SPAdwjMCLVM ·
before/after of every page — https://claude.ai/artifact/JjGFy486gXT3sYUitoJUMC

## Goal

Make every screen except Home look like one product. Today the 30 AppBars use 9
gradient pairs, 3 back-arrow styles and an optional icon that moves the title, and the
cards/buttons below them use hard-coded colors (`#31694E`, `#528FF3`, indigo, a
`steelBlue` default on By-PO screens). Replace this with:

1. one **navy AppBar** (`appHeader`) with a white module tile,
2. one **color source** (`AppAccent`) that every component reads from,
3. a small set of **reusable components** that cover all header cards, buttons and
   list leadings, so screens become thin compositions.

## Decisions (from review)

| Topic | Decision |
|---|---|
| AppBar | Navy gradient bar (`navyDark → navyMid`, same as Home). White title, white back arrow. Module color appears **only** in a white rounded tile (icon in the module color). |
| Home | **Not changed.** `home_view.dart` keeps its AppBar, wave and logo plate. |
| Page color | The tile icon color is the page's accent. Icon chips, list cards, progress bars and pills use it. |
| Buttons | Main buttons, the fill/scan bottom bar and the FAB ring use **header navy**. Exception: a button that opens another module uses that module's color ("Create Delivery" = steel). |
| Header cards | The card directly under the AppBar is a **patterned card**: white → accent tint at the corner, two faint circles (Home greeting-card motif), gradient icon tile. No solid gradient block under the navy bar. Only the hub hero cards keep a full gradient. |
| Text contrast | Small accent text on white (pills, counts) uses a dark variant for sky / amber / sage so it passes 4.5:1. |
| Back | Always pops (`closeRoute()`). `routeBackName` is removed — today it pushes a new copy of the parent screen. |

## 1. Colors — `variables.dart`

Add three text-safe shades (the only new constants):

```dart
const Color skyBlueDark  = Color(0xFF3D78B4); // white text 4.6:1
const Color amberDark    = Color(0xFF9B6B21); // white text 4.7:1
const Color sageTealDark = Color(0xFF517D6D); // white text 4.7:1
```

Stock direction colors are centralized (today `Colors.green` / `Colors.red` /
`Colors.orange` are repeated inline in three views):

```dart
const Color stockInColor  = Color(0xFF2E9B5F);
const Color stockOutColor = Color(0xFFD2453B);
```

Added during implementation: `clearOnNavy` (`#FF9C94`, "Clear" icon on the navy bottom
bar) and `cardOutline` (`#E1E6EE`, the 1 dp master-card outline from §3.6).

## 2. `AppAccent` — single color source

New file `lib/app/global/accent.dart`:

```dart
enum AppAccent {
  navy(navyDark, navyMid, navyDark),
  slate(navyMid, navyLight, navyMid),        // Inventory: products, master data, transactions
  sky(skyBlue, skyBlueLight, skyBlueDark),   // Receive · By PO
  sage(sageTeal, sageTealLight, sageTealDark), // Receive · By Supplier
  purple(mutedPurple, softPurple, mutedPurple), // Outflow · By Request / history
  amber(amber, amberLight, amberDark),       // Outflow · By Customer
  steel(steelBlue, lightSteelBlue, steelBlue); // Delivery

  const AppAccent(this.base, this.light, this.text);
  final Color base;   // icons, progress, borders
  final Color light;  // gradient end
  final Color text;   // small text on white / tint
  Color tint([double a = 0.12]) => base.withValues(alpha: a);
  LinearGradient get gradient => LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [base, light]);
}

/// Header navy, used by the AppBar, main buttons and the bottom bar.
const LinearGradient navyGradient = LinearGradient(colors: [navyDark, navyMid]);

/// Picks a palette accent for a master-data item (replaces getAccentColor2's random hue).
AppAccent accentFor(String name) => const [
      AppAccent.slate, AppAccent.sky, AppAccent.sage,
      AppAccent.purple, AppAccent.amber, AppAccent.steel,
    ][name.codeUnits.fold<int>(0, (a, c) => a + c) % 6];
```

`getAccentColor2` is deleted once `masterListCard` uses `accentFor`.

## 3. Components

All are top-level functions taking `double size` (`SizeConfig.defaultSize`), like the
existing `order_*_widgets.dart`, and use `AppTextStyle` only. Sizes below are dp at
400 dp width.

### 3.1 `appHeader` — `global/widget/app_header.dart`

```dart
PreferredSizeWidget appHeader(String title, {
  required AppAccent accent,
  required IconData icon,
  String? subtitle,              // context line, e.g. 'By PO · PO-2026-0187'
  bool subtitleLoading = false,  // skeleton while the controller loads
  List<Widget> actions = const [],
  bool showBack = true,
  VoidCallback? onBack,          // overrides the default pop (Confirm Serials → leave())
})
```

`obxHeader(() => appHeader(...))` wraps a header whose subtitle reads Rx state.

- 60 dp toolbar, `flexibleSpace` = `navyGradient` (left → right), elevation 0,
  `scrolledUnderElevation` 3, `surfaceTintColor` transparent,
  `SystemUiOverlayStyle.light`.
- Leading: `IconButton(key: Key('appBarBackButton'), Icons.arrow_back_rounded, white,
  onPressed: () => closeRoute())`, 48 dp target.
- Tile: 36 dp, radius 10, white, soft dark shadow, icon 18 dp in `accent.base`.
- Title 16/w700 white, one line ellipsis. Subtitle 12/w500 white 74 %.
- `headerAction(icon, tooltip:, onPressed:)`: 40 dp, radius 12, white 14 % fill.
- `main.dart` `appBarTheme` becomes `navyDark` with white icons (today a stray light blue).
- Deletes: `appBarOrder`, `costumAppbar`, `titleApp` (`functions_widget.dart`).

### 3.2 `accentHeaderCard` — `global/widget/accent_header_card.dart`

The patterned card under the AppBar. One component covers every detail header.

```dart
Widget accentHeaderCard({
  required double size,
  required AppAccent accent,
  required IconData icon,
  required String label,          // 'Purchase order' — small caps style, not upper-cased
  required String title,          // '#PO-2026-0187' / 'Indo Kemas' / item name
  String? code,                   // optional mono chip under the title ('BR-007')
  Widget? badge,                  // top-right: accentPill / statusBadge
  List<HeaderStat> stats = const [],   // 2–4 columns with dividers
  String? footer,                 // built with headerFooterText([...]) — null parts dropped
  IconData footerIcon = Icons.info_outline_rounded,
  AccentProgress? progress,       // segmented bar + caption + optional legend
  Widget? child,                  // extra slot below the stats
})

class HeaderStat { final String label; final String value; final Color? color; }
class ProgressSegment { final double fraction; final Color color; final String? legend; }
class AccentProgress { final List<ProgressSegment> segments; final String caption; final bool showLegend; }
```

Pattern: radius 17, border `accent.tint(.18)`, background
`LinearGradient(white 45 % → accent.tint(.11))`, two `Positioned` circles
(`accent.tint(.09)` 110 dp top-right, `accent.light` @ .12 70 dp), shadow
`accent.base @ .35`. Icon tile 44 dp radius 13 with `accent.gradient`, white icon.
Stats box: white, radius 12, 1 dp border tinted by the accent; label 8.5 sp above value.
Progress track `accent.tint(.14)`.

Reuses the decor-circle helper already in `order_menu_widgets.dart` (`_decorCircle`
becomes public `decorCircle`).

Replaces `orderDetailHeader`, `orderFillHeaderCard` + `orderFillStatsCard`, the Product
Detail glass card, the product-by-filter gradient card, the confirm-serials gradient
card and the delivery status banner.

### 3.3 Pills and badges — `global/widget/accent_pill.dart`

```dart
Widget accentPill(double size, String text, {required AppAccent accent, IconData? icon, bool outlined = false});
Widget statusPill(double size, String text, Color color, {IconData? icon}); // API status colors
```

Text uses `accent.text`; background `accent.tint(.12)` (or white + border when
`outlined`). Used for: card badges ("Processing", "By PO", "12 left"), Fill/Scan action
pills in `orderItemSummaryTile`, results counts ("2 entries").

### 3.4 Buttons — `global/widget/app_buttons.dart`

```dart
Widget navyButton(double size, String label, {required VoidCallback? onPressed, IconData? icon, bool loading = false});
Widget accentOutlineButton(double size, String label, {required Color color, required VoidCallback? onPressed, IconData? icon});
```

- `navyButton`: full width, 46 dp, radius 14, `navyGradient`, white 11 sp bold, soft navy
  shadow; disabled = grey. Replaces every "Continue to … items" `FilledButton`
  (`steelBlue`, `#31694E`, `mutedPurple`, `amber`).
- `accentOutlineButton`: 1.5 dp border at 45 %, colored text. Used for the
  delivery "Mark <Status>" buttons (API color) and "Edit details" (navy).
- "Create Delivery" / "View Deliveries" stay **steel** (`AppAccent.steel`, cross-module rule).

### 3.5 Fill / scan chrome — `order_fill_widgets.dart` (restyle in place)

- `orderFillBottomBar`: pill becomes `navyGradient`; "Clear" white 78 % with
  `#FF9C94` icon; "Continue" white. Disabled = white 40 %.
- `orderScanFab`: white circle, 3 dp `navyDark` ring, icon in `accent.base`.
- Confirm Serials custom bottom pill uses the same navy style.
- `orderFillResultsTitle(size, title, count, accent)`: title + `accentPill('N entries')`.

Existing widgets keep their `Color` parameters (callers pass `AppAccent.x.base` / `.text`);
only new components take `AppAccent`.

### 3.6 List leadings

- `stockDirectionIcon(size, {required bool isIn})` — outlined 32 dp square, radius 10,
  1.5 dp border at 55 %, 7 % tint, ▼/▲ in `stockInColor` / `stockOutColor`.
  Used by `stock_transaction_view` and `product_transaction_list_view`
  (background of the latter becomes white).
- `masterListCard` (restyle in place): outlined card (1 dp `#E1E6EE`, radius 14, no
  colored shadow); 40 dp rounded tile tinted from `accentFor(name)` with the code
  text in `accent.text` and a small kind badge (`sell` / `category` / `straighten`);
  chevron in a soft navy circle. New param `MasterKind kind`. Unit: tile shows the
  unit code in mono, the description becomes the title, "No description" in light
  italic.

### 3.7 Menu & dashboard pieces

- `orderMenuHero`: Outflow hero uses `navyGradient` (same as Receive). Section bar
  "Create Receiving" becomes `navyDark`.
- `orderMenuInfoCard` (new, `order_menu_widgets.dart`): white tile-style card with a
  gradient icon tile, title/subtitle, "Open →" and an optional row of status counts.
  Replaces the second "Deliveries" hero on the Outflow menu. **No status counts**
  (decided: no extra `GET /delivery` on the menu).
- **No delivery stepper.** `delivery_statuses` has only `name` + `color` (tenant-defined,
  no order column), so a fixed Pending → Shipped → Delivered order cannot be trusted.
- `deliveryStatusPanel`: "Update status" card with a "Now: <status>" hint, one
  `accentOutlineButton('Mark <Status>', color: <API color>)` per other status (same
  set as today), and `accentOutlineButton('Edit details', color: navyDark)`.
  A status whose name contains "cancel" asks for confirmation first.

## 4. Screen mapping

`S` = subtitle. Fields in `{}` come from the controller. Every field below was checked
against the models / backend on 2026-10-27 (see "Data check").

| View | Title (old → new) | Tile icon | Accent | Under-header component |
|---|---|---|---|---|
| home_view | — unchanged — | | | |
| product_view | Product → **Products** | inventory_2 | slate | `accentHeaderCard` summary (Total products / Stock in hand, low-stock count); "Products list" row with count pill + tinted icon buttons |
| product_detail_view | Product Detail (S: `{itemCode}`) | info_outline | slate | `accentHeaderCard` (code chip, Available badge, stock in hand + In/Out, stock bar); header moves out of the scroll view |
| product_transaction_list_view | Transaction → **Transactions** (S: `{itemName}`) | history | slate | white background, `stockDirectionIcon` |
| product_by_filter_view | Product → **Products** (S: Brand · `{name}`) | sell / category | slate | `accentHeaderCard` (label keeps "Product Brand"/"Product Category", name + code chip; **no stats row** — the by-brand/category endpoints return no totals) |
| product_brand / category / unit | Brand/Category/Unit → **Brands/Categories/Units** (S: Master data) | sell / category / straighten | slate | restyled `masterListCard` |
| stock_transaction_view | Stock Transactions (S: Inventory) | swap_vert | slate | `stockDirectionIcon` |
| stock_transaction_detail_view | **Deleted** — no route in `app_pages.dart`, never opened; a copy of Receive Order Detail. Delete view, controller and binding. | | | |
| receive_order_home_view | Receive Order Menu → **Receive** | move_to_inbox | navy | hero navy pair, section bar navy |
| receive_order_list_view | Receive Order List → **Receive Orders** (S: Receiving history) | history | navy | list cards navy |
| receive_order_list_detail_view | Receive Order Detail → **Receive Order** | assignment_turned_in | navy | `accentHeaderCard` (`type` badge, lines / total qty / `date`, footer `supplierName` · `receiveNumber`, serial-confirmation progress from lines); line cards + FAB navy |
| receive_order_by_po_view | Purchase Order List → **Purchase Orders** (S: Receive · By PO) | request_page | sky | — |
| receive_order_by_po_detail_view | Item Summary (S: By PO · `{po}`) | list_alt | sky | `accentHeaderCard` (`status` badge, expected / received / receiving now from lines, footer `supplier` · `date`, two-tone progress + legend); `navyButton` |
| receive_order_fill_by_po_view | Fill Item (S: `{po}` · `{item}`) | edit_note | sky | `accentHeaderCard` item + 4 stats + progress, "N left" badge; navy bottom bar |
| receive_order_by_supplier_view | Supplier List → **Suppliers** | storefront | sage | — |
| receive_order_by_supplier_detail_view | Item Summary (S: By Supplier · `{name}`) | list_alt | sage | `accentHeaderCard` + progress; `navyButton` (replaces `#31694E`) |
| receive_order_fill_by_supplier_view | Fill Item | edit_note | sage | as Fill by PO |
| receive_order_confirm_view | Confirm Serials (S: `{ro}` · x of y confirmed) | fact_check | sky / sage | `accentHeaderCard` (total / confirmed / remaining + green progress); navy bottom pill |
| outflow_order_home_view | Outflow Order Menu → **Outflow** | outbox | purple | hero navy; `orderMenuInfoCard` for Deliveries (no counts) |
| outflow_order_list_view | Outflow Order List → **Outflow Orders** | history | purple | list cards `mutedPurple` |
| outflow_order_list_detail_view | Outflow Order Detail → **Outflow Order** | receipt_long | purple | `accentHeaderCard` (`type` badge in steel, lines / total qty / `date`, footer `customerName` · `billNumber`); Create Delivery stays steel |
| outflow_order_by_request_view | Outflow Request List → **Outflow Requests** | assignment | purple | — |
| outflow_order_by_request_detail_view | Item Summary (S: By Request · `{code}`) | list_alt | purple | `accentHeaderCard` + progress; `navyButton` |
| scan_page_by_request | Scan Item | qr_code_scanner | purple | as Fill (Reserved/Received/Scanned/Remaining) |
| outflow_order_by_customer_view | Customer List → **Customers** | groups | amber | — |
| outflow_order_by_customer_detail_view | Item Summary (S: By Customer · `{name}`) | list_alt | amber | `accentHeaderCard` + progress; `navyButton` |
| scan_page_by_customer | Scan Item | qr_code_scanner | amber | as Fill |
| delivery_list_view | Deliveries (S: Logistics) | local_shipping | steel | — |
| delivery_detail_view | Delivery Detail (S: `{code}` · `{status}`) | route | steel | `accentHeaderCard` (status badge in the API color, stats ETA / customer); status banner removed; `deliveryStatusPanel` |

Stats in fill/scan cards: Expected/Reserved grey, Received `navyMid`, Filled/Scanned
`accent.base`, Remaining red (grey when ≤ 0).

## 5. Tests

- **Keep** `Key('appBarBackButton')`.
- `patrol_test` finds screens by AppBar title (`expectScreen`). Update the renamed
  titles: `Outflow Order Menu`→`Outflow`, `Receive Order Menu`→`Receive`,
  `Purchase Order List`→`Purchase Orders`, `Receive Order List`→`Receive Orders`,
  `Receive Order Detail`→`Receive Order`, `Supplier List`→`Suppliers`,
  `Outflow Order Detail`→`Outflow Order`, `Transaction`→`Transactions`, and the
  master lists (`product_master_test._openMaster` uses the tile text as the title —
  pass the new plural title separately).
- `product_master_test` waits for `'Product Category'`: the card label keeps that exact
  text (styled small, not upper-cased in the string).
- `home_test` quick-access map: update titles to the new names.
- `test/`: add widget tests for `appHeader` (back calls `closeRoute`, subtitle
  skeleton) and `accentHeaderCard` (renders stats/progress, no overflow at 320 dp).
- Run `flutter analyze`, `flutter test`, then the Patrol suite on a device.

## 6. Rollout order

1. `variables.dart` colors, `accent.dart`, `app_header.dart`, `accent_pill.dart`,
   `app_buttons.dart`, `accent_header_card.dart` (+ widget tests).
2. Delete `stock_transaction_detail_view` + its controller and binding. Swap every
   remaining AppBar (26 `appBarOrder` calls + Product Detail's custom row) to
   `appHeader`; delete `appBarOrder`/`costumAppbar`/`titleApp`; `appBarTheme`.
3. Detail headers → `accentHeaderCard`; buttons → `navyButton`.
4. Fill/scan chrome, confirm serials.
5. List leadings (`stockDirectionIcon`, `masterListCard`), product view summary,
   outflow menu, delivery detail.
6. Update Patrol titles; analyze + tests.

Each step leaves the app building. No commits — changes stay uncommitted for review.

## Data check (2026-10-27)

| Card | Field | Result |
|---|---|---|
| By-PO Item Summary | supplier, date, status | ✅ `PurchaseOrderModel.supplier/date/status` (passed as `Get.arguments`) |
| | expected / received / receiving | ✅ from line items |
| Receive Order | supplier, date, type, qty | ✅ `ReceiveOrderDetailModel.supplierName/date/type`, lines `qty` |
| | PO number | ❌ lines only carry `poLineId` → use `receiveNumber` instead |
| Outflow Order | customer, date, type, qty | ✅ `OutflowOrderDetailModel.customerName/date/type`, lines `qty` |
| | request number | ❌ lines only carry `orLineId` → use `billNumber` instead |
| Product Detail | stock in hand, in, out | ✅ `ProductSummaryModel.qtyRemaining/qtyIn/qtyOut/lowStock` |
| Products summary | total, stock in hand | ✅ `ProductController.totalProducts/stockInHand` |
| Product by Brand/Category | products / stock / low stock | ❌ `summaryCurcorByItemBrand/Category` return no totals → stats row dropped |
| Delivery Detail | status order for a stepper / "next" button | ❌ `delivery_statuses` = `name`, `color`, no order → no stepper, one button per status |
| Outflow menu | delivery counts | possible (`GET /delivery` is unpaginated) → **not used** (decided) |
| Stock transaction detail | — | screen unreachable → **deleted** (decided) |

No backend changes in this scope.
