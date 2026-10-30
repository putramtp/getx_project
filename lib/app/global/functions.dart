import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:intl/intl.dart';

String capitalizeFirstofEach(String text) {
  List<String> words = text.split(" ");
  for (int i = 0; i < words.length; i++) {
    String word = words[i];
    if (word.isNotEmpty) {
      words[i] = word[0].toUpperCase() + word.substring(1);
    }
  }
  return words.join(" ");
}

bool urlValid(String imageUrl) {
  Uri? uri = Uri.tryParse(imageUrl);
  return uri != null &&
      uri.isAbsolute &&
      (uri.scheme == 'http' || uri.scheme == 'https');
}

bool isImageUrl(String imageUrl) {
  final imageExtensions = ['.jpg', '.jpeg', '.png'];
  final lowercaseUrl = imageUrl.toLowerCase();

  // Check if the URL ends with a known image extension
  if (imageExtensions.any((extension) => lowercaseUrl.endsWith(extension))) {
    return true;
  }

  // Alternatively, you can check the content type of the resource
  // using a package like http or dio
  // Example:
  // final response = await http.head(Uri.parse(url));
  // final contentType = response.headers['content-type'];
  // return contentType?.startsWith('image/') ?? false;

  return false;
}

bool isPdfUrl(String pdfUrl) {
  final pdfExtensions = ['.pdf'];
  final lowercaseUrl = pdfUrl.toLowerCase();
  if (pdfExtensions.any((extension) => lowercaseUrl.endsWith(extension))) {
    return true;
  } else {
    return false;
  }
}

bool searchString(String query, String string) {
  query = query.replaceAll(' ', '').toLowerCase();
  string = string.replaceAll(' ', '').toLowerCase();
  return string.contains(query);
}

Future<bool> checkImageAssetExist(String pathImage) async {
  try {
    await rootBundle.load(pathImage);
    return true;
  } catch (error) {
    return false;
  }
}

String formatDateTime(DateTime dateTime) {
  return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
      "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
}

String formatTime(DateTime dateTime) {
  return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
}

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

/// Parses a typed quantity ("2.5" or "2,5"). Null when blank, not above 0,
/// beyond 6 decimals, or a fraction where [wholeUnits] are required.
num? parseQty(String text, {bool wholeUnits = false}) {
  final value = num.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || value <= 0) return null;
  final qty = roundQty(value);
  if (qty != value) return null;
  if (wholeUnits && qty is! int) return null;
  return qty;
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

String formatPrice(dynamic value) {
  if (value == null) return "-";

  final number = num.tryParse(value.toString()) ?? 0;
  return NumberFormat.decimalPattern('id_ID').format(number);
}


Color getAccentColor(String code) {
  const  colors = [
    Color(0xFF124076), // Navy
    Color(0xFF7F9F80), // Olive
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF9800), // Orange
    Color(0xFF009688), // Teal
    Color(0xFFE91E63), // Pink
    Color(0xFF3F51B5), // Indigo
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF8BC34A), // Light Green
  ];

  return colors[code.hashCode.abs() % colors.length];
}

Color getReadableTextColor(Color bg) {
  return bg.computeLuminance() > 0.5
      ? Colors.black
      : Colors.white;
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
