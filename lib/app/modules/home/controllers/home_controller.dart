import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getx_project/app/global/alert.dart';

import '../../../helpers/api_excecutor.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/models/stock_transaction_model.dart';
import '../../../data/providers/home_provider.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../../../global/variables.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/functions.dart';

class HomeController extends GetxController {
  final HomeProvider provider = Get.find<HomeProvider>();
  final AuthService _authService = Get.find<AuthService>();
  final Rx<DateTime> currentTime = DateTime.now().obs;
  static final DashboardModel defaultDashboard = DashboardModel(product: 0,receiveOrder: 0,outflowOrder: 0,productOther: 0,productUnique: 0);
  final Rx<DashboardModel> dashboard = defaultDashboard.obs;
  final isLoading = false.obs;
  final isLatestLoading = false.obs;
  final lastTransactions = <StockTransactionModel>[].obs;
  final isDeliveryLoading = false.obs;
  final pendingDeliveries = RxnInt(); // null until loaded (or when the call fails)

  Timer? _timer;

  final GetStorage _box = GetStorage();
  static const String _dashboardKey = 'dashboard_cache';

  @override
  void onInit() {
    super.onInit();
    reloadDashboard();
    // Header shows the date + greeting only, so a minute tick is enough.
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
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

    // Failed or skipped (already loading): keep the cached counts on screen.
    if (data == null) return;

    dashboard.value = data; // ✅ TYPE SAFE
    _box.write(_dashboardKey, data.toJson());// ✅ SAVE TO STORAGE
  }

  void _loadDataFromStorage() {
    final cached = _box.read(_dashboardKey);

    if (cached != null && cached is Map<String, dynamic>) {
      dashboard.value = DashboardModel.fromJson(cached);
    } else {
      dashboard.value = defaultDashboard;
    }
  }


  Future<void> loadLatest() async {
    final List<StockTransactionModel>? data =
        await ApiExecutor.run<List<StockTransactionModel>>(
      isLoading: isLatestLoading,
      task: () => provider.getLatestTransaction(limit: 5),
    );

    if (data == null) return;

    lastTransactions.assignAll(data); // ✅ CORRECT RX UPDATE
  }

  Future<void> loadPendingDeliveries() async {
    final count = await ApiExecutor.run<int>(
      isLoading: isDeliveryLoading,
      task: () => provider.getPendingDeliveryCount(),
    );
    if (count == null) return;
    pendingDeliveries.value = count;
  }

 Future <void>  reloadDashboard() async {
    _loadDataFromStorage();
    await loadDashboard();
    await loadLatest();
    await loadPendingDeliveries();
  }

  // ================= NAVIGATION =================
  void goToProductPage() => Get.toNamed(AppPages.productPage);
  void goToReceiveOrderHomePage() => Get.toNamed(AppPages.receiveHomePage);
  void goToOutflowOrderHomePage() => Get.toNamed(AppPages.outflowHomePage);
  void goToTransactionPage() => Get.toNamed(AppPages.stockTransactionPage);
  void goToCategoryPage() => Get.toNamed(AppPages.productCategory);
  void goToBrandPage() => Get.toNamed(AppPages.productBrand);
  void goToUnitPage() => Get.toNamed(AppPages.productUnit);
  void goToDeliveryPage() => Get.toNamed(AppPages.deliveryListPage);
  // ================= USER INFO =================   

  String getName() {
    return _authService.currentUsername ?? "";
  }

  String getRoles() {
    return _authService.currentUserRoles ?? "";
  }

  Future<void> logout() async {
    await _authService.clearToken();
    Get.offAllNamed(Routes.LOGIN);
  }

  // ================= GREETING =================

  String getGreeting() {
    final hour = currentTime.value.hour;
    if (hour >= 5 && hour < 12) return "Good morning";
    if (hour >= 12 && hour < 17) return "Good afternoon";
    if (hour >= 17 && hour < 21) return "Good evening";
    return "Good night";
  }

  /// Up to two initials for the avatar ("Putra Pardede" → "PP").
  String getInitials(String userName) {
    final words = userName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  // ================= SERIAL NUMBER TYPE =================

  int get productUnique => dashboard.value.productUnique;
  int get productOther => dashboard.value.productOther;

  void showAccountSheet(String userName) {
    final size = SizeConfig.defaultSize;
    final roles = getRoles();
    final initials = getInitials(userName);

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        // SafeArea: keep Logout above Android's 3-button navigation bar.
        child: SafeArea(
          top: false,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle
            Container(
              margin: EdgeInsets.only(top: size * 1.2),
              width: size * 4,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(size),
              ),
            ),

            // avatar + name + role
            Container(
              margin: EdgeInsets.all(size * 2),
              padding: EdgeInsets.all(size * 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [navyDark, navyMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(size * 2),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: size * 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      initials,
                      style: AppTextStyle.h3(size, color: Colors.white, weight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: size * 1.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: AppTextStyle.h4(size, color: Colors.white)),
                        SizedBox(height: size * 0.4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: size * 1, vertical: size * 0.3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(size * 2),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded, color: Colors.white70, size: size * 1.3),
                              SizedBox(width: size * 0.4),
                              Text(roles, style: AppTextStyle.bodyBold(size, color: Colors.white, weight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // menu items
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 2),
              child: Column(
                children: [
                  _sheetTile(
                    size: size,
                    icon: Icons.info_outline_rounded,
                    iconColor: navyDark,
                    label: 'Account Info',
                    onTap: () {
                      closeRoute();
                      _showAccountDetailDialog(userName, roles, size, initials);
                    },
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _sheetTile(
                    size: size,
                    icon: Icons.logout_rounded,
                    iconColor: Colors.red.shade400,
                    label: 'Logout',
                    labelColor: Colors.red.shade400,
                    onTap: () {
                      closeRoute();
                      logout();
                      infoAlertBottom(title: "Logout", "You have been logged out");
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: size * 2),
          ],
        ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAccountDetailDialog(String userName, String roles, double size, String initials) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size * 2.2)),
        insetPadding: EdgeInsets.symmetric(horizontal: size * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(size * 2.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [navyDark, navyMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(size * 2.2)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: size * 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      initials,
                      style: AppTextStyle.custom(size, scale: 2.8, weight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: size * 1.2),
                  Text(userName, style: AppTextStyle.h3(size, color: Colors.white)),
                  SizedBox(height: size * 0.6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: size * 1.2, vertical: size * 0.4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(size * 2),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.white70, size: size * 1.3),
                        SizedBox(width: size * 0.4),
                        Text(roles, style: AppTextStyle.bodyBold(size, color: Colors.white, weight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // info rows
            Padding(
              padding: EdgeInsets.all(size * 2),
              child: Column(
                children: [
                  _dialogInfoRow(size, Icons.person_outline_rounded,    'Username', userName),
                  SizedBox(height: size * 1.2),
                  _dialogInfoRow(size, Icons.shield_outlined,           'Role',     roles),
                  SizedBox(height: size * 1.2),
                  _dialogInfoRow(size, Icons.business_outlined,         'Company',  'Mastercool'),
                  SizedBox(height: size * 2),

                  // close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => closeRoute(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyDark,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: size * 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size * 1.4)),
                        elevation: 0,
                      ),
                      child: Text('Close', style: AppTextStyle.h5(size, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogInfoRow(double size, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(size * 0.7),
          decoration: BoxDecoration(
            color: navyDark.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(size),
          ),
          child: Icon(icon, size: size * 1.6, color: navyDark),
        ),
        SizedBox(width: size * 1.2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyle.small(size, color: Colors.grey.shade500)),
            Text(value,  style: AppTextStyle.h5(size)),
          ],
        ),
      ],
    );
  }

  Widget _sheetTile({
    required double size,
    required IconData icon,
    required Color iconColor,
    required String label,
    Color? labelColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size * 1.2),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: size * 1.2),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(size * 0.8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(size * 1),
              ),
              child: Icon(icon, color: iconColor, size: size * 1.8),
            ),
            SizedBox(width: size * 1.4),
            Expanded(
              child: Text(
                label,
                style: AppTextStyle.h5(size, color: labelColor ?? Colors.black87),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: size * 2),
          ],
        ),
      ),
    );
  }
}
