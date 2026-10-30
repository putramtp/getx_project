import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../../data/models/delivery_model.dart';
import '../../../data/models/delivery_status_model.dart';
import '../../../data/providers/delivery_provider.dart';
import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';

class DeliveryDetailController extends GetxController {
  final DeliveryProvider provider = Get.find<DeliveryProvider>();

  final delivery = Rxn<DeliveryModel>();
  final statuses = <DeliveryStatusModel>[].obs;

  var isLoading = false.obs;
  var isUpdating = false.obs;
  var isUploading = false.obs;
  var isOpeningProof = false.obs;

  late final DeliveryModel _initial;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is DeliveryModel) {
      _initial = args;
      delivery.value = args;
      loadDetail();
    } else {
      errorAlert("⚠️ Invalid or missing arguments in delivery: $args");
    }
  }

  Future<void> loadDetail() async {
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getDeliveryDetail(_initial.id),
    );
    if (data != null) delivery.value = data;

    final list = await ApiExecutor.run(
      isLoading: false.obs,
      task: () => provider.getDeliveryStatuses(),
    );
    if (list != null) statuses.assignAll(list);
  }

  Color colorForStatus(int statusId) {
    final match = statuses.firstWhereOrNull((s) => s.id == statusId);
    if (match == null || match.color.isEmpty) return Colors.blueGrey;
    return HexColor(match.color);
  }

  /// Whether [statusId] is the Delivered status (the move that needs a receiver).
  bool isDeliveredStatus(int statusId) =>
      statuses.firstWhereOrNull((s) => s.id == statusId)?.name.toLowerCase() == 'delivered';

  /// Where the status may move next. The backend only allows forward moves
  /// (Pending → Shipped/Delivered/Cancelled, Shipped → Delivered/Failed) and
  /// sends them as `next_statuses`; before the detail loads, every other status.
  List<DeliveryStatusModel> get nextStatuses {
    final d = delivery.value;
    if (d == null) return const [];
    final next = d.nextStatusIds;
    if (next == null) return statuses.where((s) => s.id != d.statusId).toList();
    return statuses.where((s) => next.contains(s.id)).toList();
  }

  /// A delivered delivery can no longer be edited (a manager can undo it on the web).
  bool get isLocked {
    final d = delivery.value;
    return d != null && isDeliveredStatus(d.statusId);
  }

  /// True once the delivery has the data the backend requires on every update
  /// (a non-empty address and an ETA) — quick status changes need these.
  bool get hasRequiredDetails {
    final d = delivery.value;
    if (d == null) return false;
    return d.address.trim().isNotEmpty &&
        (d.estimateAt != null && d.estimateAt!.isNotEmpty);
  }

  /// One-tap status change reusing the delivery's current ETA/address/notes.
  /// Returns false when required details are missing, so the caller can open
  /// the edit form instead.
  Future<bool> quickSetStatus(int statusId, {String? receiverName}) async {
    final d = delivery.value;
    if (d == null) return false;
    if (!hasRequiredDetails) {
      warningAlertBottom(
        "Please set the ETA and address first.",
        title: "Details needed",
      );
      return false;
    }
    await submitUpdate(
      statusId: statusId,
      estimateAt: d.estimateAt!,
      estimateTime: d.estimateTime,
      address: d.address,
      description: d.description,
      receiverName: receiverName,
    );
    return true;
  }

  /// Full update — used by both the quick status buttons and the edit form.
  /// Returns true only when the server accepted it (the edit sheet stays open
  /// otherwise, so the user's input isn't lost).
  Future<bool> submitUpdate({
    required int statusId,
    required String estimateAt,
    String? estimateTime,
    required String address,
    String? description,
    String? receiverName,
  }) async {
    final d = delivery.value;
    if (d == null) return false;

    if (address.trim().isEmpty) {
      warningAlertBottom("A delivery address is required.", title: "Missing address");
      return false;
    }

    final receiver = receiverName?.trim() ?? '';
    if (statusId != d.statusId && isDeliveredStatus(statusId) && receiver.isEmpty) {
      warningAlertBottom("Enter who received the goods.", title: "Receiver needed");
      return false;
    }

    final payload = {
      "status_id": statusId,
      "estimate_at": estimateAt,
      if (estimateTime != null && estimateTime.isNotEmpty) "estimate_time": estimateTime,
      "address": address.trim(),
      "description": description?.trim() ?? "",
      if (receiver.isNotEmpty) "receiver_name": receiver,
    };

    final updated = await ApiExecutor.run(
      isLoading: isUpdating,
      task: () => provider.updateDelivery(d.id, payload),
    );
    if (updated == null) return false;

    delivery.value = updated;
    successAlertBottom("Delivery ${updated.code} updated.");
    return true;
  }

  /// Steps a wrong status back one step, with the [reason] the backend requires.
  Future<bool> undoStatus(String reason) async {
    final d = delivery.value;
    if (d == null) return false;
    if (reason.trim().isEmpty) {
      warningAlertBottom("Enter why the status is being undone.", title: "Reason needed");
      return false;
    }
    final updated = await ApiExecutor.run(
      isLoading: isUpdating,
      task: () => provider.undoStatus(d.id, reason.trim()),
    );
    if (updated == null) return false;

    delivery.value = updated;
    successAlertBottom("Delivery ${updated.code} is back to ${updated.statusLabel}.");
    return true;
  }

  /// Attaches a photo / signed delivery note, then reloads the detail so the
  /// new file shows in the proof list.
  Future<void> uploadProof(List<int> bytes, String filename) async {
    final d = delivery.value;
    if (d == null) return;
    final res = await ApiExecutor.run(
      isLoading: isUploading,
      task: () => provider.uploadProof(d.id, bytes, filename),
    );
    if (res == null) return;
    successAlertBottom("Proof of delivery uploaded.");
    await loadDetail();
  }

  /// The proof file's bytes for the in-app preview; null on error (shown by ApiExecutor).
  Future<Uint8List?> fetchProof(DeliveryProof proof) async {
    final d = delivery.value;
    if (d == null) return null;
    return ApiExecutor.run(
      isLoading: isOpeningProof,
      task: () => provider.getProofBytes(d.id, proof.id),
    );
  }
}
