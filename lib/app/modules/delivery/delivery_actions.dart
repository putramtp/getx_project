import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/providers/delivery_provider.dart';
import '../../global/alert.dart';
import '../../global/size_config.dart';
import '../../global/styles/app_text_style.dart';
import '../../global/variables.dart';
import '../../helpers/api_excecutor.dart';
import '../../routes/app_pages.dart';

/// Shared delivery actions, used from the outflow order detail ("Create
/// Delivery" button) and from the outflow submit flows (the post-submit
/// "create delivery now?" prompt) so the logic lives in one place.

DeliveryProvider _deliveryProvider() => Get.isRegistered<DeliveryProvider>()
    ? Get.find<DeliveryProvider>()
    : Get.put(DeliveryProvider());

/// Ask whether to create a delivery for the just-completed outflow order.
Future<bool> confirmCreateDelivery() async {
  // Buttons pop via the dialog's own Navigator, not Get.back(): this dialog
  // opens while the "outflow completed" snackbar is still showing, and
  // Get.back() would only close that snackbar, leaving the dialog up.
  final result = await Get.dialog<bool>(
    Builder(builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.local_shipping_rounded, color: steelBlue),
          const SizedBox(width: 10),
          Expanded(
              child: Text("Create delivery?",
                  style: AppTextStyle.h5(SizeConfig.defaultSize))),
        ],
      ),
      content: const Text(
          "The outflow is complete. Do you want to create a delivery for it now?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text("Not now", style: AppTextStyle.plain(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
              backgroundColor: steelBlue, foregroundColor: Colors.white),
          child: const Text("Create"),
        ),
      ],
    )),
  );
  return result ?? false;
}

/// POST `createDelivery` for [outflowOrderId], then route to the delivery list
/// (the backend returns no delivery id, so the list is where it surfaces).
/// Returns true on success.
Future<bool> createDeliveryForOutflow(int outflowOrderId, {RxBool? isLoading}) async {
  final provider = _deliveryProvider();
  final result = await ApiExecutor.run(
    isLoading: isLoading ?? false.obs,
    task: () => provider.createDelivery(outflowOrderId),
  );
  if (result == null) return false; // error already shown by ApiExecutor
  successAlertBottom("Delivery created.");
  Get.toNamed(AppPages.deliveryListPage);
  return true;
}
