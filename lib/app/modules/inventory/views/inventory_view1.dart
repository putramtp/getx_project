import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../controllers/inventory_controller.dart';
import 'category_view.dart';

class InventoryView extends GetView<InventoryController> {
  const InventoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: AppBar(
        title: titleApp("INVENTORY", size),
      ),
      body: Obx(() =>_buildContent(controller.selectedIndex.value)) ,
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          items: const  <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.cube_box_fill),
              label: 'Single Product',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category),
              label: 'All Product',
            ),
          ],
          backgroundColor: hex1,
          currentIndex: controller.selectedIndex.value,
          selectedItemColor: Colors.black,
          selectedFontSize: 15,
          unselectedItemColor: Colors.black45,
          onTap: controller.onBottomNavigationTapped,
        ),
      ),
    );
  }

  Widget _buildContent (int index){
    switch (index) {
      case 0:return const SearchCategory();
      default:   return const Text("none data");
    }
  }


}
