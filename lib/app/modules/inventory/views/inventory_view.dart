import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/image_center.dart';
import '../../../global/widget/stack_body.dart';
import '../controllers/inventory_controller.dart';
import 'content/all_item_content.dart';
import 'content/category_content.dart';

class InventoryView extends GetView<InventoryController> {
  const InventoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: AppBar(
        title: titleApp("Inventory", size),
      ),
      body: StackBodyGradient(
        hex1: '#A8A196',
        hex2: '#F4E0B9',
        size: size,
        child: Obx(
          () => _buildContent(controller.selectedIndex.value, size),
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.cube_box_fill),
              label: 'Single Product',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category),
              label: 'All Product',
            ),
          ],
          currentIndex: controller.selectedIndex.value,
          selectedItemColor: Colors.cyan[700],
          selectedFontSize: size*1.4,
          iconSize :size*2,
          unselectedItemColor: Colors.black45,
          onTap: controller.onBottomNavigationTapped,
        ),
      ),
    );
  }

  Widget _buildContent(int index, double size) {
    switch (index) {
      case 0:
        return const CategoryContent();
      case 1:
        return const AllItemContent();
      default:
        return ImageCenter(
            path: 'assets/images/404_Image.png',
            height: size * 40,
            width: size * 40);
    }
  }
}
