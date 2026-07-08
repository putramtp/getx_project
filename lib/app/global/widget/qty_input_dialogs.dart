import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../alert.dart';
import '../styles/app_text_style.dart';

/// Quantity-entry dialogs shared by the outflow scan screens.
///
/// The `TextEditingController` is owned by an internal [StatefulWidget] and
/// disposed in its `dispose()` — i.e. only once the dialog has been fully
/// removed from the tree after its exit animation. Disposing the controller
/// straight after `await Get.dialog(...)` (which returns the moment
/// `Get.back()` fires, before the reverse transition finishes) would leave the
/// still-mounted `TextField` referencing a disposed controller, throwing
/// "A TextEditingController was used after being disposed".

/// Prompts for a batch quantity. Returns the parsed int, or `null` if cancelled
/// or left blank/invalid.
Future<int?> showBatchQtyDialog() {
  return Get.dialog<int>(
    _QtyDialog(
      title: 'Batch Quantity',
      label: 'Enter quantity for this batch',
      confirmText: 'OK',
      onConfirm: (text) => int.tryParse(text),
    ),
  );
}

/// Prompts for an item quantity. Returns `{'qty': int}`, or `null` if cancelled.
/// A blank/invalid entry defaults to a qty of 1.
Future<Map<String, dynamic>?> showOtherItemDialog({int? initialQty}) async {
  final qty = await Get.dialog<int>(
    _QtyDialog(
      title: 'Enter item quantity',
      label: 'Quantity',
      confirmText: 'Save',
      initialText: initialQty?.toString() ?? '',
      onConfirm: (text) => int.tryParse(text) ?? 1,
    ),
  );
  if (qty == null) return null;
  return {'qty': qty};
}

/// Receive-order quantity dialog: quantity plus an optional expiration date
/// (shown when [manageExpired]). Returns `{'qty': int, 'expired_date': String}`
/// or `null` if cancelled. Used by both fill-by-PO and fill-by-supplier.
Future<Map<String, dynamic>?> showReceiveItemQtyDialog({
  required Color accent,
  String? type,
  bool? manageExpired,
  int? initialQty,
  String? initialExpired,
}) {
  return Get.dialog<Map<String, dynamic>>(
    _ReceiveItemQtyDialog(
      accent: accent,
      type: type,
      manageExpired: manageExpired,
      initialQty: initialQty,
      initialExpired: initialExpired,
    ),
  );
}

/// Receive-number entry dialog. Returns the trimmed number, or `null` if
/// cancelled. Used by both receive-order detail views.
Future<String?> showReceiveNumberDialog({String? initialValue}) {
  return Get.dialog<String>(
    _ReceiveNumberDialog(initialValue: initialValue ?? ''),
  );
}

class _QtyDialog extends StatefulWidget {
  const _QtyDialog({
    required this.title,
    required this.label,
    required this.confirmText,
    required this.onConfirm,
    this.initialText = '',
  });

  final String title;
  final String label;
  final String confirmText;
  final String initialText;

  /// Maps the raw field text to the value returned via `Get.back(result: ...)`.
  final int? Function(String text) onConfirm;

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.numbers),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Get.back(result: widget.onConfirm(_controller.text)),
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
    this.type,
    this.initialQty,
    this.initialExpired,
  });

  final Color accent;
  final bool? manageExpired;
  final String? type;
  final int? initialQty;
  final String? initialExpired;

  @override
  State<_ReceiveItemQtyDialog> createState() => _ReceiveItemQtyDialogState();
}

class _ReceiveItemQtyDialogState extends State<_ReceiveItemQtyDialog> {
  late final TextEditingController _qtyController =
      TextEditingController(text: widget.initialQty?.toString() ?? '');
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

  void _save() {
    final qty = int.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) {
      errorAlertBottom(
        title: "Invalid Input",
        "Please enter a valid quantity greater than 0.",
      );
      return;
    }
    if (widget.manageExpired == true && _expController.text.isEmpty) {
      errorAlertBottom(
        title: "Missing Expiration Date",
        "Please select an expiration date.",
      );
      return;
    }
    Get.back(result: {'qty': qty, 'expired_date': _expController.text});
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
              controller: _qtyController,
              keyboardType: TextInputType.number,
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
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
          onPressed: _save,
          child: Text('Save', style: AppTextStyle.plain(color: Colors.white)),
        ),
      ],
    );
  }
}

class _ReceiveNumberDialog extends StatefulWidget {
  const _ReceiveNumberDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_ReceiveNumberDialog> createState() => _ReceiveNumberDialogState();
}

class _ReceiveNumberDialogState extends State<_ReceiveNumberDialog> {
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
      title: const Text('Receive Number'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Enter receive number',
          prefixIcon: Icon(Icons.confirmation_number),
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Get.back(result: _controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
