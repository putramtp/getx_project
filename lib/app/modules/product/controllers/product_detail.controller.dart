import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/product_detail_model.dart';
import '../../../data/models/product_summary_model.dart';
import '../../../data/providers/product_provider.dart';

class ProductDetailController extends GetxController with GetSingleTickerProviderStateMixin {
  final provider = Get.find<ProductProvider>();
  late AnimationController fadeController;
  late Animation<double> fadeAnim;

  late ProductSummaryModel currentProduct;
  final productDetail = Rxn<ProductDetailModel>();
  var isLoading = false.obs;
  /// The last load failed: the view offers Retry instead of default values
  /// ("Expired: No", "Rp -") that read as the product's own.
  final hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is ProductSummaryModel) {
      currentProduct = args;
      loadProductDetail();
    } else {
      errorAlert("⚠️ Invalid or missing arguments in ProductDetailController: $args");
    }
    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    fadeAnim = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeOut,
    );

    fadeController.forward();
  }

  @override
  void onClose() {
    fadeController.dispose();
    super.onClose();
  }

   /// 🔹 Fetch items for this order
  Future<void> loadProductDetail() async {
    final productId = currentProduct.itemId;

    final data = await ApiExecutor.run<ProductDetailModel>(
      isLoading: isLoading,
      hasError: hasError,
      task: () => provider.getProductDetail(productId),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;
    productDetail.value = data;

  }

}
