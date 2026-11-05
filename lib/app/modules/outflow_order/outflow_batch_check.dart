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

/// What is left of batch [code] for [line], or null when it can't be drawn
/// from (not in stock for this item, or the lookup failed) — the reason is
/// already shown. Units already scanned on this line for the same batch are
/// subtracted, so the result is what the worker can still add.
Future<num?> batchLeftToScan(
  OutflowOrderProvider provider,
  Map<String, dynamic> line,
  String code, {
  required RxBool isLoading,
}) async {
  final itemId = line['item_id'];
  final itemName = line['name']?.toString() ?? 'this item';
  if (itemId is! int) {
    errorAlertBottom('Cannot check this batch: the line has no item id.', title: 'Batch Check');
    return null;
  }

  final stock = await ApiExecutor.run<Map<String, num>>(
    isLoading: isLoading,
    task: () => provider.getSerialStock(itemId),
  );
  if (stock == null) return null;

  final inStock = stock[code];
  if (inStock == null || inStock <= 0) {
    errorAlertBottom('"$code" is not in stock for $itemName.', title: 'Unknown Batch');
    return null;
  }

  final scanned = List<Map<String, dynamic>>.from(line['scanned'] ?? const []);
  final already = sumQty(scanned.where((e) => e['serial_number'] == code));
  final left = roundQty(inStock - already);
  if (left <= 0) {
    errorAlertBottom(
      'Batch "$code" has nothing left — its stock (qty ${formatQty(inStock)}) is already scanned on this line.',
      title: 'Batch Used Up',
    );
    return null;
  }
  return left;
}

/// True when [qty] fits in what is left of the batch ([left]); otherwise shows
/// why and returns false.
bool batchQtyFits(String code, num qty, num left) {
  if (roundQty(qty) <= left) return true;
  errorAlertBottom(
    'Batch "$code" has only ${formatQty(left)} left to take, but ${formatQty(qty)} was entered.',
    title: 'Not Enough in Batch',
  );
  return false;
}
