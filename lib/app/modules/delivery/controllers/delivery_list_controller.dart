import 'dart:async';

import 'package:getx_project/app/global/functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';

import '../../../data/models/delivery_model.dart';
import '../../../data/models/delivery_status_model.dart';
import '../../../data/providers/delivery_provider.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../helpers/list_reload_guard.dart';
import '../../../modules/delivery/controllers/delivery_detail_controller.dart';
import '../../../routes/app_pages.dart';

/// Deliveries, cursor-paginated (`GET /delivery/pagination`). Search, the
/// status chip and the sort are sent to the backend ([buildParams]) and reload
/// the list — `GET /delivery` returned every delivery ever made, a payload
/// that only grew.
class DeliveryListController extends GetxController with ListReloadGuard {
  final DeliveryProvider provider = Get.find<DeliveryProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  var deliveries = <DeliveryModel>[].obs;

  /// Status options keyed by id, used for the chips and to color the pill.
  final statusById = <int, DeliveryStatusModel>{}.obs;

  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasError = false.obs;
  var isAscending = true.obs;
  var isSearchFocused = false.obs;
  final RxString searchQuery = ''.obs;
  final RxnString cursorNext = RxnString();
  Timer? _debounce;

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
    _debounce?.cancel();
    searchController.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  Map<String, String> buildParams() => {
        'limit': '20',
        'sort_dir': isAscending.value ? 'asc' : 'desc',
        if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
        if (statusFilter.value != null) 'status_id': '${statusFilter.value}',
      };

  // FIRST PAGE (+ the status options, best effort)
  Future<void> loadDeliveries() => guardReload(isLoading, _loadDeliveries);

  Future<void> _loadDeliveries() async {
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      hasError: hasError,
      task: () => provider.getDeliveriesPage(params: buildParams()),
    );
    if (res == null) return;

    final List rawList = res['data'] ?? [];
    cursorNext.value = res['next_cursor'];
    deliveries.assignAll(rawList.map((e) => DeliveryModel.fromJson(Map<String, dynamic>.from(e as Map))));

    // Status options are best-effort — a failure here shouldn't blank the list.
    if (statusById.isEmpty) {
      final statuses = await ApiExecutor.run(
        isLoading: false.obs,
        task: () => provider.getDeliveryStatuses(),
      );
      if (statuses != null) {
        statusById
          ..clear()
          ..addEntries(statuses.map((s) => MapEntry(s.id, s)));
      }
    }
  }

  // NEXT PAGE
  Future<void> loadMore() async {
    final cursor = cursorNext.value;
    if (cursor == null || isLoadingMore.value || isLoading.value || !mayLoadMore) return;
    final generation = listGeneration;

    final res = await ApiExecutor.run(
      isLoading: isLoadingMore,
      task: () => provider.getDeliveriesPage(cursor: cursor, params: buildParams()),
    );
    if (res == null) return noteLoadMoreFailed();
    // A reload started meanwhile: this page belongs to the old query.
    if (!isCurrentPage(generation)) return;

    final List rawList = res['data'] ?? [];
    cursorNext.value = res['next_cursor'];
    deliveries.addAll(rawList.map((e) => DeliveryModel.fromJson(Map<String, dynamic>.from(e as Map))));
  }

  /// Search on the backend, 400 ms after the last keystroke.
  void onSearchChanged(String value) {
    searchQuery.value = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), loadDeliveries);
  }

  void toggleSort() {
    isAscending.value = !isAscending.value;
    loadDeliveries();
  }

  void setStatusFilter(int? statusId) {
    statusFilter.value = statusId;
    loadDeliveries();
  }

  /// The status options to render as filter chips (in backend order).
  List<DeliveryStatusModel> get statusOptions => statusById.values.toList();

  Color colorForStatus(int statusId) {
    final hex = statusById[statusId]?.color;
    if (hex == null || hex.isEmpty) return Colors.blueGrey;
    return HexColor(hex);
  }

  String formatEstimate(DeliveryModel d) {
    if (d.estimateAt == null || d.estimateAt!.isEmpty) return 'No ETA';
    final time = (d.estimateTime != null && d.estimateTime!.isNotEmpty) ? ' ${d.estimateTime}' : '';
    return '${d.estimateAt}$time';
  }

  String formatYmd(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Open a delivery; reload the list once the user is back, since the detail
  /// may have moved its status (the card and the status filter must follow).
  Future<void> openDetail(DeliveryModel delivery) async {
    await openFresh<DeliveryDetailController>(AppPages.deliveryDetailPage, arguments: delivery);
    if (!isClosed) await loadDeliveries();
  }
}
