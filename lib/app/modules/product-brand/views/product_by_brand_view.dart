import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/widget/product_tile.dart';
// ============ INTERNAL IMPORTS ============
import 'package:getx_project/app/global/widget/search_bar.dart';
import 'package:getx_project/app/modules/product-brand/controllers/product_by_brand_controller.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../routes/app_pages.dart';
import '../../../global/size_config.dart';

class ProductByBrandView extends GetView<ProductByBrandController> {
  const ProductByBrandView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: appBarOrder("Product",icon: Icons.shopping_bag_outlined,routeBackName: AppPages.productCategory,hex1: '#124076',hex2: '#7F9F80'),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0 , vertical: 8.0),
            child: Column(
              children: [
                _buildHeaderGradient(size),
                const SizedBox(height: 6),
                Obx(() => SearchBarWidget(
                      isFocused: controller.isSearchFocused.value,
                      isAscending: controller.isAscending.value,
                      searchController: controller.searchController,
                      focusNode: controller.searchFocus,
                      onSearchChanged: controller.onSearchChanged,
                      onToggleSort: controller.toggleSort,
                      hintText: 'Search products...',
                    )),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
                    }
                    var products = controller.filteredProductSummaries;
                    if (products.isEmpty) {
                      return Center(
                          child: Text(
                        "No products available.",
                        style: TextStyle(
                            fontSize: size * 1.4, fontWeight: FontWeight.w400),
                      ));
                    }
                    return ListView.builder(
                      controller: controller.scrollController,
                      itemCount: products.length + 1,
                      itemBuilder: (context, index) {
                        if (index < products.length) {
                          final productSummary = products[index];
                          return ProductTile(
                            product: productSummary,
                            size: size,
                            onViewDetail: () => controller.openDetail(productSummary),
                            onViewTransaction: () => controller.openTransaction(productSummary),
                          );
                        }
                        if (controller.cursorNext.value != null) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: size * 3),
                            child: const Center(
                              child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3)),
                            ),
                          );
                        }
                        if (controller.cursorNext.value == null &&
                            products.isNotEmpty) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: size * 3),
                            child: Center(
                              child: Text(
                                "No more data.",
                                style: TextStyle(
                                    fontSize: size * 1.4,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildHeaderGradient(double size) {
    final cat = controller.currentBrand;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ Color.fromARGB(255, 18, 106, 165), Color.fromARGB(183, 56, 154, 247)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.label_outline, color: Colors.white, size: size *3),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Product Brand",style:TextStyle(color: Colors.white70, fontSize: size * 1.5)),
                Text(
                  "${cat.name} ",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 1.8),
                ),
                Text(
                  "#${cat.initialCode} ",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 1.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
