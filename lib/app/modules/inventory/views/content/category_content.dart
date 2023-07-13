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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(
              () => TextField(
                controller: controller.searchController,
                onChanged: controller.onSearch,
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  labelText: 'Search',
                  hintText: 'Search item categories...',
                  suffixIcon: controller.isSearch.value
                      ? IconButton(
                          onPressed: controller.onCloseSearch,
                          icon: const Icon(Icons.close))
                      : const Icon(Icons.search),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
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
                            return ListTile(
                              onTap: () => Get.toNamed(AppPages.itemPage,
                                  arguments: {"title": item}),
                              leading: const Icon(Icons.arrow_right),
                              trailing: const Text(
                                "Go",
                                style: TextStyle(
                                    color: Colors.green, fontSize: 15),
                              ),
                              title: Text(item),
                            );
                          })
                      : const Center(
                          child: Text(
                            "Not found Categories ",
                            style: TextStyle(color: Colors.red, fontSize: 15),
                          ),
                        ),
            ),
          )
        ],
      ),
    );
  }
}
