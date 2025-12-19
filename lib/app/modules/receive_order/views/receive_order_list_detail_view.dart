import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/receive_order_list_detail_controller.dart';
import '../../../global/size_config.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../data/models/serial_number_model.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderListDetailView extends GetView<ReceiveOrderListDetailController> {
  const ReceiveOrderListDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: appBarOrder("Receive order detail",routeBackName: AppPages.receiveOrderListPage),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderGradient(size),
            const SizedBox(height: 16),
            Expanded(child: Obx(() {
              if (controller.isLoading.value) {
                return  Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text("Loading items...",
                          style: TextStyle(fontSize: size * 1.2, color: Colors.black54))
                    ],
                  ),
                );
              }

              if (controller.receiveOrderDetail.value == null) {
                return  Center(
                    child: Text("No items found.",
                        style: TextStyle(fontSize: size * 1.2, color: Colors.black54)));
              }

              final lines =
                  controller.receiveOrderDetail.value?.receiveOrderLines ?? [];
              final linesCount = lines.length;

              return ListView.separated(
                itemCount: linesCount,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final line = lines[index];
                  final List<SerialNumberModel> serialNumbers = line.serialNumbers;
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(line.itemName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text("Quantity:${line.qty}",
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[700])),
                      leading: CircleAvatar(
                        radius: size *1.6,
                        backgroundColor: Colors.indigo.withOpacity(0.15),
                        child:  Icon(Icons.handyman_rounded,color: Colors.indigo, size: size *1.6),
                      ),
                      trailing:serialNumbers.isEmpty ? const SizedBox.shrink() : IconButton(
                        icon:  Icon(Icons.visibility_rounded,size:size *2, color: Colors.indigo),
                        onPressed: () {
                          // 🔹 Show serial numbers in dialog
                          Get.dialog(
                            AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                "Serial Numbers - ${line.itemName}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: serialNumbers.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 8),
                                  itemBuilder: (_, snIndex) {
                                    final sn = serialNumbers[snIndex];
                                    return Column(
                                      crossAxisAlignment:CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Text("${snIndex +1}.",
                                            style: const TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontWeight: FontWeight.w500)),
                                            const SizedBox(width: 2),
                                            Text("SN: ${sn.serialNumber}",
                                                style: const TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                        if (sn.internalCode.isNotEmpty)
                                          Text("Internal: ${sn.internalCode}",
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                        if (sn.expiredDate != null)
                                          Text(
                                            "Expired: ${sn.expiredDate}",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.redAccent),
                                          ),
                                        Text(
                                          "Active: ${sn.isActive ? "Yes" : "No"}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: sn.isActive
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text("Close"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            })),
            // const SizedBox(height: 16),
            // _buildContinueButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderGradient(double size) {
    final ro = controller.currentReceiveOrder;
    final roCode = ro.code;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF528FF3), Color(0xFF2163F0), Color(0xFF1B3B94)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_rounded, color: Colors.white, size: size *3),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Receive Order",style: TextStyle(color: Colors.white70, fontSize: size * 1.3)),
                Text("#$roCode",
                    style:  TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: size *1.8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
