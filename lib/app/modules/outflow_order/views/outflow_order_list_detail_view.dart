import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';
import '../../../global/size_config.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../data/models/serial_number_model.dart';
import '../controllers/outflow_order_list_detail_controller.dart';
import '../../../routes/app_pages.dart';

class OutflowOrderDetailView extends GetView<OutflowOrderListDetailController> {
  const OutflowOrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: appBarOrder("Outflow order detail",routeBackName: AppPages.outflowOrderListPage,hex1:"#EF7722",hex2:"#FAA533"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderGradient(size),
            const SizedBox(height: 16),
            Expanded(child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text("Loading items...",
                          style: TextStyle(fontSize: 16, color: Colors.black54))
                    ],
                  ),
                );
              }

              if (controller.outflowOrderDetail.value == null) {
                return const Center(
                    child: Text("No items found.",
                        style: TextStyle(fontSize: 16, color: Colors.black54)));
              }

              final lines =
                  controller.outflowOrderDetail.value?.outflowOrderLines ?? [];
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
                        radius: 24,
                        backgroundColor: Colors.orange.withOpacity(0.15),
                        child: const Icon(Icons.handyman_rounded,
                            color: Colors.orange, size: 26),
                      ),
                      trailing:serialNumbers.isEmpty ? const SizedBox.shrink() : IconButton(
                        iconSize:  size * 2,
                        icon: const  Icon(Icons.visibility_rounded,color: Colors.orange),
                        onPressed: () {
                          // 🔹 Show serial numbers in dialog
                          Get.dialog(
                            AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                "Serial Numbers - ${line.itemName}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
    final ro = controller.curretOutflowOrder;
    final roCode = ro.code;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient:  LinearGradient(
          colors: [HexColor("#EF7722"),HexColor("#FAA533")],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_rounded, color: Colors.white, size: size * 3),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Outflow Order",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text("#$roCode",
                  style:  TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 1.8)),
            ],
          ),
        ],
      ),
    );
  }
}
