import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getx_project/app/routes/app_pages.dart';

import '../../../../global/size_config.dart';
import '../../controllers/category_controller.dart';

class CategoryContent extends GetView<CategoryController> {
  const CategoryContent({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Obx(
            () => TextField(
              controller: controller.searchController,
              onChanged: controller.onSearch,
              decoration: InputDecoration(
                border: const UnderlineInputBorder(),
                labelText: 'Search',
                labelStyle: TextStyle(fontSize: size * 1.4),
                hintStyle: TextStyle(fontSize: size * 1.3),
                hintText: 'Search item categories...',
                suffixIcon: controller.isSearch.value
                    ? IconButton(
                        onPressed: controller.onCloseSearch,
                        icon: const Icon(Icons.close))
                    : const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Obx(
              () => controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : controller.filteListCategories.isNotEmpty
                      ? ListView.builder(
                          itemCount: controller.filteListCategories.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String item =
                                controller.filteListCategories[index];
                            return Container(
                              margin:
                                  EdgeInsets.symmetric(vertical: size * 0.4),
                              padding: EdgeInsets.all(size * 0.4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.black,
                                    width: size * 0.03,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(size * 1),
                              ),
                              child: ListTile(
                                onTap: () => Get.toNamed(AppPages.itemPage,arguments: {"title": item}),
                                trailing: const Icon(Icons.keyboard_arrow_right_outlined,color: Colors.green,),
                                title: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: size * 1.4,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w400
                                  ),
                                ),
                              ),
                            );
                          })
                      : Center(
                          child: Text(
                            "Not Found Categories ",
                            style: TextStyle(
                                color: Colors.red, fontSize: size * 1.6),
                          ),
                        ),
            ),
          )
        ],
      ),
    );
  }
}
