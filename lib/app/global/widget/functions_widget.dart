import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';
import 'package:getx_project/app/global/variables.dart';

AppBar costumAppbar(String title) {
  return AppBar(
    title: Text(title),
    centerTitle: true,
    excludeHeaderSemantics: true,
    backgroundColor: Colors.green[100],
    elevation: 2,
  );
}

Widget titleApp(String text, double size) {
  return Text(
    text,
    style: AppTextStyle.custom(size,
            scale: 1.8,
            letterSpacing: 0.5,
            color: Colors.white,
            weight: FontWeight.w500)
        .copyWith(wordSpacing: 2),
    overflow: TextOverflow.ellipsis,
  );
}

Widget titleMenu(String text, double size) {
  return Text(text, style: AppTextStyle.custom(size, scale: 1.17));
}

Widget testContainer(double size) {
  return Container(height: size, width: size, color: Colors.brown);
}

PreferredSizeWidget appBarOrder(String title, double size,
    {IconData? icon = Icons.inventory_2,
    String? routeBackName,
    bool showIcon = true,
    Color? color1,
    Color? color2}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(65),
    child: AppBar(
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration:  BoxDecoration(
          gradient: LinearGradient(
            colors: [color1 ?? steelBlue, color2 ?? lightSteelBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          IconButton(
            icon:  Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white,size: size *2),
            onPressed: () =>
                (routeBackName != null) ? Get.toNamed(routeBackName) : Get.back(),
          ),
          showIcon 
              ? Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(icon, color: Colors.white, size: size *2),
                ],
              )
              : const SizedBox.shrink(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyle.custom(size,
                scale: 2.2,
                weight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
      elevation: 4,
      centerTitle: false,
    ),
  );
}

// showRemoveDialog(context, code, onConfirm);
Future<void> showRemoveDialog(
  BuildContext context,
  String code,
  VoidCallback onConfirm,
) async {
  await Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.redAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              "Remove Scanned Code",
              style: AppTextStyle.custom(SizeConfig.defaultSize,
                px: 20,
                weight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Content message
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Are you sure you want to remove this code?",
                  textAlign: TextAlign.center,
                  style: AppTextStyle.custom(SizeConfig.defaultSize,
                    px: 15,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                Text(
                  code,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.custom(SizeConfig.defaultSize,
                    px: 17,
                    weight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    "Cancel",
                    style: AppTextStyle.plain(
                      color: Colors.grey,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    onConfirm();
                    Get.back();
                  },
                  child: Text(
                    "Remove",
                    style: AppTextStyle.plain(
                      color: Colors.redAccent,
                      weight: FontWeight.bold,
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

/// showEditCodeDialog(context, oldCode, onSave: (newCode) ;
Future<void> showEditCodeDialog(
  BuildContext context,
  String code, {
  required ValueChanged<String> onSave,
}) async {
  final TextEditingController controller = TextEditingController(text: code);

  await Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_note_rounded,
                color: Colors.blueAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              "Edit Scanned Code",
              style: AppTextStyle.custom(SizeConfig.defaultSize, px: 20, weight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: AppTextStyle.custom(SizeConfig.defaultSize, px: 16, weight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: "Scanned Code",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    "Cancel",
                    style: AppTextStyle.plain(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newCode = controller.text.trim();
                    if (newCode.isNotEmpty) {
                      onSave(newCode);
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    "Save",
                    style: AppTextStyle.plain(weight: FontWeight.bold),
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


Widget buildSyncButton({required VoidCallback onPressed,required double size,Color color = Colors.blue,String name = 'Synchronization'}){
   return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: SizedBox(
        width: double.infinity,
        height: size * 4,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon:  Icon(Icons.sync, color: Colors.white,size: size *2,),
          label:  Text(
            name,
            style: AppTextStyle.h4(size, color: Colors.white, weight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
}

Widget textWithIcon(double size, String text, IconData icon,Color iconColor) {
  return RichText(
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    text: TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(icon, color: iconColor, size: size * 2),
        ),
        WidgetSpan(
          child: SizedBox(width:size * 0.5), 
        ),
        TextSpan(
          text: text,
          style: AppTextStyle.info(size),
        ),
      ],
    ),
  );
}

Widget textLoading(double size,{color = Colors.black54,message = "Loading..."}) {
  return Center(child: Text(message,style: AppTextStyle.infoBold(size,color: color)));
}

Widget textNoData(double size,{color = Colors.black54,message = "No data."})   {
  return Center(child: Text(message,style: AppTextStyle.infoBold(size,color: color)));
}

/// Error state with a Retry action, shown when a load fails (vs. the empty
/// state, which means the load succeeded but returned nothing).
Widget errorRetry(
  double size, {
  required VoidCallback onRetry,
  String message = "Couldn't load data.\nCheck your connection and try again.",
  Color accent = navyDark,
}) {
  return Center(
    child: Padding(
      padding: EdgeInsets.all(size * 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: size * 5, color: Colors.grey),
          SizedBox(height: size * 1.2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyle.info(size, color: Colors.black54),
          ),
          SizedBox(height: size * 1.6),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('Retry', style: AppTextStyle.bodyBold(size, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                  horizontal: size * 2.4, vertical: size * 1.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(size * 1.2)),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Capture a serial code for a serial-tracked item: the worker chooses to scan
/// a barcode or type it manually. Returns the trimmed code, or null if
/// cancelled. Shared by the receive-fill and outflow-scan flows.
Future<String?> captureSerialInput({Color accent = Colors.blueAccent}) async {
  final mode = await Get.bottomSheet<String>(
    SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.qr_code_scanner_rounded, color: accent),
            title: const Text("Scan barcode"),
            onTap: () => Get.back(result: 'scan'),
          ),
          ListTile(
            leading: Icon(Icons.keyboard_rounded, color: accent),
            title: const Text("Enter manually"),
            onTap: () => Get.back(result: 'manual'),
          ),
        ],
      ),
    ),
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  );

  if (mode == 'scan') {
    final barcode = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    return (barcode == "-1") ? null : barcode;
  }
  if (mode == 'manual') {
    return showManualSerialDialog(accent: accent);
  }
  return null;
}

/// Manual serial-number entry dialog. Returns the trimmed code or null.
Future<String?> showManualSerialDialog({Color accent = Colors.blueAccent}) async {
  final TextEditingController controller = TextEditingController();
  void submit() {
    final value = controller.text.trim();
    if (value.isNotEmpty) Get.back(result: value);
  }

  return Get.dialog<String>(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.keyboard_rounded, color: accent, size: 48),
            const SizedBox(height: 16),
            Text("Enter Serial Number",
                style: AppTextStyle.custom(SizeConfig.defaultSize, px: 20, weight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => submit(),
              style: AppTextStyle.custom(SizeConfig.defaultSize, px: 16, weight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: "Serial Number",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text("Cancel", style: AppTextStyle.plain(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: accent, foregroundColor: Colors.white),
                  child: Text("Save",
                      style: AppTextStyle.plain(weight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}