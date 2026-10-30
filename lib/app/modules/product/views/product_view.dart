import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// ============ INTERNAL IMPORTS ============
import '../../../global/accent.dart';
import '../../../global/widget/accent_header_card.dart';
import '../../../global/widget/accent_pill.dart';
import '../../../global/widget/app_buttons.dart';
import '../../../global/widget/app_header.dart';
import 'package:getx_project/app/global/widget/product_tile.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';
import 'package:getx_project/app/global/widget/top_filter_popup.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../global/variables.dart';
import '../../../global/size_config.dart';
import '../controllers/product_controller.dart';

class ProductView extends GetView<ProductController> {
  const ProductView({super.key});
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: appHeader('Products', accent: AppAccent.slate, icon: Icons.inventory_2_rounded),
        body: RefreshIndicator(
          onRefresh: controller.loadProducts,
          child: NotificationListener(
            onNotification: (ScrollNotification notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 250) {
                controller.loadMore();
              }
              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Obx(
                      () => accentMetricCard(
                        size: size,
                        accent: AppAccent.slate,
                        metrics: [
                          HeaderMetric('Total products', '${controller.totalProducts.value}',
                              icon: Icons.inventory_2_rounded, accent: AppAccent.navy),
                          HeaderMetric('Stock in hand', '${controller.stockInHand.value}',
                              icon: Icons.layers_rounded, accent: AppAccent.sage),
                        ],
                        footer: _summaryFooter(size),
                      ),
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
                    return  SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: skeletonGenericList(size),
                      ),
                    );
                  }
                  
                  if (controller.hasError.value && controller.productSummaries.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: errorRetry(size, onRetry: controller.loadProducts, accent: navyDark),
                    );
                  }

                  if (controller.productSummaries.isEmpty) {
                    return  SliverFillRemaining(
                      hasScrollBody: false,
                      child: textNoData(size),
                    );
                  }
                  
                  var products = controller.productSummaries;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: products.length + 1,
                      (context, index) {
                        if (index < products.length) {
                          final productSummary = products[index];
                           return ProductTile(
                              product: productSummary,
                              size: size,
                              onViewDetail: () => controller.openDetail(productSummary),
                              onViewTransaction: () => controller.openTransaction(productSummary),
                            );
                        }
                        if (controller.cursorNext.value != null &&controller.limit.value >= 8) {
                          return  Padding(
                            padding:  EdgeInsets.symmetric(vertical: size * 3),
                            child: const Center(
                              child: SizedBox(width: 26,height: 26,child: CircularProgressIndicator(strokeWidth: 3)),
                            ),
                          );
                        }
                        if (controller.cursorNext.value == null && products.isNotEmpty) {
                          return NoMoreDataFooter(size: size);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ));
  }

  /// "● N low stock" (orange when any) and the time the summary was loaded.
  Widget _summaryFooter(double size) {
    final low = controller.lowStock.value;
    final updated = controller.lastUpdated.value;
    final color = low > 0 ? Colors.orange.shade800 : Colors.grey.shade600;
    return Row(
      children: [
        Container(width: size * 0.7, height: size * 0.7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: size * 0.5),
        Text(low > 0 ? '$low low stock' : 'No low stock', style: AppTextStyle.custom(size, scale: 1.0, color: color, weight: FontWeight.w700)),
        const Spacer(),
        if (updated != null)
          Text('Updated ${DateFormat('HH:mm').format(updated)}', style: AppTextStyle.small(size, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildTitleBar(double size, BuildContext context) {
    return Row(
      key: const ValueKey('title'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text('Products list', style: AppTextStyle.h5(size, weight: FontWeight.w700, color: navyDark)),
            SizedBox(width: size * 0.8),
            accentPill(size, '${controller.totalProducts.value}', accent: AppAccent.slate),
          ],
        ),
        Row(
          children: [
            // Flipped when descending, so the icon still shows the sort direction.
            softIconButton(size, Icons.sort_rounded,
                tooltip: 'Sort', onPressed: controller.toggleSort, flipVertically: !controller.isAscending.value),
            SizedBox(width: size * 0.5),
            softIconButton(size, Icons.search_rounded, tooltip: 'Search', onPressed: controller.startSearch),
            SizedBox(width: size * 0.5),
            softIconButton(size, Icons.tune_rounded,
                tooltip: 'Filter', onPressed: () => _openTopFilterSheet(context)),
          ],
        ),
      ],
    );
  }

  /// 🧾 Modern Top Filter Sheet
  void _openTopFilterSheet(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Filter",
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) {
        return TopDateFilterPopup(
          controller: controller,
          showPrice: true,
          showDateRange:false,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Qty remaining less than",
                  style: AppTextStyle.custom(SizeConfig.defaultSize,
                      px: 14, weight: FontWeight.w600),
                ),
                SizedBox(
                  width: 80,
                  child: Obx(() => TextFormField(
                        initialValue: controller.qtyRemainingLessThan.value?.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters:  [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: "",
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          final number = int.tryParse(value);
                          controller.qtyRemainingLessThan.value =
                              (number != null && number > 0) ? number : null;
                        },
                      )),
                ),
              ],
              
            ),
            const SizedBox(height: 10)
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1), // 👈 slide from top
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }
  Widget _buildSearchField(double size, BuildContext context) {
    return Row(
      key: const ValueKey('search'),
      children: [
        Expanded(
          child: TextField(
            key: const Key('productSearchField'),
            controller: controller.searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search products...',
              border: InputBorder.none,
              prefixIcon:  Icon(Icons.search,size:size *2),
              hintStyle: AppTextStyle.plain(color: Colors.grey.shade500),
              suffixIcon: controller.isStillSearch.value 
              ? IconButton(
                  icon:  Icon(Icons.clear_outlined,size: size * 1.6),
                  onPressed:controller.clearSearched,
                )
              : const SizedBox.shrink(),
            ),
            style: AppTextStyle.custom(size, scale: 1.8),
            onChanged: controller.filterList,
          ),
        ),
        TextButton(
          onPressed: controller.stopSearch,
          child: Text('Cancel', style: AppTextStyle.custom(size, scale: 1.6, color: Colors.grey[800])),
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
