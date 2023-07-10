import 'package:flutter/material.dart';
import 'package:get/get.dart';


import '../../../global/size_config.dart';
import '../../../global/widget/bottom_navigation_bar.dart';
import '../../../global/widget/functions_widget.dart';
import '../controllers/home_controller.dart';


class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final sizeDefault = SizeConfig.defaultSize;
    return Scaffold(
        appBar: AppBar(
          title:   Obx(() => buildTitle(controller.currentIndex.value,sizeDefault)),
          actions: [IconButton(onPressed: (){
            Get.toNamed("/login");
          }, icon:const Icon(Icons.person_2_rounded))],
          centerTitle: true,
          excludeHeaderSemantics: true,
          backgroundColor: Colors.green[100],
          elevation: 2,
        ),
        body: Obx(() => buildContent(controller.currentIndex.value,sizeDefault)),
        bottomNavigationBar: Obx(
          () => BottomNavigationBarCostum(index: controller.currentIndex.value, onTap: controller.onItemTapped),
        ));
  }
}


