import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../global/size_config.dart';
import '../../../../global/widget/not_found_image.dart';
import '../controllers/home_controller.dart';
import 'dashboard_view.dart';
import 'receiving_order_view.dart';
import 'return_order_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final sizeDefault = SizeConfig.defaultSize;
    return Scaffold(
        appBar: AppBar(
          title:   Obx(() => _buildTitle(controller.currentIndex.value,sizeDefault)),
          centerTitle: true,
          excludeHeaderSemantics: true,
          backgroundColor: Colors.green[100],
          elevation: 2,
        ),
        body: Obx(() => _buildContent(controller.currentIndex.value,sizeDefault)),
        bottomNavigationBar: Obx(
          () => BottomNavigationBar(
            backgroundColor: Colors.grey[100],
            elevation:2,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon:  Icon(CupertinoIcons.arrow_down_doc),
                label: 'Receiving Order',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.arrow_up_doc),
                label: 'Return Order',
              ),
            ],
            currentIndex: controller.currentIndex.value,
            selectedItemColor: Colors.blue[700],
            unselectedItemColor: Colors.black,
            onTap: controller.onItemTapped,
          ),
        ));
  }
  Widget _buildContent(int selectedIndex,double sizeDefault) {
    switch (selectedIndex) {
      case 0:
        return const DashboardView();
      case 1:
        return  const ReceivingOrderView();
      case 2:
        return const ReturnOrderView();
      default:
        return  NotFoundImage(height:sizeDefault * 24,width:sizeDefault * 24, path: "assets/images/404_Image.png"); // Or return a default content widget
    }
  }
  Widget _buildTitle(int selectedIndex,double sizeDefault) {
    switch (selectedIndex) {
      case 0:
        return const Text("Dashboard");
      case 1:
        return  const Text("Receive Order");
      case 2:
        return const Text("Return Order");
      default:
        return const Text("None"); // Or return a default content widget
    }
  }
}
