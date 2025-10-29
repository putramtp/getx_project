import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';
import 'package:getx_project/app/routes/app_pages.dart';

class ReceiveOrderHomeView extends GetView {
  const ReceiveOrderHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> menuItems = [
      {'title': 'By Purchase-order', 'icon': Icons.receipt_long_rounded,'color': Colors.indigoAccent,'routes':AppPages.receiveOrderByPoPage},
      {'title': 'By Supplier', 'icon': Icons.group_rounded,'color': Colors.blue,'routes':AppPages.receiveOrderBySupplierPage},
      {'title': 'Receive Order', 'icon': Icons.category_rounded,'color': Colors.green},
      {'title': 'Adjustments', 'icon': Icons.tune_rounded,'color': Colors.orange},
      {'title': 'Reports', 'icon': Icons.insert_chart_rounded,'color': Colors.purple},
      {'title': 'Settings', 'icon': Icons.settings_rounded,'color': Colors.teal},
      {'title': 'Support', 'icon': Icons.help_outline_rounded,'color': Colors.redAccent},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarReceive("Receive Order Menu", icon: Icons.grid_view_outlined),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: GridView.builder(
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            final String title = item['title'] as String;
            final IconData icon = item['icon'] as IconData;
            final Color color = item['color'] as Color;
            final String? routesName = item['routes'] as String?;
            void navigateRoute() =>  routesName != null ?  Get.toNamed(routesName) : Get.snackbar(title, "The route has not been set yet.", duration: const Duration(milliseconds: 900)); 

            return GestureDetector(
              onTap: navigateRoute,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.1),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: navigateRoute,
                  splashColor: color.withOpacity(0.15),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(icon, color: color, size: 30),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
