import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../../data/models/delivery_model.dart';
import '../../../data/models/delivery_status_model.dart';
import '../../../data/providers/delivery_provider.dart';
import '../../../global/alert.dart';
import '../../../global/submit_key.dart';
import '../../../services/draft_service.dart';
import '../../../services/network_service.dart';
import '../../../helpers/api_excecutor.dart';

class DeliveryDetailController extends GetxController {
  final DeliveryProvider provider = Get.find<DeliveryProvider>();

  final delivery = Rxn<DeliveryModel>();
  final statuses = <DeliveryStatusModel>[].obs;

  var isLoading = false.obs;
  var isUpdating = false.obs;
  var isUploading = false.obs;
  /// True while the camera / gallery picker is open (not observed: only a guard).
  bool isPickingProof = false;
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
    // Two calls below: offline, one notice instead of one per call.
    if (!await Get.find<NetworkService>().ensureOnline()) return;
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
  /// Returns true only when the server accepted it; false when the required
  /// details are missing ([hasRequiredDetails] — the caller opens the edit
  /// form) or the save failed (its error is already shown).
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
    // True only when the server accepted the change.
    return submitUpdate(
      statusId: statusId,
      estimateAt: d.estimateAt!,
      estimateTime: d.estimateTime,
      address: d.address,
      description: d.description,
      receiverName: receiverName,
    );
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
    if (updated == null) {
      // The update may have been applied with its answer lost: show what the
      // server has, or the next try is refused against a stale screen.
      loadDetail();
      return false;
    }

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
      task: () => provider.undoStatus(d.id, reason.trim(), expectedStatusId: d.statusId),
    );
    if (updated == null) {
      loadDetail(); // as in submitUpdate: the screen must follow the server
      return false;
    }

    delivery.value = updated;
    successAlertBottom("Delivery ${updated.code} is back to ${updated.statusLabel}.");
    return true;
  }

  /// Attaches a photo / signed delivery note, then reloads the detail so the
  /// new file shows in the proof list.
  Future<void> uploadProof(List<int> bytes, String filename) async {
    final d = delivery.value;
    if (d == null) return;
    // One key per pending upload of this delivery (kept across a failed try).
    final key = SubmitKey(Get.find<DraftService>(), 'delivery_proof_${d.id}');
    final res = await ApiExecutor.run(
      isLoading: isUploading,
      task: () => key.send((k) => provider.uploadProof(d.id, bytes, filename, idempotencyKey: k)),
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
