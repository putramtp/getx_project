import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import '../../../global/alert.dart';
import '../../../modules/home/views/widgets/indicator.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../../global/functions.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../controllers/home_controller.dart';
import 'clip/wave_clip.dart';
import 'widgets/menu_grid.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = controller.getName();
    final userRoles = controller.getRoles();

    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;

    return Scaffold(
      appBar: _buildAppBar(size, userName),
      body: _buildBody(theme, size, userName, userRoles),
    );
  }

  // ===================== APP BAR =====================

  PreferredSizeWidget _buildAppBar(double size, String userName) {
    return AppBar(
      leading: const SizedBox.shrink(),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: size * 2),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.account_circle_rounded,
                  color: Color(0xff2D6187)),
              onPressed: () => _showAccountSheet(userName),
            ),
          ),
        )
      ],
      flexibleSpace: _buildGradient(),
    );
  }

  void _showAccountSheet(String userName) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.info, color: Color(0xff2D6187)),
              title: const Text("Account Info"),
              onTap: () {
                Get.back();
                Get.defaultDialog(
                  title: "Account Detail",
                  middleText: "Your logged in as:\n$userName",
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () {
                Get.back();
                controller.logout();
                infoAlertBottom(
                  title: "Logout",
                  "You have been logged out",
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===================== BODY =====================

  Widget _buildBody(
    ThemeData theme,
    double size,
    String userName,
    String userRoles,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 2),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: size * 12),
                      _buildHeader(size, 'Dashboard', icon: Icons.home),
                      SizedBox(height: size * 2),
                      _buildGreetingCard(theme, size, userName, userRoles),
                      SizedBox(height: size * 2),
                      _buildDashboardGrid(size),
                      SizedBox(height: size * 4),
                      _lastTransactions(size),
                      const Divider(),
                      SizedBox(height: size * 2),
                      _buildHeader(size, 'Statisic', icon: Icons.pie_chart),
                      _pieChartItem(size),
                      SizedBox(height: size * 2),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(size),
          ],
        ),
        _buildTopWave(size),
        Positioned(
            right: size * 1,
            bottom: size * 5, // ✅ lifted higher from bottom
            child: _buildBottomRefresh(size)),
      ],
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader(double size, String title,
      {bool? isIconText = true, IconData icon = Icons.home}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: SizeConfig.fontSize(2.1), fontWeight: FontWeight.bold),
        ),
        (isIconText == true)
            ? Row(
                children: [
                  Icon(icon, size: size * 1.7),
                  SizedBox(width: size),
                  Text("/ $title",
                      style: TextStyle(fontSize: SizeConfig.fontSize(1.7))),
                ],
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  // ===================== GREETING CARD =====================

  Widget _buildGreetingCard(
    ThemeData theme,
    double size,
    String userName,
    String userRoles,
  ) {
    return Container(
      height: size * 24,
      width: Get.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 1.6),
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [HexColor("#5db7f5"), HexColor("#8adbca")],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(size * 2),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white),
                SizedBox(width: size),
                Obx(() => Text(
                      formatTime(controller.currentTime.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
              ],
            ),
          ),
          Image.asset("assets/images/logo_short.png",
              height: size * 5, width: size * 5),
          SizedBox(height: size),
          Text(controller.getGreeting(),
              style:
                  theme.textTheme.titleLarge?.copyWith(color: Colors.white70)),
          Text(userName,
              style:
                  theme.textTheme.titleMedium?.copyWith(color: Colors.white70)),
          Text("Role : $userRoles",
              style:
                  theme.textTheme.titleMedium?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }

  // ===================== DASHBOARD GRID (DRY) =====================

  Widget _buildDashboardGrid(double size) {
    return Obx(() {
      final dashboard = controller.dashboard.value;
      String stat(int? v) => (v ?? 0).toString();
      final menus = [
        _MenuConfig(
          title: 'PRODUCT',
          icon: CupertinoIcons.briefcase_fill,
          status: stat(dashboard.product),
          hex1: '#124076',
          hex2: '#7F9F80',
          onTap: controller.goToProductPage,
        ),
        _MenuConfig(
          title: 'RECEIVE ORDER',
          icon: CupertinoIcons.bag_badge_plus,
          statusLabel: 'this year',
          status: stat(dashboard.receiveOrder),
          hex1: '#4A70A9',
          hex2: '#8FABD4',
          onTap: controller.goToReceiveOrderHomePage,
        ),
        _MenuConfig(
          title: 'OUTFLOW ORDER',
          icon: CupertinoIcons.bag_badge_minus,
          status: stat(dashboard.outflowOrder),
          statusLabel: "this year",
          hex1: '#FF6F3C',
          hex2: '#e68d40',
          onTap: controller.goToOutflowOrderHomePage,
        ),
        // _MenuConfig(
        //   title: 'TEST RETURN',
        //   icon: CupertinoIcons.backward_end,
        //   status: '33',
        //   hex1: '#1679AB',
        //   hex2: '#5DEBD7',
        //   onTap: controller.goToReturnPage,
        // ),
      ];

      return GridView.extent(
        maxCrossAxisExtent: size * 15,
        crossAxisSpacing: size * 2,
        mainAxisSpacing: size * 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: menus
            .map((e) => MenuGrid(
                  size: size,
                  hex1: e.hex1,
                  hex2: e.hex2,
                  iconData: e.icon,
                  status: e.status,
                  statusLabel: e.statusLabel,
                  title: e.title,
                  onTap: e.onTap,
                ))
            .toList(),
      );
    });
  }

  // =================Latest Transaction  =====================
  Widget _lastTransactions(double size) {
    return Column(
      children: [
        _buildHeader(size, 'Lastest Transactions', isIconText: false),
        const Divider(),
        Obx(() {
           if (controller.isLatestLoading.value) {
            return  Center(
              child:  Text("Loading items...",style: TextStyle(fontSize: size * 1.2, color: Colors.black54))
            );
          }

          if (controller.lastTransactions.isEmpty) {
            return Center(
                child: Text("No data.",
                    style: TextStyle(
                        fontSize: size * 1.2, color: Colors.black54)));
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.lastTransactions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = controller.lastTransactions[index];

              final isIn = item.flowType == "IN";
              final color = isIn ? Colors.green : Colors.red;

              return Row(
                children: [
                  /// Status Icon
                  Container(
                    width: size * 4,
                    height: size * 4,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isIn ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: size *2,
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.time,
                          style: TextStyle(
                            fontSize: size *1.3,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Qty & Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${isIn ? '+' : '-'}${item.qty}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.status == "Completed"
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize: size * 1.2,
                            color: item.status == "Completed"
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        }),
      ],
    );
  }
  // ===================== FOOTER =====================

  Widget _buildFooter(double size) {
    return Container(
      height: size * 4,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [hex1, hex5])),
      child: Center(
        child: RichText(
          text: const TextSpan(
            text: 'Selamat Datang di ',
            style: TextStyle(color: Colors.black87),
            children: [
              TextSpan(
                text: 'Inventory Mastercool',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== TOP WAVE =====================

  Widget _buildTopWave(double size) {
    return ClipPath(
      clipper: WaveClip(),
      child: Container(
        height: size * 10,
        width: Get.width,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [hex1, hex5])),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: Get.width - (size * 21),
            height: size * 6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size),
            ),
            child: Image.asset("assets/images/inventory_logo.png",
                fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  // ===================== FAB =====================
  Widget _buildBottomRefresh(double size) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      return SizedBox(
        width: size * 4,
        height: size * 4,
        child: FloatingActionButton(
          tooltip: 'Refresh Dashboard',
          backgroundColor: const Color.fromARGB(255, 93, 164, 231),
          shape: const CircleBorder(),
          onPressed: isLoading ? null : controller.reloadDashboard,
          child: isLoading
              ? SizedBox(
                  width: size * 2,
                  height: size * 2,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  Icons.refresh_rounded,
                  size: size * 3,
                  color: Colors.white,
                ),
        ),
      );
    });
  }

  Widget _buildGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [hex1, hex5]),
      ),
    );
  }

  Widget _pieChartItem(double size) {
    return Card(
      color: const Color.fromARGB(230, 248, 248, 248),
      child: AspectRatio(
        aspectRatio: 2,
        child: Column(
          children: [
            SizedBox(height: size),
            Text("Serial Number Type",style: TextStyle(fontSize: size *1.5,color: const Color.fromARGB(255, 139, 111, 19), fontWeight: FontWeight.w400)),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Obx(() => PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, pieTouchResponse) {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              controller.resetTouch();
                              return;
                            }
                            controller.onTouch(pieTouchResponse
                                .touchedSection!.touchedSectionIndex);
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 0,
                        centerSpaceRadius: size * 2,
                        sections: controller.showingSections(size),
                      ),
                    )),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Indicator(
                        color: Colors.blue,
                        text: 'Unique',
                        isSquare: true,
                        size: size * 1.5,
                        fontSize: size * 1.2,
                      ),
                      const SizedBox(height: 5),
                      Indicator(
                        color: Colors.yellow,
                        text: 'Other',
                        isSquare: true,
                        size: size * 1.5,
                        fontSize: size * 1.2,
                      ),
                      SizedBox(height: size * 5),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuConfig {
  final String title;
  final IconData icon;
  final String status;
  final String? statusLabel;
  final String hex1;
  final String hex2;
  final VoidCallback onTap;

  _MenuConfig({
    required this.title,
    required this.icon,
    required this.status,
    this.statusLabel,
    required this.hex1,
    required this.hex2,
    required this.onTap,
  });
}
