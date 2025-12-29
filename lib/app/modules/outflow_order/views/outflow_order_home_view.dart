import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';
import 'package:hexcolor/hexcolor.dart';
import '../../../global/size_config.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../routes/app_pages.dart';

class OutflowOrderHomeView extends GetView {
  const OutflowOrderHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'By Request','icon': Icons.receipt_long_rounded,'color': HexColor("#5170FD"),'route': AppPages.outflowOrderByRequestPage},
      {'title': 'By Customer','icon': Icons.group_rounded,'color': HexColor("#239BA7"),'route': AppPages.outflowOrderByCustomerPage},
      // {'title': 'Adjustment', 'icon': Icons.tune_rounded,'color': Colors.orange},
      // {'title': 'Return', 'icon': Icons.insert_chart_rounded,'color': Colors.purple},
      // {'title': 'Setting', 'icon': Icons.settings_rounded,'color': Colors.teal},
    ];
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Outflow Order Menu",size,icon: Icons.grid_view_outlined,routeBackName: AppPages.homePage,hex1: "#FF6F3C",hex2: "#e68d40"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => Get.toNamed(AppPages.outflowOrderListPage),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient:  LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomRight,
                    colors: [
                      HexColor("#EF7722"),
                      HexColor("#FAA533"),
                      HexColor("#FFC29B"),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child:  Icon(
                        Icons.receipt_long_rounded,
                        size: size * 4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Outflow Order",
                            style: AppTextStyle.h1(size,color: Colors.white)
                                .copyWith(
                                  letterSpacing: 0.5,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "View all outflow orders",
                            style:AppTextStyle.h4(size,color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: size *2,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // GRID MENU BELOW
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 1.05,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _buildMenuCard(
                    size: size,
                    title: item['title'],
                    icon: item['icon'],
                    color: item['color'],
                    onTap: () {
                      final route = item['route'] as String;
                      Get.toNamed(route);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required size,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius:  size * 4,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, size: size * 4.5, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style:  TextStyle(
                  fontSize: size * 1.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
