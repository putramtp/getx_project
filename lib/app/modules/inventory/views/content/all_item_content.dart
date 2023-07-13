import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../global/size_config.dart';
import '../../../../global/variables.dart';
import '../../controllers/all_item_controller.dart';

class AllItemContent extends GetView<AllItemController> {
  const AllItemContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size * 2),
      child: Column(
        children: [
          Obx(
            () => TextField(
              controller: controller.searchController,
              onChanged: controller.onSearch,
              decoration: InputDecoration(
                border: const UnderlineInputBorder(),
                labelText: 'Search',
                hintText: 'Search item...',
                suffixIcon: controller.isSearch.value
                    ? IconButton(
                        onPressed: controller.onCloseSearch,
                        icon: const Icon(Icons.close))
                    : const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(
            child: Obx(() {
              if (controller.isCellLoad.value) {
                return const Center(child: CircularProgressIndicator());
              } else if (controller.listDataRow.isEmpty) {
                return const Center(child: Text("Data is empty "));
              } else {
                return DataTable2(
                  fixedTopRows: controller.fixedRows,
                  border: TableBorder.all(width: 0.5, color: Colors.grey),
                  headingRowColor: MaterialStateProperty.resolveWith(
                      (states) => controller.fixedRows > 0
                          ? hex3
                          : Colors.transparent),
                  columns: const [
                    DataColumn2(
                        label: Center(child: Text('Title')),
                        size: ColumnSize.L),
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
                  rows: controller.filterListDataRow,
                );
              }
            }),
          )
        ],
      ),
    );
  }
}
