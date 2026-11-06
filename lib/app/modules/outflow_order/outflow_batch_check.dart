import 'package:get/get.dart';

import '../../data/providers/outflow_order_provider.dart';
import '../../global/alert.dart';
import '../../global/functions.dart';
import '../../helpers/api_excecutor.dart';

/// Early check of a scanned BATCH label on the outflow scan screens (By
/// Request, By Customer, By Work Order), so a label that isn't in stock — or a
/// draw larger than what is left of the batch — is caught at the scan instead
/// of failing the whole submit. The backend still enforces both
/// (`attachWorkerSelectedOutflowSerials`); this only moves the message earlier.
///
/// The decisions are pure functions ([checkBatchLeft], [checkBatchQty],
/// [checkRename]) so they can be unit tested; the `Future` wrappers fetch the
/// stock and show the refusal.

/// A refusal the scan screen shows as a snackbar.
class BatchRefusal {
  final String title;
  final String message;

  /// Warning (a duplicate) rather than an error.
  final bool isWarning;

  const BatchRefusal(this.title, this.message, {this.isWarning = false});

  void show() => isWarning ? warningAlertBottom(message, title: title) : errorAlertBottom(message, title: title);
}

/// Result of [checkBatchLeft]: what can still be drawn, or why nothing can.
class BatchLeft {
  final num? left;
  final BatchRefusal? refusal;
  const BatchLeft.ok(num this.left) : refusal = null;
  const BatchLeft.refused(BatchRefusal this.refusal) : left = null;
}

/// Units of batch [code] already scanned for [itemId] across [lines] — every
/// line of the screen, since two lines of one item (By Customer lists a
/// customer's requests together) draw on the same batch.
num scannedFromBatch(Iterable<Map> lines, Object? itemId, String code) => sumQty([
      for (final line in lines)
        if (line['item_id'] == itemId)
          ...List<Map>.from(line['scanned'] ?? const []).where((e) => e['serial_number'] == code),
    ]);

/// What is left of batch [code] for [line] given the label stock [stock]
/// (code → units left, from [OutflowOrderProvider.getSerialStock]), less what
/// [lines] already scanned from it.
BatchLeft checkBatchLeft(Map<String, num> stock, Map line, String code, {Iterable<Map> lines = const []}) {
  final itemName = line['name']?.toString() ?? 'this item';
  final inStock = stock[code];
  if (inStock == null || inStock <= 0) {
    return BatchLeft.refused(BatchRefusal('Unknown Batch', '"$code" is not in stock for $itemName.'));
  }
  final already = scannedFromBatch(lines.isEmpty ? [line] : lines, line['item_id'], code);
  final left = roundQty(inStock - already);
  if (left <= 0) {
    return BatchLeft.refused(BatchRefusal(
      'Batch Used Up',
      'Batch "$code" has nothing left — its stock (qty ${formatQty(inStock)}) is already scanned.',
    ));
  }
  return BatchLeft.ok(left);
}

/// Null when [qty] fits in what is left of the batch ([left]), else why not.
BatchRefusal? checkBatchQty(String code, num qty, num left) => roundQty(qty) <= left
    ? null
    : BatchRefusal(
        'Not Enough in Batch',
        'Batch "$code" has only ${formatQty(left)} left to take, but ${formatQty(qty)} was entered.',
      );

/// Whether "Edit Code" may turn row [oldCode] of [line] into [newCode] without
/// a stock lookup: null when it may (a BATCH line still needs
/// [checkBatchLeft] — see [needsBatchCheck]), a refusal for a duplicate, and
/// [renameIgnored] when there is nothing to rename. [lines] are all lines of
/// the screen, so a code scanned on another line of the same item counts too.
BatchRefusal? checkRename(Map line, String oldCode, String newCode, {Iterable<Map> lines = const []}) {
  final scanned = List<Map>.from(line['scanned'] ?? const []);
  if (newCode.isEmpty || newCode == oldCode || !scanned.any((e) => e['serial_number'] == oldCode)) {
    return renameIgnored;
  }
  if (scanned.any((e) => e['serial_number'] == newCode) || scannedOnOtherLine(lines, line, newCode)) {
    return BatchRefusal('Duplicate Code', '"$newCode" is already scanned for this item.', isWarning: true);
  }
  return null;
}

/// Whether [code] is already scanned on another line of [line]'s item in
/// [lines] (By Customer can list two requests of one item). A BATCH label may
/// feed several lines — [checkBatchLeft] sums those draws — but a unit label
/// can leave only once, and the backend refuses the whole submit otherwise.
bool scannedOnOtherLine(Iterable<Map> lines, Map line, String code) {
  if (line['serialNumberType'] == 'BATCH') return false;
  return lines.any((other) =>
      !identical(other, line) &&
      other['item_id'] == line['item_id'] &&
      List<Map>.from(other['scanned'] ?? const []).any((e) => e['serial_number'] == code));
}

/// [checkRename]'s answer when there is nothing to rename (no message).
const renameIgnored = BatchRefusal('', '');

/// Whether a scan on [line] is checked against the batch stock.
bool needsBatchCheck(Map line) => line['manage_sn'] == true && line['serialNumberType'] == 'BATCH';

/// Fetches [line]'s label stock and runs [checkBatchLeft]; null when nothing
/// can be drawn (the reason, or the failed lookup, is already shown).
Future<num?> batchLeftToScan(
  OutflowOrderProvider provider,
  Map<String, dynamic> line,
  String code, {
  required RxBool isLoading,
  Iterable<Map> lines = const [],
}) async {
  final itemId = line['item_id'];
  if (itemId is! int) {
    errorAlertBottom('Cannot check this batch: the line has no item id.', title: 'Batch Check');
    return null;
  }

  final stock = await ApiExecutor.run<Map<String, num>>(
    isLoading: isLoading,
    task: () => provider.getSerialStock(itemId),
  );
  if (stock == null) return null;

  final result = checkBatchLeft(stock, line, code, lines: lines);
  result.refusal?.show();
  return result.left;
}

/// True when [qty] fits in what is left of the batch ([left]); otherwise shows
/// why and returns false.
bool batchQtyFits(String code, num qty, num left) {
  final refusal = checkBatchQty(code, qty, left);
  refusal?.show();
  return refusal == null;
}

/// Whether a scanned row may change its code from [oldCode] to [newCode]
/// ("Edit Code" on the scan screen). A rename is a new scan of that label, so it
/// passes the same checks: no duplicate on [line] ([checkRename]), and on a
/// BATCH line the label must be in stock with room for the row's qty. The
/// reason is shown when it may not.
Future<bool> canRenameScan(
  OutflowOrderProvider provider,
  Map<String, dynamic> line,
  String oldCode,
  String newCode, {
  required RxBool isLoading,
  Iterable<Map> lines = const [],
}) async {
  final refusal = checkRename(line, oldCode, newCode, lines: lines);
  if (refusal != null) {
    if (!identical(refusal, renameIgnored)) refusal.show();
    return false;
  }
  if (!needsBatchCheck(line)) return true;
  // The scan FAB is disabled while a check runs; the row's "Edit Code" is not.
  if (isLoading.value) {
    infoAlertBottom('The previous scan is still being checked.', title: 'Please wait');
    return false;
  }

  final row = List<Map>.from(line['scanned'] ?? const []).firstWhere((e) => e['serial_number'] == oldCode);
  final left = await batchLeftToScan(provider, line, newCode, isLoading: isLoading, lines: lines);
  if (left == null) return false;
  return batchQtyFits(newCode, safeToNum(row['qty']), left);
}
