import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_by_supplier_detail_controller.dart';

class ReceiveOrderFillBySupplierView extends GetView<ReceiveOrderBySupplierDetailController> {
  const ReceiveOrderFillBySupplierView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: appBarOrder("Fill Item", icon: Icons.edit_rounded,hex1:"75a340",hex2:"B1C29E"),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final index = controller.selectedIndex.value;
            if (controller.items.isEmpty || index >= controller.items.length) {
              return const Center(child: CircularProgressIndicator());
            }

            final item = controller.items[index];
            final int expected = (item["expected"] ?? 0) as int;
            final int received = (item["received"] ?? 0) as int;
            final List<Map<String, dynamic>> filled =
                List<Map<String, dynamic>>.from(item["filled"] ?? []);

            final int filledQty = filled.fold<int>(
              0,
              (sum, e) {
                final qtyValue = e['qty'];
                final parsedQty =
                    qtyValue is int ? qtyValue : int.tryParse('$qtyValue') ?? 0;
                return sum + parsedQty;
              },
            );

            final int remaining = expected - (received + filledQty);

            // AnimatedSwitcher keyed by item id -> animates when selectedIndex changes
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final inAnim = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: inAnim,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              // key must change when item changes
              child: Column(
                key: ValueKey(item['id']),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(theme, item),
                  const SizedBox(height: 12),
                  _buildQtyCard( theme, expected, received, filledQty, remaining,size),
                  const SizedBox(height: 20),
                  Text("Filled Results",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(child: _buildFilledList(theme, filled, context)),
                ],
              ),
            );
          }),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: size * 6,
        height: size * 6,
        child: FloatingActionButton(
          backgroundColor:const Color(0xFF658C58),
          foregroundColor: Colors.white,
          elevation: 5,
          shape: const CircleBorder(),
          child: Icon(Icons.edit_note_rounded, size: size * 3),
          onPressed: () async {
            final index = controller.selectedIndex.value;
            final item = controller.items[index];
            final serialType = item['serialNumberType'];
            final manageExpired = item['manageExpired'];

            final result = await _showItemQtyDialog(
                type: serialType, manageExpired: manageExpired);
            if (result != null && result['qty'] != null && result['qty'] > 0) {
              controller.addFilledQty(
                batchQty: result['qty'],
                expiredDate: result['expired_date'],
              );
            }
          },
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme,size),
    );
  }

  Future<Map<String, dynamic>?> _showItemQtyDialog({
    String? type,
    bool? manageExpired,
  }) async {
    final TextEditingController qtyController = TextEditingController();
    final TextEditingController expController = TextEditingController();

    return Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          type == 'BATCH' ? 'Batch Quantity' : 'Enter item quantity',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 Quantity input
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // 🔹 Only show expiration section if manageExpired == true
              if (manageExpired == true) 
              ...[
                GestureDetector(
                  onTap: () async {
                    FocusScope.of(Get.context!)
                        .unfocus(); // close keyboard if open
                    final DateTime? pickedDate = await showDatePicker(
                      context: Get.context!,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.teal,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (pickedDate != null) {
                      expController.text =
                          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: expController,
                      decoration: const InputDecoration(
                        labelText: 'Expiration Date',
                        prefixIcon: Icon(Icons.date_range),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              final qty = int.tryParse(qtyController.text);
              if (qty == null || qty <= 0) {
                warningAlertBottom(title: "Invalid Input","Please enter a valid quantity greater than 0.");
                return;
              }

              if (manageExpired == true && expController.text.isEmpty) {
                errorAlertBottom(title:"Missing Expiration Date","Please select an expiration date.");
                return;
              }

              Get.back(
                result: {
                  'qty': qty,
                  'expired_date': expController.text,
                },
              );
            },
            child: const Text('Save',style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ===== UI helpers =====

  Widget _buildBottomBar(ThemeData theme,double size) {
    return Obx(() {
      final items = controller.items;
      final hasItems = items.isNotEmpty;
      final selectedIndex = controller.selectedIndex.value;

      final currentItem = hasItems && selectedIndex < items.length
          ? items[selectedIndex]
          : null;

      // ✅ unified filled format
      final List<Map<String, dynamic>> filled = currentItem != null
          ? List<Map<String, dynamic>>.from(currentItem["filled"] ?? [])
          : [];

      final bool hasFilledCurrent = filled.isNotEmpty;

      // ✅ count all filled qty from unified data
      final totalFilled = controller.totalFilled;
      final bool hasAnyFilled = totalFilled > 0;

      return Container(
        height: size * 4,
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: hasItems && hasFilledCurrent
                  ? controller.clearFilledCodes
                  : null,
              icon: Icon(
                Icons.delete_forever,
                color: hasItems && hasFilledCurrent ? Colors.red : Colors.grey,
                size: size * 2.6,
              ),
              label: Text(
                "Clear",
                style: TextStyle(
                  fontSize: size * 1.6,
                  color:hasItems && hasFilledCurrent ? Colors.red : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: hasAnyFilled ? controller.goToNextItem : null,
              icon: Icon(
                 size: size * 2.6,
                Icons.save_rounded,
                color: hasAnyFilled ? Colors.blue : Colors.grey,
              ),
              label: Text(
                "Continue",
                style: TextStyle(
                  fontSize: size * 1.6,
                  color: hasAnyFilled ? Colors.blueAccent : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      );
    });
  }

  Widget _buildHeaderCard(ThemeData theme, Map<String, dynamic> item) {
    return Card(
      color: Colors.brown[50],
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_rounded,color: Colors.blueGrey, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item["name"].toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:Colors.blueGrey ,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyCard(
    ThemeData theme,
    int expected,
    int received,
    int filledQty,
    int remaining,
    double size,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQtyInfo("Expected", expected.toString(), Colors.grey.shade700,size),
            _buildQtyInfo("Received", received.toString(), Colors.blue,size),
            _buildQtyInfo("Filled", filledQty.toString(), Colors.green,size),
            _buildQtyInfo("Remaining",remaining.toString(),remaining <= 0 ? Colors.grey : Colors.red,size),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyInfo(String label, String value, Color color,double size) {
    return Column(
      children: [
        Text(value,style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: size *1.3)),
        const SizedBox(height: 2),
        Text(label,style: TextStyle(fontSize: size *1.3, color: Colors.grey.shade600)),
      ],
    );
  }

  /// ✅ Modern filled list
  Widget _buildFilledList(
    ThemeData theme,
    List<Map<String, dynamic>> filled,
    BuildContext context,
  ) {
    if (filled.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text("No items have been filled yet",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: filled.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final qty = filled[i]['qty'] ?? 1;
                final expiredDate = filled[i]['expired_date'] ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.assignment_turned_in_outlined,
                        color: theme.colorScheme.primary),
                  ),
                  // show qty only for batch items
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$qty",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      expiredDate.isNotEmpty
                          ? Text(
                              "Exp : $expiredDate",
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w400,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                  onTap: () async {
                    await Get.bottomSheet(
                      SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit,
                                  color: Colors.blueAccent),
                              title: const Text("Edit Code"),
                              onTap: () {
                                Get.back();
                                infoAlertBottom("you click edit code.");
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              title: const Text("Remove Code"),
                              onTap: () {
                                Get.back();
                                infoAlertBottom("you click remove code.");
                              },
                            ),
                          ],
                        ),
                      ),
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
