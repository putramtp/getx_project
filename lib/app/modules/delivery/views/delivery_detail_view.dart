import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../data/models/delivery_model.dart';
import '../../../data/models/delivery_status_model.dart';
import '../../../global/accent.dart';
import '../../../global/alert.dart';
import '../../../global/widget/accent_header_card.dart';
import '../../../global/widget/accent_pill.dart';
import '../../../global/widget/app_header.dart';
import '../../../global/functions.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/qty_input_dialogs.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../controllers/delivery_detail_controller.dart';
import 'delivery_proof_card.dart';
import 'delivery_status_panel.dart';

class DeliveryDetailView extends GetView<DeliveryDetailController> {
  const DeliveryDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: obxHeader(() {
        final d = controller.delivery.value;
        return appHeader('Delivery Detail', accent: AppAccent.steel, icon: Icons.route_rounded, subtitle: d == null ? null : '${d.code} · ${d.statusLabel}');
      }),
      body: SafeArea(
        child: Obx(() {
          final d = controller.delivery.value;
          if (d == null) {
            return controller.isLoading.value
                ? skeletonLineList(size, accent: steelBlue)
                : textNoData(size, message: "Delivery not found.");
          }
          return skeletonize(
            loading: controller.isLoading.value,
            child: SingleChildScrollView(
            padding: EdgeInsets.all(size * 1.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(size, d),
                SizedBox(height: size * 1.6),
                _infoCard(size, d),
                SizedBox(height: size * 1.6),
                _statusPanel(size, d),
                if (controller.isLocked) ...[
                  SizedBox(height: size * 1.6),
                  deliveryProofCard(
                    size,
                    proofs: d.proofs,
                    uploading: controller.isUploading.value,
                    onCamera: () => _pickProof(ImageSource.camera),
                    onGallery: () => _pickProof(ImageSource.gallery),
                    onOpen: _openProof,
                  ),
                ],
              ],
            ),
          ),
          );
        }),
      ),
    );
  }

  DeliveryStatusModel _currentStatus(DeliveryModel d) =>
      controller.statuses.firstWhereOrNull((s) => s.id == d.statusId) ??
      DeliveryStatusModel(id: d.statusId, name: d.statusName, label: d.statusLabel, color: '');

  Widget _header(double size, DeliveryModel d) {
    return accentHeaderCard(
      size: size,
      accent: AppAccent.steel,
      icon: Icons.route_rounded,
      label: 'Delivery',
      title: '#${d.code}',
      badge: statusPill(size, d.statusLabel, deliveryStatusColor(_currentStatus(d))),
      stats: [
        HeaderStat('ETA', _estimateText(d)),
        HeaderStat('Customer', d.customer),
      ],
    );
  }

  /// One "Mark `<status>`" per status it may move to next, plus "Edit details"
  /// (hidden once delivered). Cancelling asks for confirmation first, Delivered
  /// asks who received the goods; a quick change missing ETA/address opens the
  /// edit form instead.
  Widget _statusPanel(double size, DeliveryModel d) {
    return deliveryStatusPanel(
      size,
      current: _currentStatus(d),
      others: controller.nextStatuses,
      canEdit: !controller.isLocked,
      undoTo: d.undoAvailable ? d.undoToLabel : null,
      onUndo: () async {
        if (controller.isUpdating.value || d.undoToLabel == null) return;
        final reason = await showUndoReasonDialog(d.undoToLabel!);
        if (reason != null) await controller.undoStatus(reason);
      },
      onEdit: () => _openEditSheet(),
      onMark: (s) async {
        if (controller.isUpdating.value) return;
        if (_isFinalStatus(s) && await _confirmFinal(s) != true) return;
        String? receiver;
        if (controller.isDeliveredStatus(s.id)) {
          receiver = await showReceiverNameDialog();
          if (receiver == null) return;
        }
        final ok = await controller.quickSetStatus(s.id, receiverName: receiver);
        if (!ok) _openEditSheet(presetStatusId: s.id);
      },
    );
  }

  /// Picks a photo (resized: the backend caps a file at 20 MB) and uploads it.
  Future<void> _pickProof(ImageSource source) async {
    if (controller.isUploading.value) return;
    final file = await ImagePicker().pickImage(source: source, maxWidth: 2000, imageQuality: 85);
    if (file == null) return;
    await controller.uploadProof(await file.readAsBytes(), file.name);
  }

  /// A photo opens in an in-app preview; other files (a PDF note uploaded on
  /// the web) are opened there.
  Future<void> _openProof(DeliveryProof proof) async {
    if (!proof.isImage) {
      infoAlertBottom("Open ${proof.title} on the web — the app previews photos only.", title: "Not a photo");
      return;
    }
    final bytes = await controller.fetchProof(proof);
    if (bytes != null) await showProofPreview(proof.title, bytes);
  }

  /// Cancelled and Failed end the delivery (only a manager can undo them), so
  /// they ask first; Delivered asks for the receiver instead.
  bool _isFinalStatus(DeliveryStatusModel s) {
    final name = s.name.toLowerCase();
    return name.contains('cancel') || name.contains('fail');
  }

  Future<bool?> _confirmFinal(DeliveryStatusModel s) {
    final cancelling = s.name.toLowerCase().contains('cancel');
    return Get.dialog<bool>(
      AlertDialog(
        title: Text("Mark ${s.label}?"),
        content: Text(cancelling
            ? "This delivery will be marked as cancelled."
            : "This delivery will be marked as failed / returned. Only a manager can undo it."),
        actions: [
          TextButton(onPressed: () => closeRoute(false), child: const Text("Back")),
          TextButton(onPressed: () => closeRoute(true), child: Text("Mark ${s.label}")),
        ],
      ),
    );
  }

  Widget _infoCard(double size, DeliveryModel d) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size * 1.6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(size, Icons.person_outline_rounded, "Customer", d.customer),
          if (d.outflowOrderCode != null)
            _infoRow(size, Icons.receipt_long_rounded, "Outflow Order",
                d.outflowOrderCode!),
          _infoRow(size, Icons.event_outlined, "Estimated",
              _estimateText(d)),
          _infoRow(size, Icons.place_outlined, "Address",
              d.address.isEmpty ? "—" : d.address),
          _infoRow(size, Icons.notes_rounded, "Notes",
              (d.description == null || d.description!.isEmpty) ? "—" : d.description!),
          if (d.receiverName != null && d.receiverName!.isNotEmpty)
            _infoRow(size, Icons.how_to_reg_rounded, "Received by", d.receiverName!),
          if (d.deliveredAt != null)
            _infoRow(size, Icons.task_alt_rounded, "Delivered at", d.deliveredAt!),
          _infoRow(size, Icons.person_pin_rounded, "Updated by", d.updatedName),
        ],
      ),
    );
  }

  String _estimateText(DeliveryModel d) {
    if (d.estimateAt == null || d.estimateAt!.isEmpty) return "No ETA set";
    final time = (d.estimateTime != null && d.estimateTime!.isNotEmpty)
        ? " ${d.estimateTime}"
        : "";
    return "${d.estimateAt}$time";
  }

  Widget _infoRow(double size, IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size * 0.8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: size * 2, color: Colors.grey.shade500),
          SizedBox(width: size * 1.2),
          SizedBox(
            width: size * 11,
            child: Text(label,
                style: AppTextStyle.small(size, color: Colors.grey.shade600)
                    .copyWith(fontSize: size * 1.3)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyle.body(size).copyWith(fontSize: size * 1.4)),
          ),
        ],
      ),
    );
  }

  /// Edit form (status / ETA date+time / address / notes). [presetStatusId]
  /// pre-selects a status — used when a quick action needed missing details.
  void _openEditSheet({int? presetStatusId}) {
    final d = controller.delivery.value;
    if (d == null) return;
    final size = SizeConfig.defaultSize;

    final addressCtrl = TextEditingController(text: d.address);
    final descCtrl = TextEditingController(text: d.description ?? '');
    final receiverCtrl = TextEditingController();
    // Only the current status and the ones it may move to are offered.
    final choices = [
      ...controller.statuses.where((s) => s.id == d.statusId),
      ...controller.nextStatuses,
    ];
    int statusId = presetStatusId ?? d.statusId;
    DateTime? date = DateTime.tryParse(d.estimateAt ?? '');
    TimeOfDay? time = _parseTime(d.estimateTime);

    Get.bottomSheet(
      StatefulBuilder(builder: (context, setSheet) {
        return Container(
          padding: EdgeInsets.fromLTRB(size * 2, size * 2, size * 2,
              MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom + size * 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(size * 2)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: size * 6,
                    height: size * 0.6,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(size)),
                  ),
                ),
                SizedBox(height: size * 1.6),
                Text("Edit Delivery",
                    style: AppTextStyle.h5(size)),
                SizedBox(height: size * 1.6),
                Text("Status",
                    style: AppTextStyle.small(size, color: Colors.grey.shade600)),
                SizedBox(height: size * 0.6),
                DropdownButtonFormField<int>(
                  initialValue: choices.any((s) => s.id == statusId)
                      ? statusId
                      : null,
                  isExpanded: true,
                  decoration: _fieldDecoration(size),
                  items: choices
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (v) => setSheet(() => statusId = v ?? statusId),
                ),
                if (statusId != d.statusId && controller.isDeliveredStatus(statusId)) ...[
                  SizedBox(height: size * 1.4),
                  Text("Received by",
                      style: AppTextStyle.small(size, color: Colors.grey.shade600)),
                  SizedBox(height: size * 0.6),
                  TextField(
                    key: const Key('deliveryEditReceiverField'),
                    controller: receiverCtrl,
                    decoration: _fieldDecoration(size, hint: "Name of the person who received the goods"),
                  ),
                ],
                SizedBox(height: size * 1.4),
                Row(
                  children: [
                    Expanded(
                      child: _pickerField(
                        size,
                        label: "ETA date",
                        value: date != null
                            ? DateFormat('yyyy-MM-dd').format(date!)
                            : "Select",
                        icon: Icons.event_outlined,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setSheet(() => date = picked);
                        },
                      ),
                    ),
                    SizedBox(width: size * 1.2),
                    Expanded(
                      child: _pickerField(
                        size,
                        label: "ETA time",
                        value: time != null ? time!.format(context) : "Select",
                        icon: Icons.schedule_rounded,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: time ?? TimeOfDay.now(),
                          );
                          if (picked != null) setSheet(() => time = picked);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size * 1.4),
                Text("Address",
                    style: AppTextStyle.small(size, color: Colors.grey.shade600)),
                SizedBox(height: size * 0.6),
                TextField(
                  key: const Key('deliveryEditAddressField'),
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: _fieldDecoration(size, hint: "Delivery address"),
                ),
                SizedBox(height: size * 1.4),
                Text("Notes",
                    style: AppTextStyle.small(size, color: Colors.grey.shade600)),
                SizedBox(height: size * 0.6),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: _fieldDecoration(size, hint: "Optional notes"),
                ),
                SizedBox(height: size * 2),
                SizedBox(
                  width: double.infinity,
                  height: size * 4.4,
                  child: Obx(() => ElevatedButton(
                        onPressed: controller.isUpdating.value
                            ? null
                            : () async {
                                if (date == null) {
                                  return;
                                }
                                final saved = await controller.submitUpdate(
                                  statusId: statusId,
                                  estimateAt:
                                      DateFormat('yyyy-MM-dd').format(date!),
                                  estimateTime: time != null
                                      ? _fmtTime(time!)
                                      : null,
                                  address: addressCtrl.text,
                                  description: descCtrl.text,
                                  receiverName: receiverCtrl.text,
                                );
                                if (saved) closeRoute();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: steelBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(size * 1.2)),
                        ),
                        child: controller.isUpdating.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 3, color: Colors.white))
                            : Text("Save changes",
                                style: AppTextStyle.bodyBold(size,
                                    color: Colors.white)),
                      )),
                ),
              ],
            ),
          ),
        );
      }),
      isScrollControlled: true,
    ).whenComplete(() {
      addressCtrl.dispose();
      descCtrl.dispose();
      receiverCtrl.dispose();
    });
  }

  InputDecoration _fieldDecoration(double size, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: EdgeInsets.symmetric(horizontal: size * 1.2, vertical: size * 1.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(size * 1.2),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _pickerField(double size,
      {required String label,
      required String value,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(size * 1.2),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: size * 1.2, vertical: size * 1.3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(size * 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, size: size * 1.8, color: Colors.grey.shade600),
            SizedBox(width: size * 0.8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          AppTextStyle.small(size, color: Colors.grey.shade500)
                              .copyWith(fontSize: size * 1.1)),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.body(size).copyWith(fontSize: size * 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmtTime(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
}
