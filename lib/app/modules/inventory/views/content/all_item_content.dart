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
    controller.fetchDataRowProduct(size);
    return Column(
      children: [
        Obx(
          () => Padding(
            
            padding:  EdgeInsets.symmetric(horizontal:size*3),
            child: TextField(
              controller: controller.searchController,
              onChanged: (String query) {
                controller.onSearch(query, size);
              },
              decoration: InputDecoration(
                border: const UnderlineInputBorder(),
                labelStyle: TextStyle(fontSize: size * 1.4),
                hintStyle: TextStyle(fontSize: size * 1.4),
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
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Obx(() {
            if (controller.isCellLoad.value) {
              return const Center(child: CircularProgressIndicator());
            } else if (controller.filterListDataRow.isEmpty) {
              return const Center(child: Text("Data is empty "));
            } else {
              return DataTable2(
                fixedTopRows: controller.fixedRows,
                columnSpacing: size *1,
                minWidth: 200,
                border: TableBorder.all(width: 0.5, color: Colors.grey),
                headingRowColor: MaterialStateProperty.resolveWith((states) =>
                    controller.fixedRows > 0 ? hex3 : Colors.transparent),
                columns: [
                  DataColumn2(
                    label: Text('Title',
                        style: TextStyle(fontSize: size * 1.2),
                        overflow: TextOverflow.ellipsis),
                    fixedWidth: size *10
                  ),
                  DataColumn2(
                    label: Text(
                      'Price',
                      style: TextStyle(fontSize: size * 1.2),
                      overflow: TextOverflow.ellipsis,
                    ),
                    fixedWidth: size *6
                  ),
                  DataColumn2(
                    label: Text(
                      'Discount',
                      style: TextStyle(fontSize: size * 1.2),
                      overflow: TextOverflow.ellipsis,
                    ),
                    fixedWidth: size *7
                  ),
                  DataColumn2(
                    label: Text(
                      'Qty',
                      style: TextStyle(fontSize: size * 1.2),
                      overflow: TextOverflow.ellipsis,
                    ),
                    fixedWidth: size *7
                  ),
                ],
                rows: controller.filterListDataRow,
              );
            }
          }),
        )
      ],
    );
  }
}
