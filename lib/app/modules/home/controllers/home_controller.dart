import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../helpers/api_excecutor.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/models/stock_transaction_model.dart';
import '../../../data/providers/home_provider.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_pages.dart';

class HomeController extends GetxController {
  final HomeProvider provider = Get.find<HomeProvider>();
  final AuthService _authService = Get.find<AuthService>();
  final Rx<DateTime> currentTime = DateTime.now().obs;
  static final DashboardModel defaultDashboard = DashboardModel(product: 0,receiveOrder: 0,outflowOrder: 0,productOther: 0,productUnique: 0);
  final Rx<DashboardModel> dashboard = defaultDashboard.obs;
  final touchedIndex = (-1).obs;
  final isLoading = false.obs;
  final isLatestLoading = false.obs;
  final lastTransactions = <StockTransactionModel>[].obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    reloadDashboard();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      currentTime.value = DateTime.now();
    });
  }

  @override
  void onClose() {
    _timer?.cancel(); // ✅ PREVENT MEMORY LEAK
    super.onClose();
  }

  Future<void> loadDashboard() async {
    final thisYear = DateTime.now().year;

    final DashboardModel? data =
        await ApiExecutor.run<DashboardModel>(
      isLoading: isLoading,
      task: () => provider.getDashboard(year: thisYear),
    );

    if (data == null) {
      dashboard.value = defaultDashboard;
      return;
    }

    dashboard.value = data; // ✅ TYPE SAFE
  }

  Future<void> loadLatest() async {
    final List<StockTransactionModel>? data =
        await ApiExecutor.run<List<StockTransactionModel>>(
      isLoading: isLatestLoading,
      task: () => provider.getLatestTransaction(limit: 10),
    );

    if (data == null) return;

    lastTransactions.assignAll(data); // ✅ CORRECT RX UPDATE
  }

  /// ✅ PROMISE.ALL (SAFE)
 void  reloadDashboard()  {
    dashboard.value = defaultDashboard;
    loadDashboard();
    loadLatest();
  }

  // ================= NAVIGATION =================

  void goToProductPage() => Get.toNamed(AppPages.productPage);
  void goToReceiveOrderHomePage() => Get.toNamed(AppPages.receiveHomePage);
  void goToOutflowOrderHomePage() => Get.toNamed(AppPages.outflowHomePage);
  void goToReturnPage() => Get.toNamed(AppPages.returnPage);

  // ================= USER INFO =================

  String getName() {
    return _authService.currentUsername ?? "";
  }

  String getRoles() {
    return _authService.currentUserRoles ?? "";
  }

  void logout() {
    _authService.clearToken();
    Get.offAllNamed(Routes.LOGIN);
  }

  // ================= GREETING =================

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning 🌅";
    if (hour >= 12 && hour < 17) return "Good Afternoon ☀️";
    if (hour >= 17 && hour < 21) return "Good Evening 🌇";
    return "Good Night 🌙";
  }

  // ================= PIE CHART =================

  void onTouch(int index) {
    touchedIndex.value = index;
  }

  void resetTouch() {
    touchedIndex.value = -1;
  }

  int get productUnique => dashboard.value.productUnique;
  int get productOther => dashboard.value.productOther;

  List<PieChartSectionData> showingSections(double size) {
    final int index = touchedIndex.value;

    final double unique = productUnique.toDouble();
    final double other = productOther.toDouble();
    final double total = unique + other;

    final double uniquePercent = total == 0 ? 0 : (unique / total) * 100;
    final double otherPercent = total == 0 ? 0 : (other / total) * 100;

    return List.generate(2, (i) {
      final isTouched = i == index;
      final fontSize = isTouched ? size * 1.5 : size * 0.9;
      final radius = isTouched ? size * 5 : size * 3;

      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      if (i == 0) {
        return PieChartSectionData(
          color: Colors.blue,
          value: uniquePercent,
          title: '${uniquePercent.toStringAsFixed(1)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: shadows,
          ),
        );
      } else {
        return PieChartSectionData(
          color: Colors.yellow,
          value: otherPercent,
          title: '${otherPercent.toStringAsFixed(1)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: shadows,
          ),
        );
      }
    });
  }
}
