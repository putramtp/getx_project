import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';
import '../../../global/functions.dart';
import '../../../global/size_config.dart';
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
      body: Stack(children: [
        _buildHeaderGradient(size),
        // MAIN CONTENT
        Obx(() {
          final detail = controller.productDetail.value;
          final loading = controller.isLoading.value;

          return FadeTransition(
            opacity: controller.fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(size),
                  const SizedBox(height: 20),
                  _buildProductCard(product, detail,size),
                  const SizedBox(height: 28),
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
                      _infoRow("Selling Price", "Rp ${formatPrice(detail?.priceSell)}",size, loading,isPrice: true),
                      _infoRow("Serial Number", detail?.serialNumberType, size,loading),
                      _infoRow("Expired",detail?.manageExpired == true ? "Yes" : "No",size,loading),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // SECTION: DESCRIPTION
                  _sectionCard(title: "Description",size: size,children: [_buildDescription(detail, size, loading)],
                  ),

                  const SizedBox(height: 30),

                  // if (detail != null) _buildActionButtons(),
                ],
              ),
            ),
          );
        }),
      ]),
    );
  }

  // --------------------------------------------------------------------------
  // HEADER
  // --------------------------------------------------------------------------
  Widget _buildHeaderGradient(size) {
    return Container(
      height: size *23,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [HexColor('#124076'), HexColor('#7F9F80')],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // APP BAR
  // --------------------------------------------------------------------------
  Widget _buildAppBar(size) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Get.back(),
          icon:  Icon(Icons.arrow_back_rounded,
              color: Colors.white, size:size * 2),
        ),
         Text(
          "Product Detail",
          style: TextStyle(
            color: Colors.white,
            fontSize: size *2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // PRODUCT CARD (Glassmorphism)
  // --------------------------------------------------------------------------
  Widget _buildProductCard(product, detail,size) {
    return Hero(
      tag: "product_${product.itemId}",
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    color: Colors.black.withOpacity(0.10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.itemName,style:  TextStyle(fontSize: size * 2.2, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),

                  // ITEM CODE TAG
                  _buildTag("Code: ${product.itemCode}",size),

                  const SizedBox(height: 16),
                  _buildStockRow(product, detail,size),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text,size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: size * 1.4,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800),
      ),
    );
  }

  Widget _buildStockRow(product, detail,size) {
    final low = product.lowStock;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Icon(
          low ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
          size: size *2.4,
          color: low ? Colors.orange.shade700 : Colors.green.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          low ? "Low Stock" : "Available",
          style: TextStyle(
            fontSize: size *2,
            fontWeight: FontWeight.w600,
            color: low ? Colors.orange.shade700 : Colors.green.shade700,
          ),
        ),
        const Spacer(),
        // QTY TAG
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: product.qtyRemaining > 0
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.red.shade400, Colors.red.shade600],
            ),
          ),
          child: Text(
            "${product.qtyRemaining} ${detail?.unitName ?? ''}",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: size *1.8),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SECTION CARD
  // --------------------------------------------------------------------------
  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    required double size,
  }) {
    return Container(
      padding: EdgeInsets.all(size * 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 2.1),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style:
                TextStyle(fontSize: size * 1.8, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Divider(),
        ...children,
      ]),
    );
  }

  // --------------------------------------------------------------------------
  // INFO ROW
  // --------------------------------------------------------------------------
  Widget _infoRow(String label, String? value, double size, bool loading,
      {bool isPrice = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size * 0.9),
      child: Row(
        children: [
          SizedBox(
            width: size * 12,
            child: Text(label,
                style: TextStyle(
                    fontSize: size * 1.4,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              loading
                  ? "  ..."
                  : (value?.isNotEmpty == true ? value! : "-"),
              style: TextStyle(
                fontSize: size * 1.4,
                fontWeight: isPrice ? FontWeight.bold : FontWeight.w600,
                color: isPrice ? Colors.indigo.shade700 : Colors.black87,
              ),
            ),
          )
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DESCRIPTION LIST
  // --------------------------------------------------------------------------
  Widget _buildDescription(detail, double size, bool loading) {
    if (loading) {
      return Text("  ...",
          style: TextStyle(color: Colors.grey, fontSize: size * 1.4));
    }

    if (detail?.descriptions == null || detail.descriptions.isEmpty) {
      return Text("No Descriptions",
          style: TextStyle(color: Colors.grey, fontSize: size * 1.4));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: detail.descriptions
          .map<Widget>((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text("• $d",
                    style: const TextStyle(fontSize: 15, height: 1.4)),
              ))
          .toList(),
    );
  }

  // --------------------------------------------------------------------------
  // ACTION BUTTONS
  // --------------------------------------------------------------------------
  // Widget _buildActionButtons() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: ElevatedButton.icon(
  //           onPressed: () {},
  //           icon: const Icon(Icons.edit_outlined, color: Colors.white),
  //           label: const Text("Edit Product",style: TextStyle(color: Colors.white),),
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.blue.shade600,
  //             padding: const EdgeInsets.symmetric(vertical: 16),
  //             shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(14)),
  //           ),
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: OutlinedButton.icon(
  //           onPressed: () {},
  //           icon: const Icon(Icons.inventory_2_outlined),
  //           label: const Text("Stock Adjust"),
  //           style: OutlinedButton.styleFrom( 
  //             padding: const EdgeInsets.symmetric(vertical: 16),
  //             side: BorderSide(color: Colors.blue.shade600),
  //             shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(14)),
  //           ),
  //         ),
  //       )
  //     ],
  //   );
  // }
}
