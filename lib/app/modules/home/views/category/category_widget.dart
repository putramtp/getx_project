import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/receiving_order_controller.dart';

class CategoryView extends GetView<ReceivingOrderController> {
  const CategoryView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Obx(() => TextField(
                        controller: controller.searchController,
                        onChanged: controller.onSearch,
                        decoration: InputDecoration(
                            helperText: "Please find the item you want.",
                            labelText: 'Search...',
                            focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.green),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            suffixIcon: controller.isSearch.value
                                ? IconButton(
                                    onPressed: controller.onCloseSearch,
                                    icon: const Icon(Icons.close))
                                : const Icon(Icons.search)),
                      )),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() => ListView.builder(
                  itemCount: controller.filteListCategories.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                        leading: const Icon(Icons.arrow_right),
                        title: Text(controller.filteListCategories[index]),
                        onTap: () {
                          // Get.toNamed("/receive", arguments: {
                          //   "title": controller.filteListCategories[index],
                          // });
                        });
                  },
                )),
          ),
        ],
      ),
    );
  }
}
