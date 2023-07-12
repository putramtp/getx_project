import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/global/variables.dart';

import '../../../global/widget/functions_widget.dart';
import '../controllers/item_controller.dart';
import 'package:data_table_2/data_table_2.dart';

class ItemView extends GetView<ItemController> {
  const ItemView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: AppBar(
        // leading: BackButton(onPressed:()=> Get.toNamed(AppPages.inventoryPage)),
        title: titleApp(controller.title.value,size),
      ),
      body: Obx(() {
        if (controller.isCellLoad.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (controller.listDataRowProduct.isEmpty) {
          return const Center(child: Text("Data is empty "));
        } else {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20,10, 20,2),
            child: DataTable2(
              fixedTopRows: controller.fixedRows,
              border: TableBorder.all(width: 0.5, color: Colors.grey),
              headingRowColor: MaterialStateProperty.resolveWith(
                  (states) => controller.fixedRows > 0
                      ? hex3
                      : Colors.transparent),
              columns: const [
                DataColumn2(label: Center(child: Text('Title')),size: ColumnSize.L),
                DataColumn2(
                    label: Center(child: Text('Price')),
                    size: ColumnSize.S),
                DataColumn2(
                    label: Center(child: Text('Discount')),
                    size: ColumnSize.S),
                DataColumn2(
                    label: Center(child: Text('Qty')),
                    size: ColumnSize.S),
              ],
              rows: controller.listDataRowProduct,
            ),
          );
        }
      }),
    );
  }
}
