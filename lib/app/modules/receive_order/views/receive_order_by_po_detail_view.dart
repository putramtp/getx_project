import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';

import '../controllers/receive_order_by_po_detail_controller.dart';
import '../views/receive_order_fill_by_po_view.dart';
import '../../../global/alert.dart';
import '../../../global/size_config.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderByPoDetailView extends GetView<ReceiveOrderByPoDetailController> {
  const ReceiveOrderByPoDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: appBarOrder("Item Summary",size,routeBackName:AppPages.receiveOrderByPoPage),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(size),
            const SizedBox(height: 16),
            Expanded(child: Obx(() {
              if (controller.isLoading.value) {
                return textLoading(size,message: "loading items..");
              }

              if (controller.items.isEmpty) {
                return textNoData(size,message: "No items found.");
              }

              return ListView.separated(
                itemCount: controller.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = controller.items[index];
                  final expected = item['expected'] ?? 0;
                  // Unified filled format: [{code, qty}]
                  final List<Map<String, dynamic>> filledList =
                      List<Map<String, dynamic>>.from(item['filled'] ?? []);

                  // Sum up total filled qty
                  final filledCount = filledList.fold<int>(
                    0,
                    (sum, e) =>
                        sum +
                        ((e['qty'] is int)
                            ? e['qty'] as int
                            : int.tryParse('${e['qty']}') ?? 0),
                  );
                  final received = item['received'] ?? 0;
                  final bool isFinished = received >= expected;
                  final receivedAndFilled = received + filledCount;

                  // log("${item['name']} - ${item['serialNumberType']}");

                  IconData icon;
                  Color bgColor;

                  if (expected > 0 && receivedAndFilled >= expected) {
                    icon = Icons.check_circle_rounded;
                    bgColor = Colors.green;
                  } else if (receivedAndFilled > 0 &&
                      receivedAndFilled < expected) {
                    icon = Icons.timelapse_rounded;
                    bgColor = Colors.orange;
                  } else {
                    icon = Icons.cancel_rounded;
                    bgColor = Colors.red;
                  }

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(item['name'] ?? "Unnamed",style: AppTextStyle.h5(size)),
                      subtitle: Text("Expected: $expected | Received: $received | receiving: $filledCount",style:AppTextStyle.body(size,color: Colors.grey)),
                      leading: CircleAvatar(
                        radius: size * 2.2,
                        backgroundColor: bgColor.withOpacity(0.15),
                        child: Icon(icon, color: bgColor, size: size * 2),
                      ),
                      trailing: !isFinished
                          ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(228, 192, 225, 240),
                                padding:  const EdgeInsets.all(12), 
                                minimumSize: Size.zero,           
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                controller.selectedIndex.value = index;
                                controller.selectedItem.value = item;
                                Get.to(() => const ReceiveOrderFillByPoView());
                              },
                             icon:  Icon(Icons.edit_rounded,size: size *1.5,color: Colors.black87,),
                             label:  Text("fill",style: TextStyle(fontSize: size * 1.2,color: Colors.black87)),
                            )
                          : null,
                    ),
                  );
                },
              );
            })),
            const SizedBox(height: 16),
            _buildContinueButton(size),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(double size) {
    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        final totalFilled = controller.totalFilled;
        final isLoading = controller.isLoadingReceiving.value;
        return FilledButton.icon(
          icon: isLoading
              ?  SizedBox(
                  height: size * 2,
                  width: size * 2,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.receipt_long_rounded),
          label: Text(isLoading
              ? "Processing..."
              : "Continue to receiving items ($totalFilled filled)",style: TextStyle(fontSize: size * 1.4),),
          onPressed: isLoading ? null  :() async {
            if (controller.items.isEmpty) return;
            // Use the unified filled data
            final allFilledUnified = controller.getAllFilledUnified();
            final totalFilled = controller.totalFilled;

            if (totalFilled == 0) {
              warningAlertBottom(title:"No Items Filled","Please fill at least one item before continuing.");
              return;
            }

            // ✅ Make sure only one dialog opens at a time
            String? receiveNumber = controller.receiveNumber.value;
            if (receiveNumber.isEmpty) {
              receiveNumber = await _showReceiveNumberDialog();
              if (receiveNumber == null || receiveNumber.trim().isEmpty) {
                return; // user cancelled or input empty
              }
              controller.receiveNumber.value = receiveNumber.trim();
            }

            // ✅ Ensure previous dialog is fully closed before showing next
            await Future.delayed(const Duration(milliseconds: 200));

            final confirm = await Get.dialog<bool>(
              _buildConfirmDialog(allFilledUnified, totalFilled),
            );
            if (confirm == true) {
              controller.startReceivingItem();
            }
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xff4A70A9)
          ),
        );
      }),
    );
  }

  Widget _buildConfirmDialog(
    Map<dynamic, List<Map<String, dynamic>>> allFilled,
    int totalFilled,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.teal,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () async {
                  final newNumber = await _showReceiveNumberDialog(
                    initialValue: controller.receiveNumber.value,
                  );
                  if (newNumber != null && newNumber.trim().isNotEmpty) {
                    controller.receiveNumber.value = newNumber.trim();
                  }
                },
                child: Column(
                  children: [
                    const Text(
                      'Continue to Receiving ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Obx(() => Text(
                          '#${controller.receiveNumber.value}?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Total receiving quantity: $totalFilled',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // 🔹 Loop through each item and show filled  + total qty
              ...controller.items.map((item) {
                final lineId = item['line_id'];
                final name = item['name'] ?? 'Unnamed';
                final serialNumberType = item['serialNumberType'] ?? 'other';
                final filledList = allFilled[lineId] ?? [];

                // Calculate total qty for this item
                final itemQty = filledList.fold<int>(
                  0,
                  (sum, entry) =>
                      sum +
                      (entry['qty'] is int
                          ? entry['qty'] as int
                          : int.tryParse('${entry['qty']}') ?? 0),
                );

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_rounded,
                              size: 20, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          serialNumberType == 'BATCH'
                              ? Text(
                                  'Total: $itemQty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (filledList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: filledList.map((entry) {
                              final qty = entry['qty'];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.list_rounded,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "Filled: $qty",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(left: 4, top: 4),
                          child: Text(
                            "No filled quantities yet.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      onPressed: () => Get.back(result: true),
                      child: const Text(
                        'Continue',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showReceiveNumberDialog({String? initialValue}) async {
    final TextEditingController textController =
        TextEditingController(text: initialValue ?? '');

    return Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Receive Number'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Enter receive number',
            prefixIcon: Icon(Icons.confirmation_number),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = textController.text.trim();
              Get.back(result: val);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(size) {
    final po = controller.currentOrder;
    final poNumber = po.poNumber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff434E78), Color(0xff607B8F), Color(0xff456882)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.description_rounded, color: Colors.white, size: size * 4),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Purchase Order",style: TextStyle(color: Colors.white70, fontSize: size * 1.4)),
                Text("#$poNumber",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: size * 2.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
