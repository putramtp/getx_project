import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';
import 'package:getx_project/app/global/widget/skeleton_widgets.dart';
import 'package:getx_project/app/modules/home/views/widgets/menu_card.dart';

import '../controllers/home_controller.dart';
import '../../../global/functions.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import 'clip/wave_clip.dart';
import 'widgets/indicator.dart';
import 'widgets/menu_grid.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userName = controller.getName();
    final userRoles = controller.getRoles();

    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;

    return Scaffold(
      appBar: _buildAppBar(size, userName),
      body: _buildBody(size, userName, userRoles),
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
            backgroundColor: Colors.white.withOpacity(0.18),
            child: IconButton(
              icon: const Icon(Icons.account_circle_rounded, color: Colors.white),
              onPressed: () => controller.showAccountSheet(userName),
            ),
          ),
        )
      ],
      flexibleSpace: _buildGradient(),
    );
  }

  // ===================== BODY =====================

  Widget _buildBody(double size, String userName, String userRoles) {
    return RefreshIndicator(
      onRefresh: controller.reloadDashboard,
      child: Stack(
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
                        _buildHeader(size, 'Dashboard', icon: Icons.home,isIconText: false),
                        SizedBox(height: size * 2),
                        _buildGreetingCard(size, userName, userRoles),
                        SizedBox(height: size * 2),
                        _buildDashboardGrid(size),
                        SizedBox(height: size * 4),
                        _buildCircleMenu(size),
                        SizedBox(height: size * 2),
                        _sectionTitle(size, 'Latest Transactions', Icons.receipt_long_rounded, skyBlue),
                        SizedBox(height: size),
                        _lastTransactions(size),
                        SizedBox(height: size * 3),
                        _sectionTitle(size, 'Statistic', Icons.pie_chart_rounded, sageTeal),
                        SizedBox(height: size),
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
        ],
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader(double size, String title,
      {bool? isIconText = true, IconData icon = Icons.home}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: size * 1.8, color: navyDark),
            SizedBox(width: size * 0.8),
            Text(title, style: AppTextStyle.h3(size)),
          ],
        ),
        if (isIconText == true)
          Text('/ $title', style: AppTextStyle.h5(size, color: Colors.grey.shade400)),
      ],
    );
  }

  // ===================== SECTION TITLE =====================

  Widget _sectionTitle(double size, String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: size * 0.5,
          height: size * 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size),
          ),
        ),
        SizedBox(width: size * 1.2),
        Container(
          padding: EdgeInsets.all(size * 0.8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(size),
          ),
          child: Icon(icon, size: size * 2, color: color),
        ),
        SizedBox(width: size * 1.2),
        Text(title, style: AppTextStyle.h5(size)),
      ],
    );
  }

  // ===================== GREETING CARD =====================

  Widget _buildGreetingCard(double size, String userName, String userRoles) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 2),
      child: Container(
        width: Get.width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [navyDark, navyMid, navyLight],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -size * 4,
              right: -size * 4,
              child: Container(
                width: size * 18,
                height: size * 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -size * 5,
              left: -size * 3,
              child: Container(
                width: size * 16,
                height: size * 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(size * 0.7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(size),
                            ),
                            child: Icon(Icons.access_time_rounded, color: Colors.white, size: size * 1.8),
                          ),
                          SizedBox(width: size),
                          Obx(() => Text(
                                formatTime(controller.currentTime.value),
                                style: AppTextStyle.infoBold(size, color: Colors.white),
                              )),
                        ],
                      ),
                      Image.asset("assets/images/logo_short.png", height: size * 5, width: size * 5),
                    ],
                  ),
                  SizedBox(height: size * 2),
                  Divider(color: Colors.white.withOpacity(0.25), thickness: 0.8),
                  SizedBox(height: size * 1.5),
                  Text(controller.getGreeting(), style: AppTextStyle.h2(size, color: Colors.white)),
                  SizedBox(height: size * 0.6),
                  Text(userName, style: AppTextStyle.h3(size, color: Colors.white.withOpacity(0.9))),
                  SizedBox(height: size * 1.2),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: size * 1.2, vertical: size * 0.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(size * 2),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.white70, size: size * 1.4),
                        SizedBox(width: size * 0.5),
                        Text(userRoles, style: TextStyle(color: Colors.white, fontSize: size * 1.3, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  SizedBox(height: size),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== DASHBOARD GRID =====================

  Widget _buildDashboardGrid(double size) {
    return Obx(() {
      final dashboard = controller.dashboard.value;
      final year = controller.currentTime.value.year;
      String stat(int? v) => (v ?? 0).toString();
      final menus = [
        _MenuConfig(
          title: 'PRODUCT',
          icon: CupertinoIcons.briefcase_fill,
          status: stat(dashboard.product),
          color1: navyDark,
          color2: sageGreen,
          onTap: controller.goToProductPage,
        ),
        _MenuConfig(
          title: 'RECEIVE ORDER',
          icon: CupertinoIcons.bag_badge_plus,
          status: stat(dashboard.receiveOrder),
          color1: steelBlue,
          color2: lightSteelBlue,
          onTap: controller.goToReceiveOrderHomePage,
        ),
        _MenuConfig(
          title: 'OUTFLOW ORDER',
          icon: CupertinoIcons.bag_badge_minus,
          status: stat(dashboard.outflowOrder),
          color1: mutedPurple,
          color2: lightPurple,
          onTap: controller.goToOutflowOrderHomePage,
        ),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overview', style: AppTextStyle.h5(size, color: Colors.grey.shade600)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: size * 1, vertical: size * 0.4),
                decoration: BoxDecoration(
                  color: navyDark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(size * 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: size * 1.2, color: navyDark),
                    SizedBox(width: size * 0.5),
                    Text('$year', style: TextStyle(fontSize: size * 1.2, color: navyDark, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: size * 1.5),
          Row(
            children: [
              for (int i = 0; i < menus.length; i++) ...[
                Expanded(
                  child: MenuGrid(
                    size: size,
                    color1: menus[i].color1,
                    color2: menus[i].color2,
                    iconData: menus[i].icon,
                    status: menus[i].status,
                    title: menus[i].title,
                    onTap: menus[i].onTap,
                  ),
                ),
                if (i < menus.length - 1) SizedBox(width: size * 1.5),
              ],
            ],
          ),
        ],
      );
    });
  }

  // ===================== CIRCLE MENU =====================

  Widget _buildCircleMenu(double size) {
    final menus = [
      _CircleMenuItem(title: 'Transaction', icon: Icons.currency_exchange,   iconColor: skyBlue,      onTap: controller.goToTransactionPage),
      _CircleMenuItem(title: 'Category',    icon: Icons.category,             iconColor: sageTeal,     onTap: controller.goToCategoryPage),
      _CircleMenuItem(title: 'Brand',       icon: Icons.abc,                  iconColor: softPurple,   onTap: controller.goToBrandPage),
      _CircleMenuItem(title: 'Unit',        icon: Icons.thermostat_auto,      iconColor: amber,        onTap: controller.goToUnitPage),
    ];

    return Container(
      padding: EdgeInsets.all(size * 1.8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded, size: size * 1.8, color: Colors.grey.shade500),
              SizedBox(width: size * 0.8),
              Text('Quick Access', style: TextStyle(fontSize: size * 1.4, fontWeight: FontWeight.w600, color: Colors.grey.shade600, letterSpacing: 0.4)),
            ],
          ),
          SizedBox(height: size * 1.5),
          Row(
            children: [
              for (int i = 0; i < menus.length; i++) ...[
                Expanded(
                  child: CircleMenuItem(
                    size: size,
                    icon: menus[i].icon,
                    title: menus[i].title,
                    iconColor: menus[i].iconColor,
                    onTap: menus[i].onTap,
                  ),
                ),
                if (i < menus.length - 1) SizedBox(width: size * 1.5),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ===================== LATEST TRANSACTIONS =====================

  Widget _lastTransactions(double size) {
    return Column(
      children: [
        Obx(() {
          if (controller.isLatestLoading.value) {
            return skeletonGenericList(size, count: 4);
          }
          if (controller.lastTransactions.isEmpty) {
            return textNoData(size);
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.lastTransactions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final st = controller.lastTransactions[index];
              final isIn = st.flowType == "IN";
              final color = isIn ? Colors.green : Colors.red;
              return Row(
                children: [
                  Container(
                    width: size * 4,
                    height: size * 4,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: size * 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(st.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyle.bodyBold(size)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isIn ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(st.order!.code, style: AppTextStyle.body(size, color: isIn ? Colors.green : Colors.orange)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${isIn ? '+' : '-'}${st.qty % 1 == 0 ? st.qty.toInt() : st.qty}", style: AppTextStyle.bodyBold(size, color: color)),
                      const SizedBox(height: 4),
                      Text(st.time, style: AppTextStyle.info(size, color: Colors.grey.shade600)),
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
      padding: EdgeInsets.symmetric(vertical: size * 0.8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [navyDark, navyMid],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.white38, size: size * 1.2),
          SizedBox(width: size * 0.6),
          Text(
            'Mastercool Inventory Management',
            style: TextStyle(fontSize: size * 1.1, color: Colors.white54, fontStyle: FontStyle.italic),
          ),
        ],
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [navyDark, navyMid],
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: Get.width - (size * 21),
            height: size * 6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size),
            ),
            child: Image.asset("assets/images/inventory_logo.png", fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [navyDark, navyMid],
        ),
      ),
    );
  }

  // ===================== PIE CHART =====================

  Widget _pieChartItem(double size) {
    return Card(
      color: const Color.fromARGB(230, 248, 248, 248),
      child: AspectRatio(
        aspectRatio: 2,
        child: Column(
          children: [
            SizedBox(height: size),
            Text("Serial Number Type", style: TextStyle(fontSize: size * 1.5, color: sageTeal, fontWeight: FontWeight.w500)),
            Expanded(
              child: Obx(() {
                final total = controller.productUnique + controller.productOther;
                if (total == 0) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pie_chart_outline, size: size * 4, color: Colors.grey.shade300),
                        SizedBox(height: size),
                        Text("No data available", style: TextStyle(fontSize: size * 1.4, color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, pieTouchResponse) {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                controller.resetTouch();
                                return;
                              }
                              controller.onTouch(pieTouchResponse.touchedSection!.touchedSectionIndex);
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 0,
                          centerSpaceRadius: size * 2,
                          sections: controller.showingSections(size),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Indicator(color: navyDark, text: 'Unique', isSquare: true, size: size * 1.5, fontSize: size * 1.2),
                        const SizedBox(height: 5),
                        Indicator(color: hex1,     text: 'Other',  isSquare: true, size: size * 1.5, fontSize: size * 1.2),
                        SizedBox(height: size * 5),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private data classes ──────────────────────────────────────────

class _MenuConfig {
  final String title;
  final IconData icon;
  final String status;
  final Color color1;
  final Color color2;
  final VoidCallback onTap;

  const _MenuConfig({
    required this.title,
    required this.icon,
    this.status = '',
    required this.color1,
    required this.color2,
    required this.onTap,
  });
}

class _CircleMenuItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleMenuItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}
