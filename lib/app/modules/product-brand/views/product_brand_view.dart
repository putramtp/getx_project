// ============ PACKAGE IMPORTS ============
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ============ INTERNAL IMPORTS ============
import 'package:getx_project/app/data/models/product_brand_model.dart';
import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';
import 'package:getx_project/app/global/widget/search_bar.dart';
import 'package:getx_project/app/modules/product-brand/controllers/product_brand_controller.dart';
import 'package:getx_project/app/routes/app_pages.dart';

class ProductBrandView extends GetView<ProductBrandController> {
  const ProductBrandView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return RefreshIndicator(
      onRefresh:controller.loadBrands ,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: appBarOrder("Brand",size,icon: Icons.label_outline, routeBackName: AppPages.homePage,hex1: '#124076',hex2: '#7F9F80'),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Obx(() => SearchBarWidget(
                    isFocused: controller.isSearchFocused.value,
                    isAscending: controller.isAscending.value,
                    searchController: controller.searchController,
                    focusNode: controller.searchFocus,
                    onSearchChanged: controller.onSearchChanged,
                    onToggleSort: controller.toggleSort,
                )),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return textLoading(size);
                    }
    
                    final orders = controller.filteredOrders;
                    if (orders.isEmpty) {
                      return textNoData(size);
                    }
    
                    return NotificationListener(
                      onNotification: (ScrollNotification notification) {
                        if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 250) {
                          controller.loadMore();
                        }
                        return false;
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: orders.length + 1,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: size * 17,
                          mainAxisSpacing: size *2,
                          crossAxisSpacing: size * 2,
                          childAspectRatio: Get.width < 360 ? (size * 0.13) : (size * 0.06),
                        ),
                        itemBuilder: (context, index) {
                          if (index < orders.length) {
                            return _brandGridCard(orders[index], size);
                          }
                        
                          if (controller.cursorNext.value != null) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(strokeWidth: 3),
                                ),
                              ),
                            );
                          }
                        
                          if (controller.cursorNext.value == null && orders.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: Text(
                                  "No more data",
                                  style: TextStyle(
                                    fontSize: size * 1.2,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }
                        
                          return const SizedBox.shrink();
                        },
                      ),
                    );
                  }),
                ),
                // buildSyncButton(name: 'Sync',size: size,onPressed: controller.loadBrands,color: const Color.fromARGB(255, 25, 105, 116))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandGridCard(ProductBrandModel brand, double size) {
    final accent = getAccentColor(brand.initialCode);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => controller.openDetail(brand),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Badge (dynamic height)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 1.4,
                  vertical: size * 0.8,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(size),
                ),
                child: Text(
                  brand.initialCode,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accent,
                    fontSize: size * 1.6,
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      brand.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: size * 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Tap to view",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: size * 1.2,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




}
