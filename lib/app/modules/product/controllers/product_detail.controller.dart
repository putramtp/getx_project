import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/helpers/api_excecutor.dart';
import 'package:getx_project/app/models/product_detail_model.dart';
import 'package:getx_project/app/models/product_summary_model.dart';
import 'package:getx_project/app/modules/product/providers/product_provider.dart';

class ProductDetailController extends GetxController with GetSingleTickerProviderStateMixin {
  final provider = Get.find<ProductProvider>();
  late AnimationController fadeController;
  late Animation<double> fadeAnim;

  late ProductSummaryModel currentProduct;
  final productDetail = Rxn<ProductDetailModel>();
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    currentProduct = Get.arguments;
    loadProductDetail();
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
      task: () => provider.getProductDetail(productId),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;
    log("Data : ${data.toJson()}");
    productDetail.value = data;

  }

}
