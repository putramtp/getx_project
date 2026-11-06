import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

String getDateString(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

Future<DateTime?> pickDate(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  return await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: firstDate ?? DateTime(2010),
    lastDate: lastDate ?? DateTime.now(),
  );
}

int safeToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  // num.tryParse: MySQL SUM()/DECIMAL values arrive as "320.000000".
  if (value is String) return num.tryParse(value.trim())?.toInt() ?? 0;
  return 0;
}

/// Quantities are DECIMAL(18,6) on the backend (kg, metre, ...). Rounds to that
/// scale so float sums don't drift (0.1 + 0.2 must equal 0.3 in the over-fill
/// guards), and returns whole values as `int` so they print as "3", not "3.0".
num roundQty(num value) {
  final rounded = (value * 1000000).round() / 1000000;
  return rounded == rounded.truncateToDouble() ? rounded.toInt() : rounded;
}

num safeToNum(dynamic value) {
  if (value is num) return roundQty(value);
  if (value is String) return roundQty(num.tryParse(value.trim()) ?? 0);
  return 0;
}

/// Total `qty` over fill/scan entries.
num sumQty(Iterable<Map> entries) =>
    roundQty(entries.fold<num>(0, (sum, e) => sum + safeToNum(e['qty'])));

String formatQty(num value) => '${roundQty(value)}';

/// Snackbar text after Clear on a fill/scan screen: how many entries went and
/// the quantity they held ("Removed 1 entry (qty 3) from …") — an entry count
/// alone read as a quantity.
String clearedEntriesMessage(List? entries, String name) {
  final list = List<Map>.from(entries ?? const []);
  final noun = list.length == 1 ? 'entry' : 'entries';
  return 'Removed ${list.length} $noun (qty ${formatQty(sumQty(list))}) from $name';
}

/// Parses a typed quantity ("2.5", "2,5", ".5", "5."). Null when blank, not above 0,
/// beyond 6 decimals, a fraction where [wholeUnits] are required, or not plain
/// digits with at most one decimal separator — so "1e3", "0x10", "NaN",
/// "Infinity" and signs are refused, and so is [looksLikeThousands] input.
num? parseQty(String text, {bool wholeUnits = false}) {
  final typed = _qtyText(text);
  if (!RegExp(r'^\d+([.,]\d+)?$').hasMatch(typed) || looksLikeThousands(typed)) return null;
  final value = num.tryParse(typed.replaceAll(',', '.'));
  if (value == null || value <= 0) return null;
  final qty = roundQty(value);
  if (qty != value) return null;
  if (wholeUnits && qty is! int) return null;
  return qty;
}

/// Typed input that reads as a thousands-grouped number ("1.000", "12,000",
/// "1.000.000"): taken as a decimal it would silently become 1 / 12 / junk.
/// ".000" adds nothing to a decimal, so whoever typed it meant thousands.
/// ("1.500" may be 1.5 kg or 1500: see [ambiguousQty].)
bool looksLikeThousands(String text) {
  final typed = _qtyText(text);
  return RegExp(r'^\d{1,3}([.,]\d{3}){2,}$').hasMatch(typed) || RegExp(r'^\d{1,3}[.,]000$').hasMatch(typed);
}

/// Typed quantity text as the qty helpers read it: trimmed, ".5" as "0.5" and
/// "5." as "5" — plain decimals a worker types. One place, so [parseQty],
/// [looksLikeThousands] and [ambiguousQty] judge the same text ("1.500." is
/// "1.500" to all three, not 1.5 to one and nothing to the others).
String _qtyText(String text) {
  final typed = text.trim();
  if (RegExp(r'^[.,]\d+$').hasMatch(typed)) return '0$typed';
  if (RegExp(r'\d[.,]$').hasMatch(typed)) return typed.substring(0, typed.length - 1);
  return typed;
}

/// The two readings of a typed quantity that may be either ("1.500",
/// "12,250": a 1–3 digit whole part, one separator, exactly three digits).
/// In English it is 1.5, in Indonesian 1500 — the app can't tell, so the qty
/// dialogs ask ([parseQty] alone takes the decimal). Null when the text is
/// not ambiguous: "0.125" (no thousands start with 0), "1.5", "1.000"
/// ([looksLikeThousands], refused outright).
({num decimal, int thousands})? ambiguousQty(String text) {
  final typed = _qtyText(text);
  if (!RegExp(r'^[1-9]\d{0,2}[.,]\d{3}$').hasMatch(typed) || looksLikeThousands(typed)) return null;
  return (
    decimal: roundQty(num.parse(typed.replaceAll(',', '.'))),
    thousands: int.parse(typed.replaceAll(RegExp(r'[.,]'), '')),
  );
}

/// Serial-tracked UNIQUE/BATCH lines count whole units — the backend makes one
/// SKU per unit / batch entry and rejects fractions. Everything else (quantity
/// only) may be fractional.
bool wholeUnitsOnly(Map item) =>
    item['manage_sn'] == true && const ['UNIQUE', 'BATCH'].contains(item['serialNumberType']);

/// The reason a PO/OR summary line can't be received/issued from the app: the
/// backend sends `[flag]: false` (`can_receive` / `can_issue`) with a
/// `blocked_reason`. Null when the line is open — or the backend predates the flag.
String? lineBlockedReason(Map<String, dynamic> json, String flag) {
  if (json[flag] != false) return null;
  final reason = json['blocked_reason']?.toString().trim() ?? '';
  return reason.isEmpty ? 'This line cannot be processed from the app.' : reason;
}

/// A line the backend refuses: shown read-only, never filled/scanned or submitted.
bool isLineBlocked(Map item) => item['blocked_reason'] != null;

/// The first line after [after] that can still be filled/scanned, or null.
int? nextOpenLine(List<Map> items, int after) {
  for (var i = after + 1; i < items.length; i++) {
    if (!isLineBlocked(items[i])) return i;
  }
  return null;
}

/// The receive/outflow lines worth submitting: those with at least one entry
/// under [entriesKey] ("filled" on receive, "scanned" on outflow) whose qty is
/// above 0. The backend saves every line it is sent, so an unfilled one would
/// become a qty-0 document line and stock transaction.
List<Map<String, dynamic>> linesToSubmit(Iterable<Map<String, dynamic>> items, String entriesKey) => [
      for (final item in items)
        if (((item[entriesKey] as List?) ?? const []).any((e) => (num.tryParse('${e['qty']}') ?? 0) > 0))
          item,
    ];

/// The submit body's `items`: [linesToSubmit] reduced to what the backend
/// reads — `line_id` and the [entriesKey] entries. The idempotency check hashes
/// the whole body, so the line's `received` / `reserved` (which change once the
/// document is booked) must not be in it: a retry after reopening the screen
/// has to hash the same to be recognised.
List<Map<String, dynamic>> submitLines(Iterable<Map<String, dynamic>> items, String entriesKey) => [
      for (final item in linesToSubmit(items, entriesKey))
        {'line_id': item['line_id'], entriesKey: item[entriesKey]},
    ];

/// Empties every line's [entriesKey] entries ("filled" / "scanned") in memory.
/// After `submit_already_saved` the entries on screen were already booked: if
/// they stayed, the next tap would send them again with a fresh key — even
/// when the reload that should replace them fails.
void dropAllEntries(RxList<Map<String, dynamic>> items, String entriesKey) {
  for (final item in items) {
    item[entriesKey] = <Map<String, dynamic>>[];
  }
  items.refresh();
}

/// Sorts [rows] in place by [key]: A→Z when [ascending], else Z→A. A list's
/// Sort button sorts only the rows loaded so far (the list endpoints take no
/// sort), so the controllers re-run it after every reload and next page —
/// else a page appended below, or a reload, undoes the order the button shows.
void sortRowsBy<T>(List<T> rows, String Function(T row) key, {required bool ascending}) =>
    rows.sort((a, b) => ascending ? key(a).compareTo(key(b)) : key(b).compareTo(key(a)));

String formatPrice(dynamic value) {
  if (value == null) return "-";

  final number = num.tryParse(value.toString()) ?? 0;
  return NumberFormat.decimalPattern('id_ID').format(number);
}


/// Closes the top route (dialog, bottom sheet or page), optionally returning
/// [result]. Use this instead of `Get.back()`: in GetX 4.7, `Get.back()` only
/// closes an open snackbar when one is showing, leaving the route up. Snackbars
/// are overlays, not routes, so popping the root navigator leaves them alone.
/// Pops synchronously (not `maybePop`, which pops after an await) so a route
/// opened right after this call isn't the one that gets closed.
void closeRoute<T>([T? result]) {
  final navigator = Get.key.currentState;
  if (navigator != null && navigator.canPop()) navigator.pop<T>(result);
}

/// The route really on top of the root navigator (page, dialog or sheet).
/// Not `Get.rawRoute`: that is GetX's bookkeeping, and after `offNamedUntil`
/// it names the route the unwind stopped at (e.g. the Outflow menu), not the
/// page just pushed. `popUntil` with a predicate true at once pops nothing.
Route<dynamic>? topRoute() {
  Route<dynamic>? top;
  Get.key.currentState?.popUntil((route) {
    top = route;
    return true;
  });
  return top;
}

/// Whether [page] — the page a submit started on, taken with [topRoute]
/// before its request — is still on the stack. The steps after the answer
/// (Confirm Serials, the delivery prompt, back to the list) navigate relative
/// to the top of the stack: run after the worker left the page (Back while it
/// was sending), they replaced another document's page or popped Home.
bool submitPageStillOpen(Route<dynamic>? page) => page != null && page.isActive;

/// Opens [route] with a fresh controller of type [T] (a detail page bound by
/// `lazyPut`). GetX deletes the previous page's controller only once that route
/// is disposed, about 300 ms after Back. Force-deleting it earlier and pushing
/// the new page let that late disposal delete the NEW page's controller (its
/// draft stopped saving, then "controller not found"). So wait for it to go
/// first; force-delete only a leftover that outlived the wait.
///
/// A second call while one is still opening (a double tap during the wait or
/// the push animation, when the page underneath still takes taps) is ignored:
/// it would force-delete the page just opened. And if the worker left the
/// screen during the wait, nothing opens.
Future<dynamic> openFresh<T>(String route, {dynamic arguments}) async {
  if (_openingFresh) return null;
  _openingFresh = true;
  final from = topRoute();
  Future<dynamic>? opened;
  try {
    final deadline = DateTime.now().add(const Duration(milliseconds: 800));
    while (Get.isRegistered<T>() && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (from != null && !from.isCurrent) return null;
    if (Get.isRegistered<T>()) Get.delete<T>(force: true);
    opened = Get.toNamed(route, arguments: arguments);
    // Taps still reach the page underneath until the push animation ends.
    await Future.delayed(const Duration(milliseconds: 400));
  } finally {
    _openingFresh = false;
  }
  return opened;
}

bool _openingFresh = false;

/// After a submit: pop back to the [listRoute] the flow started from and let
/// [refresh] reload it, so it shows the document's new state.
///
/// The list keeps its controller — never delete it first. Pushing a second
/// copy failed both ways: `offAndToNamed` left the old list underneath with a
/// deleted controller (Back landed on a dead page), and `offNamedUntil`
/// disposed the old list right away, which deleted the new list's controller
/// of the same type ("OutflowOrderByCustomerController not found").
/// When [listRoute] isn't on the stack, popping stops at the module's
/// [menuRoute] and the list is opened above it, so Back still reaches the menu.
void returnToListAfterSubmit(String listRoute, {required String menuRoute, required VoidCallback refresh}) {
  var found = false;
  Get.key.currentState?.popUntil((route) {
    if (route.settings.name == listRoute) found = true;
    return found || route.settings.name == menuRoute || route.isFirst;
  });
  if (found) {
    refresh();
  } else {
    Get.toNamed(listRoute);
  }
}
