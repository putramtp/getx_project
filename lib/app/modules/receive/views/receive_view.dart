import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../../global/size_config.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/stack_body.dart';
import '../controllers/receive_controller.dart';
import 'widgets/table_view.dart';

class ReceiveView extends GetView<ReceiveController> {
  const ReceiveView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: AppBar(
        title: titleApp("Receive Items", size),
       backgroundColor: const Color(0xff90AEFF),
        leading: BackButton(color: Colors.white,onPressed: (){Get.back();}),
      ),
      body: StackBodyGradient(
        hex1: "#7D7463",
        hex2: "#90AEFF",
        size: size,
        child: Column(
          children: [
            Container(
              height: size * 5,
              width: Get.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [HexColor("#4FC0D0"), HexColor("#8eeb8a")],
                ),
              ),
              child: Center(
                  child: Obx(() =>_buildtitleTable(controller.selectedIndex.value, size))),
            ),
            Expanded(
              child: TableView(size: size),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_left),
                      Icon(Icons.calendar_today_outlined),
                    ],
                  ),
                  label: 'Previous',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  label: 'Today',
                ),
                BottomNavigationBarItem(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined),
                      Icon(Icons.arrow_right),
                    ],
                  ),
                  label: 'Upcoming',
                ),
              ],
              currentIndex: controller.selectedIndex.value,
              onTap: controller.onSelectedBNavigation)),
    );
  }

  Widget _buildtitleTable(int index, double size) {
    late String title;
    switch (index) {
      case 0:
        title = "Previous";
        break;
      case 1:
        title = "Today";
        break;
      case 2:
        title = "Upcoming";
        break;
      default:
        title = "none";
    }
    return Text("Table Receive items $title",
        style: TextStyle(
            fontSize: size * 1.35,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: size * 0.1));
  }
}
