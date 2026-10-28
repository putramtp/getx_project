
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/product_detail_model.dart';
import '../../../data/models/product_summary_model.dart';
import '../../../global/accent.dart';
import '../../../global/widget/accent_header_card.dart';
import '../../../global/widget/accent_pill.dart';
import '../../../global/variables.dart';
import '../../../global/widget/app_header.dart';
import '../../../global/functions.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../controllers/product_detail.controller.dart';

class ProductDetailView extends GetView<ProductDetailController> {
  const ProductDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    final product = controller.currentProduct;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: appHeader(
        'Product Detail',
        accent: AppAccent.slate,
        icon: Icons.info_outline_rounded,
        subtitle: product.itemCode,
      ),
      body: Obx(() {
        final detail = controller.productDetail.value;
        final loading = controller.isLoading.value;

        return FadeTransition(
          opacity: controller.fadeAnim,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10 + MediaQuery.paddingOf(context).bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductCard(product, detail, size),
                const SizedBox(height: 28),
                skeletonize(
                  loading: loading,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION: BASIC INFO
                      _sectionCard(
                        title: "Basic Information",
                        size: size,
                        children: [
                          _infoRow("UPC", detail?.upc, size, loading),
                          _infoRow("Product Type", detail?.type, size, loading),
                          _infoRow("Category", detail?.categoryName, size, loading),
                          _infoRow("Brand", detail?.brandName, size, loading),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECTION: PRICING
                      _sectionCard(
                        title: "Pricing",
                        size: size,
                        children: [
                          _infoRow(
                            "Selling Price",
                            "Rp ${formatPrice(detail?.priceSell)}",
                            size,
                            loading,
                            isPrice: true,
                          ),
                          _infoRow("Serial Number", detail?.serialNumberType, size, loading),
                          _infoRow("Expired", detail?.manageExpired == true ? "Yes" : "No", size, loading),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECTION: DESCRIPTION
                      _sectionCard(
                        title: "Description",
                        size: size,
                        children: [_buildDescription(detail, size, loading)],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }),
    );
  }

  // --------------------------------------------------------------------------
  // PRODUCT CARD
  // --------------------------------------------------------------------------
  Widget _buildProductCard(ProductSummaryModel product, ProductDetailModel? detail, double size) {
    final low = product.lowStock;
    final unit = detail?.unitName ?? '';
    return Hero(
      tag: "product_${product.itemId}",
      child: Material(
        color: Colors.transparent,
        child: accentHeaderCard(
          size: size,
          accent: AppAccent.slate,
          icon: Icons.inventory_2_rounded,
          label: 'Product',
          title: product.itemName,
          code: product.itemCode,
          badge: statusPill(
            size,
            low ? "Low Stock" : "Available",
            low ? amber : stockInColor,
            icon: low ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
          ),
          stats: [
            HeaderStat('Stock in hand', '${product.qtyRemaining} $unit'.trim(),
                color: product.qtyRemaining > 0 ? navyDark : stockOutColor),
            HeaderStat('In', '${product.qtyIn}', color: stockInColor),
            HeaderStat('Out', '${product.qtyOut}', color: stockOutColor),
          ],
          progress: AccentProgress(
            [ProgressSegment(product.qtyIn > 0 ? product.qtyRemaining / product.qtyIn : 0, navyMid)],
            caption: '${product.qtyRemaining} of ${product.qtyIn} received still in stock',
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SECTION CARD
  // --------------------------------------------------------------------------
  Widget _sectionCard({required String title, required List<Widget> children, required double size}) {
    return Container(
      padding: EdgeInsets.all(size * 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 2.1),
        boxShadow: [BoxShadow(blurRadius: 18, offset: const Offset(0, 8), color: Colors.black.withValues(alpha: 0.05))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyle.h4(size, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // INFO ROW
  // --------------------------------------------------------------------------
  Widget _infoRow(String label, String? value, double size, bool loading, {bool isPrice = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size * 0.9),
      child: Row(
        children: [
          SizedBox(
            width: size * 12,
            child: Text(
              label,
              style: AppTextStyle.custom(size, scale: 1.4, color: Colors.grey.shade600, weight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              loading ? "  ..." : (value?.isNotEmpty == true ? value! : "-"),
              style: AppTextStyle.custom(
                size,
                scale: 1.4,
                weight: isPrice ? FontWeight.bold : FontWeight.w600,
                color: isPrice ? Colors.indigo.shade700 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DESCRIPTION LIST
  // --------------------------------------------------------------------------
  Widget _buildDescription(ProductDetailModel? detail, double size, bool loading) {
    if (loading) {
      return Text("  ...", style: AppTextStyle.custom(size, scale: 1.4, color: Colors.grey));
    }

    final descriptions = detail?.descriptions;
    if (descriptions == null || descriptions.isEmpty) {
      return Text("No Descriptions", style: AppTextStyle.custom(size, scale: 1.4, color: Colors.grey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: descriptions
          .map<Widget>(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text("• $d", style: AppTextStyle.custom(size, px: 15, height: 1.4)),
            ),
          )
          .toList(),
    );
  }
}
