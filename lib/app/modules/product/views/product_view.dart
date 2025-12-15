import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/widget/animated_counter.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../data/models/product_summary_model.dart';
import '../../../routes/app_pages.dart';
import '../../../global/size_config.dart';
import '../controllers/product_controller.dart';

class ProductView extends GetView<ProductController> {
  const ProductView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: appBarOrder("Product",icon: Icons.shopping_bag_outlined,routeBackName: AppPages.homePage,hex1: '#124076',hex2: '#7F9F80'),
        body: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(child: Obx(() => _metricBox('Total Products',controller.totalProducts.value,'+8.00%',size))),
                    SizedBox(width: size *2),
                    Expanded(child: Obx(() => _metricBox('Stock in Hand',controller.stockInHand.value,'+2.34%',size))),
                  ],
                ),
              ),
            ),

            // --- Sticky: Products List Title ---
           SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: Container(
                  height: 60,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(() => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => SlideTransition(position: Tween<Offset>(  begin: const Offset(0.3, 0),  end: Offset.zero,).animate(animation),child: child),
                        child: controller.isSearching.value
                            ? _buildSearchField(size,context) // ← Searching mode
                            : _buildTitleBar(size,context), // ← Normal mode
                      )),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            // --- Products / Categories List ---
            Obx(() {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.0,color: Colors.grey)),
                );
              }

              if (controller.filteredProductSummaries.isEmpty) {
                return  SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text("No products available.",style: TextStyle(fontSize: size * 1.4,fontWeight: FontWeight.w400 ),)),
                );
              }

              var products = controller.filteredProductSummaries;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: products.length + 1,
                  (context, index) {
                    if (index < products.length) {
                      final productSummary = products[index];
                      return _productTile(productSummary,size);
                    }
                    if (controller.cursorNext.value != null ) {
                      return  Padding(
                        padding:  EdgeInsets.symmetric(vertical: size * 3),
                        child: const Center(
                          child: SizedBox(width: 26,height: 26,child: CircularProgressIndicator(strokeWidth: 3)),
                        ),
                      );
                    }
                    if (controller.cursorNext.value == null && products.isNotEmpty) {
                      return  Padding(
                        padding:  EdgeInsets.symmetric(vertical: size * 3),
                        child: Center(
                            child: Text("No more data.",style: TextStyle(fontSize: size *1.4,color: Colors.grey,fontWeight: FontWeight.w500),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              );
            }),
          ],
        ));
  }

  Widget _metricBox(String title, int value, String percent, size) {
    return Container(
      width: size * 18,
      padding: EdgeInsets.all(size * 2),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 234, 239, 245),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,style: TextStyle(fontSize: size * 1.5,fontWeight: FontWeight.w400,color: Colors.black54)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(radius: size *2.7,backgroundColor: const Color.fromARGB(15, 79, 206, 147),child: Icon(Icons.layers_outlined , size: size *3,)),
              SizedBox(width: size * 0.5),
              Expanded(child: AnimatedCounter(value: value,style: TextStyle(fontSize: size * 1.8, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 6),
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //   decoration: BoxDecoration(
          //     color: Colors.green.withOpacity(0.2),
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: Text(percent,style: const TextStyle(color: Color.fromARGB(255, 2, 138, 7))),
          // ),
        ],
      ),
    );
  }

  Widget _productTile(ProductSummaryModel p, double size) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.all(size * 1.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: size * 2.8,
              backgroundColor: const Color.fromARGB(255, 220, 230, 221),
              child: Icon(
                Icons.stars_rounded,
                color: const Color.fromARGB(255, 77, 164, 175),
                size: size * 2.4,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: size * 1.6,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 35, 132, 211),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 0.8),
                          ),
                          child: Text(
                            p.itemCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: size * 1.15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => controller.openDetail(p),
                            child: Text(
                              "View details",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: size * 1.1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: size),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _textWithIcon(size,"${p.qtyRemaining}",Icons.archive,Colors.blue),
                            _textWithIcon(size,"${p.qtyIn}",Icons.arrow_drop_down,Colors.green),
                            _textWithIcon(size,"${p.qtyIn}",Icons.arrow_drop_up,Colors.red),
                            if (p.lowStock)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: size * 0.6, vertical: size * 0.4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Low Stock",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: size * 1.1,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 2),
                      // VIEW TRANSACTION BUTTON
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => controller.openTransaction(p),
                            child: Text(
                              "View Transactions",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: size * 1.1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }


  
  Widget _textWithIcon(double size, String text, IconData icon,Color iconColor) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(icon, color: iconColor, size: size * 2),
          ),
          WidgetSpan(
            child: SizedBox(width:size * 0.5), 
          ),
          TextSpan(
            text: text,
            style: TextStyle(fontSize: size * 1.3, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(size,context) {
    return Row(
      key: const ValueKey('title'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Products list', style: Theme.of(context).textTheme.titleLarge),
        Padding(
          padding:  EdgeInsets.only(right: size * 0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                tooltip: 'Sort',
                padding: EdgeInsets.symmetric(horizontal: size *1),
                constraints: const BoxConstraints(),
                onPressed: controller.toggleSort,  
                icon: Icon(controller.isAscending.value ? Icons.arrow_drop_down : Icons.arrow_drop_up, size: size *3),
              ),
              IconButton(
                tooltip: 'Search',
                padding: EdgeInsets.symmetric(horizontal: size *1),
                constraints: const BoxConstraints(),
                onPressed: controller.startSearch,   // ← Tap to search
                icon: Icon(Icons.search, size: size * 2),
              ),
              IconButton(
                tooltip: 'Sync data',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: controller.loadCategories,
                icon: Icon(Icons.sync, size: size * 2),
              ),
               
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(size,context) {
    return Row(
      key: const ValueKey('search'),
      children: [
        Expanded(
          child: TextField(
            controller: controller.searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search products...',
              border: InputBorder.none,
              prefixIcon:  Icon(Icons.search,size:size *2),
              hintStyle: TextStyle(color: Colors.grey.shade500),
              suffixIcon: controller.isStillSearch.value 
              ? IconButton(
                  icon:  Icon(Icons.clear_outlined,size: size * 1.6),
                  onPressed:controller.clearSearched,
                )
              : const SizedBox.shrink(),
            ),
            style: TextStyle(fontSize: size * 1.8),
            onChanged: controller.onSearchChanged,
          ),
        ),
        TextButton(
          onPressed: controller.stopSearch,
          child: Text('Cancel', style: TextStyle(color: Colors.grey[800], fontSize: size * 1.6)),
        ),
      ],
    );
  }

}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
