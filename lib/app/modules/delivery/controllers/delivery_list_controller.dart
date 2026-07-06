import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';

import '../../../data/models/delivery_model.dart';
import '../../../data/models/delivery_status_model.dart';
import '../../../data/providers/delivery_provider.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../modules/delivery/controllers/delivery_detail_controller.dart';
import '../../../routes/app_pages.dart';

class DeliveryListController extends GetxController {
  final DeliveryProvider provider = Get.find<DeliveryProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  /// Full unfiltered set from the backend (`GET /delivery` has no pagination),
  /// plus the [deliveries] view after search / sort / status filtering.
  final _all = <DeliveryModel>[];
  var deliveries = <DeliveryModel>[].obs;

  /// Status options keyed by id, used to color the status pill.
  final statusById = <int, DeliveryStatusModel>{}.obs;

  var isLoading = false.obs;
  var hasError = false.obs;
  var isAscending = true.obs;
  var isSearchFocused = false.obs;
  final RxString searchQuery = ''.obs;

  /// null = show all statuses; otherwise filter to this status id.
  final RxnInt statusFilter = RxnInt();

  @override
  void onInit() {
    super.onInit();
    searchFocus.addListener(() {
      isSearchFocused.value = searchFocus.hasFocus;
    });
    loadDeliveries();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  Future<void> loadDeliveries() async {
    if (isLoading.value) return;
    // Hold the loading flag across BOTH fetches + _applyView so the skeleton
    // stays until everything is ready. Letting ApiExecutor flip it off after
    // the first call would expose an empty `deliveries` (before _applyView),
    // flashing "No deliveries found." then the list. Inner calls get throwaway
    // flags so they don't toggle the shared one mid-load.
    isLoading.value = true;
    try {
      hasError.value = false;
      final data = await ApiExecutor.run(
        isLoading: false.obs,
        task: () => provider.getDeliveries(),
      );
      if (data == null) {
        hasError.value = true;
        return;
      }

      _all
        ..clear()
        ..addAll(data);

      // Status options are best-effort — a failure here shouldn't blank the list.
      final statuses = await ApiExecutor.run(
        isLoading: false.obs,
        task: () => provider.getDeliveryStatuses(),
      );
      if (statuses != null) {
        statusById
          ..clear()
          ..addEntries(statuses.map((s) => MapEntry(s.id, s)));
      }

      _applyView();
    } finally {
      isLoading.value = false;
    }
  }

  /// Rebuild [deliveries] from [_all] applying search, status filter and sort.
  void _applyView() {
    final q = searchQuery.value.toLowerCase();
    var list = _all.where((d) {
      final matchesStatus =
          statusFilter.value == null || d.statusId == statusFilter.value;
      final matchesSearch = q.isEmpty ||
          d.code.toLowerCase().contains(q) ||
          d.customer.toLowerCase().contains(q) ||
          (d.outflowOrderCode?.toLowerCase().contains(q) ?? false);
      return matchesStatus && matchesSearch;
    }).toList();

    list.sort((a, b) =>
        isAscending.value ? a.code.compareTo(b.code) : b.code.compareTo(a.code));

    deliveries.assignAll(list);
  }

  void onSearchChanged(String value) {
    searchQuery.value = value.trim();
    _applyView();
  }

  void toggleSort() {
    isAscending.value = !isAscending.value;
    _applyView();
  }

  void setStatusFilter(int? statusId) {
    statusFilter.value = statusId;
    _applyView();
  }

  /// The status options to render as filter chips (in backend order).
  List<DeliveryStatusModel> get statusOptions =>
      statusById.values.toList();

  Color colorForStatus(int statusId) {
    final hex = statusById[statusId]?.color;
    if (hex == null || hex.isEmpty) return Colors.blueGrey;
    return HexColor(hex);
  }

  String formatEstimate(DeliveryModel d) {
    if (d.estimateAt == null || d.estimateAt!.isEmpty) return 'No ETA';
    final time = (d.estimateTime != null && d.estimateTime!.isNotEmpty)
        ? ' ${d.estimateTime}'
        : '';
    return '${d.estimateAt}$time';
  }

  String formatYmd(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  void openDetail(DeliveryModel delivery) {
    if (Get.isRegistered<DeliveryDetailController>()) {
      Get.delete<DeliveryDetailController>(force: true);
    }
    Get.toNamed(AppPages.deliveryDetailPage, arguments: delivery);
  }
}
