import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../alert.dart';
import '../styles/app_text_style.dart';
import '../functions.dart';

/// Quantity-entry dialogs shared by the outflow scan screens.
///
/// The `TextEditingController` is owned by an internal [StatefulWidget] and
/// disposed in its `dispose()` — i.e. only once the dialog has been fully
/// removed from the tree after its exit animation. Disposing the controller
/// straight after `await Get.dialog(...)` (which returns the moment
/// `closeRoute()` fires, before the reverse transition finishes) would leave the
/// still-mounted `TextField` referencing a disposed controller, throwing
/// "A TextEditingController was used after being disposed".

/// Prompts for a serial-tracked batch quantity (whole units). Returns the qty,
/// or `null` if cancelled.
Future<num?> showBatchQtyDialog() {
  return Get.dialog<num>(
    const _QtyDialog(
      title: 'Batch Quantity',
      label: 'Enter quantity for this batch',
      confirmText: 'OK',
      wholeUnits: true,
    ),
  );
}

/// Prompts for an item quantity — fractional (kg, metre) unless [wholeUnits].
/// Returns `{'qty': num}`, or `null` if cancelled.
Future<Map<String, dynamic>?> showOtherItemDialog({num? initialQty, bool wholeUnits = false}) async {
  final qty = await Get.dialog<num>(
    _QtyDialog(
      title: 'Enter item quantity',
      label: 'Quantity',
      confirmText: 'Save',
      initialText: initialQty == null ? '' : formatQty(initialQty),
      wholeUnits: wholeUnits,
    ),
  );
  if (qty == null) return null;
  return {'qty': qty};
}

/// Receive-order quantity dialog: quantity plus an optional expiration date
/// (shown when [manageExpired]). Returns `{'qty': num, 'expired_date': String}`
/// or `null` if cancelled. Used by both fill-by-PO and fill-by-supplier.
/// [wholeUnits] for serial-tracked lines (see `wholeUnitsOnly`).
Future<Map<String, dynamic>?> showReceiveItemQtyDialog({
  required Color accent,
  String? type,
  bool? manageExpired,
  bool wholeUnits = false,
  num? initialQty,
  String? initialExpired,
}) {
  return Get.dialog<Map<String, dynamic>>(
    _ReceiveItemQtyDialog(
      accent: accent,
      type: type,
      manageExpired: manageExpired,
      wholeUnits: wholeUnits,
      initialQty: initialQty,
      initialExpired: initialExpired,
    ),
  );
}

/// Receive-number entry dialog. Returns the trimmed number, or `null` if
/// cancelled. Used by both receive-order detail views.
Future<String?> showReceiveNumberDialog({String? initialValue}) {
  return Get.dialog<String>(
    _TextDialog(
      title: 'Receive Number',
      label: 'Enter receive number',
      icon: Icons.confirmation_number,
      fieldKey: const Key('receiveNumberField'),
      initialValue: initialValue ?? '',
    ),
  );
}

/// Why a delivery status is stepped back (required by the backend, ≤ 500 chars).
/// Returns the trimmed reason, or `null` if cancelled.
Future<String?> showUndoReasonDialog(String backTo) {
  return Get.dialog<String>(
    _TextDialog(
      title: 'Undo status',
      label: 'Why go back to $backTo?',
      icon: Icons.undo_rounded,
      fieldKey: const Key('deliveryUndoReasonField'),
      confirmText: 'Undo',
      maxLength: 500,
    ),
  );
}

/// Who received the goods — the backend requires it on the move to Delivered.
/// Returns the trimmed name, or `null` if cancelled.
Future<String?> showReceiverNameDialog() {
  return Get.dialog<String>(
    const _TextDialog(
      title: 'Received by',
      label: 'Name of the person who received the goods',
      icon: Icons.person_outline_rounded,
      fieldKey: Key('deliveryReceiverField'),
      confirmText: 'Mark Delivered',
    ),
  );
}

void _invalidQtyAlert({required bool wholeUnits, String typed = ''}) => errorAlertBottom(
      title: "Invalid Input",
      looksLikeThousands(typed) || (wholeUnits && ambiguousQty(typed) != null)
          ? "Type the number without a thousands separator (e.g. 1000, not ${typed.trim()})."
          : wholeUnits
              ? "Serial-tracked items count whole units — enter a whole number greater than 0."
              : "Please enter a quantity greater than 0 (up to 6 decimals).",
    );

/// The typed quantity, or null (the reason shown) — the dialog then stays open.
/// An [ambiguousQty] ("1.500": 1.5 or 1500?) is never guessed: a whole-unit
/// line refuses it (a decimal can't be meant there, and a silent 1500 would
/// make 1500 labels), any other line lets the worker pick the reading.
Future<num?> _readQty(String text, {required bool wholeUnits}) async {
  final readings = ambiguousQty(text);
  if (readings == null) {
    final qty = parseQty(text, wholeUnits: wholeUnits);
    if (qty == null) _invalidQtyAlert(wholeUnits: wholeUnits, typed: text);
    return qty;
  }
  if (wholeUnits) {
    _invalidQtyAlert(wholeUnits: true, typed: text);
    return null;
  }
  return Get.dialog<num>(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Which quantity?'),
      content: Text('"${text.trim()}" can be read two ways. Which one did you mean?'),
      actions: [
        TextButton(onPressed: () => closeRoute(), child: const Text('Cancel')),
        OutlinedButton(
          key: const Key('qtyReadingDecimal'),
          onPressed: () => closeRoute<num>(readings.decimal),
          child: Text(formatQty(readings.decimal)),
        ),
        ElevatedButton(
          key: const Key('qtyReadingThousands'),
          onPressed: () => closeRoute<num>(readings.thousands),
          child: Text('${readings.thousands}'),
        ),
      ],
    ),
  );
}

class _QtyDialog extends StatefulWidget {
  const _QtyDialog({
    required this.title,
    required this.label,
    required this.confirmText,
    this.initialText = '',
    this.wholeUnits = false,
  });

  final String title;
  final String label;
  final String confirmText;
  final String initialText;
  final bool wholeUnits;

  @override
  State<_QtyDialog> createState() => _QtyDialogState();
}

class _QtyDialogState extends State<_QtyDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = await _readQty(_controller.text, wholeUnits: widget.wholeUnits);
    if (qty == null || !mounted) return;
    closeRoute(qty);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title),
      content: TextField(
        key: const Key('qtyDialogField'),
        controller: _controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !widget.wholeUnits),
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.numbers),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => closeRoute(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}

class _ReceiveItemQtyDialog extends StatefulWidget {
  const _ReceiveItemQtyDialog({
    required this.accent,
    required this.manageExpired,
    required this.wholeUnits,
    this.type,
    this.initialQty,
    this.initialExpired,
  });

  final Color accent;
  final bool? manageExpired;
  final bool wholeUnits;
  final String? type;
  final num? initialQty;
  final String? initialExpired;

  @override
  State<_ReceiveItemQtyDialog> createState() => _ReceiveItemQtyDialogState();
}

class _ReceiveItemQtyDialogState extends State<_ReceiveItemQtyDialog> {
  late final TextEditingController _qtyController =
      TextEditingController(text: widget.initialQty == null ? '' : formatQty(widget.initialQty!));
  late final TextEditingController _expController =
      TextEditingController(text: widget.initialExpired ?? '');

  @override
  void dispose() {
    _qtyController.dispose();
    _expController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: widget.accent,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _expController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _save() async {
    final qty = await _readQty(_qtyController.text, wholeUnits: widget.wholeUnits);
    if (qty == null || !mounted) return;
    if (widget.manageExpired == true && _expController.text.isEmpty) {
      errorAlertBottom(
        title: "Missing Expiration Date",
        "Please select an expiration date.",
      );
      return;
    }
    closeRoute({'qty': qty, 'expired_date': _expController.text});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.type == 'BATCH' ? 'Batch Quantity' : 'Enter item quantity',
        style: AppTextStyle.plain(weight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('qtyDialogField'),
              controller: _qtyController,
              keyboardType: TextInputType.numberWithOptions(decimal: !widget.wholeUnits),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.manageExpired == true) ...[
              GestureDetector(
                onTap: _pickExpiry,
                child: AbsorbPointer(
                  child: TextField(
                    key: const Key('qtyDialogExpiryField'),
                    controller: _expController,
                    decoration: const InputDecoration(
                      labelText: 'Expiration Date',
                      prefixIcon: Icon(Icons.date_range),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => closeRoute(), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
          onPressed: _save,
          child: Text('Save', style: AppTextStyle.plain(color: Colors.white)),
        ),
      ],
    );
  }
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    required this.icon,
    required this.fieldKey,
    this.initialValue = '',
    this.confirmText = 'Save',
    this.maxLength = 255,
  });

  final String title;
  final String label;
  final IconData icon;
  final Key fieldKey;
  final String initialValue;
  final String confirmText;

  /// The backend's limit for this field (the counter stops the typing there).
  final int maxLength;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => closeRoute(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => closeRoute(_controller.text.trim()),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
