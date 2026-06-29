import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../../data/models/delivery_model.dart';
import '../../../data/models/delivery_status_model.dart';
import '../../../data/providers/delivery_provider.dart';
import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../services/auth_service.dart';

class DeliveryDetailController extends GetxController {
  final DeliveryProvider provider = Get.find<DeliveryProvider>();
  final AuthService _auth = Get.find<AuthService>();

  final delivery = Rxn<DeliveryModel>();
  final statuses = <DeliveryStatusModel>[].obs;

  var isLoading = false.obs;
  var isUpdating = false.obs;

  late final DeliveryModel _initial;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is DeliveryModel) {
      _initial = args;
      delivery.value = args;
      loadDetail();
      _ensureUserId();
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

  /// Resolve and cache the current user's id quietly (used as `updated_by`).
  Future<int?> _ensureUserId() async {
    if (_auth.userId.value != null) return _auth.userId.value;
    final id = await ApiExecutor.run(
      isLoading: false.obs,
      task: () => provider.getCurrentUserId(),
    );
    if (id != null) _auth.setUserId(id);
    return id;
  }

  Color colorForStatus(int statusId) {
    final match = statuses.firstWhereOrNull((s) => s.id == statusId);
    if (match == null || match.color.isEmpty) return Colors.blueGrey;
    return HexColor(match.color);
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
  Future<bool> quickSetStatus(int statusId) async {
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
    );
    return true;
  }

  /// Full update — used by both the quick status buttons and the edit form.
  Future<void> submitUpdate({
    required int statusId,
    required String estimateAt,
    String? estimateTime,
    required String address,
    String? description,
  }) async {
    final d = delivery.value;
    if (d == null) return;

    if (address.trim().isEmpty) {
      warningAlertBottom("A delivery address is required.", title: "Missing address");
      return;
    }

    final uid = await _ensureUserId();
    if (uid == null) {
      errorAlert("Couldn't determine the current user. Please re-login.");
      return;
    }

    final payload = {
      "status_id": statusId,
      "updated_by": uid,
      "estimate_at": estimateAt,
      if (estimateTime != null && estimateTime.isNotEmpty) "estimate_time": estimateTime,
      "address": address.trim(),
      "description": description?.trim() ?? "",
    };

    final updated = await ApiExecutor.run(
      isLoading: isUpdating,
      task: () => provider.updateDelivery(d.id, payload),
    );
    if (updated == null) return;

    delivery.value = updated;
    successAlertBottom("Delivery ${updated.code} updated.");
  }
}
